import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:typeset_tag/src/core/typeset_parser.dart';
import 'package:typeset_tag/src/models/style_type_enum.dart';
import 'package:typeset_tag/src/models/style_type_value_model.dart';
import 'package:typeset_tag/src/taggable/constants.dart';
import 'package:typeset_tag/src/taggable/utils/tag.dart';
import 'package:typeset_tag/src/taggable/utils/tag_parser.dart';
import 'package:typeset_tag/typeset.dart';

/// A custom [TextEditingController] that provides WhatsApp-style text
/// formatting capabilities in a text input field.
///
/// This controller extends the standard [TextEditingController] and overrides
/// the [buildTextSpan] method to apply formatting to the text as it's being
/// edited. It uses the [TypesetParser] to parse and format the text according
/// to the formatting rules defined in the package.
///
/// Example usage:
/// ```dart
/// final controller = TypeSetEditingController();
/// TextField(
///   controller: controller,
///   // Other TextField properties
/// );
/// ```
///
/// The text can be formatted using the following syntax:
/// - Bold: *text*
/// - Italic: _text_
/// - Strikethrough: ~text~
/// - Underline: #text#
/// - Monospace: `text`
/// - Link: §text|url§
/// - Font size: text<size>
///
/// The controller automatically renders the formatted text in the TextField
/// while preserving the raw text with formatting markers for editing.
class TypeSetEditingController<T> extends TextEditingController {
  /// Creates a controller for an editable text field with WhatsApp-style
  /// text formatting capabilities.
  ///
  /// The [text] parameter is the initial text to be displayed in the text
  /// field.
  /// The [linkStyle] parameter is the style to apply to links in the text.
  /// The [linkRecognizerBuilder] parameter is a function that builds a gesture
  /// recognizer for links.
  /// The [monospaceStyle] parameter is the style to apply to monospace text.
  /// The [boldStyle] parameter is the style to apply to bold text.
  /// The [markerColor] parameter is the color to use for formatting markers
  /// (like *, _, etc.).
  TypeSetEditingController({
    super.text,
    this.linkStyle,
    this.linkRecognizerBuilder,
    this.monospaceStyle,
    this.boldStyle,
    this.markerColor = const Color(0xFF9E9E9E),
    required this.searchTaggables,
    required this.buildTaggables,
    required this.toFrontendConverter,
    required this.toBackendConverter,
    required this.toTaggableFromBackend,
    required this.textStyleBuilder,
    this.tagStyles = const [TagStyle()],
  }) : super() {
    addListener(taggingListeners);
  }

  /// The style to apply to links in the text.
  final TextStyle? linkStyle;

  /// A function that builds a gesture recognizer for links in the text.
  final GestureRecognizer Function(String text, String url)?
      linkRecognizerBuilder;

  /// The style to apply to monospace text.
  final TextStyle? monospaceStyle;

  /// The style to apply to bold text.
  final TextStyle? boldStyle;

  /// The color to use for formatting markers (like *, _, etc.)
  final Color markerColor;

  /// A list of `TypeValueModel` objects representing the manipulated string.
  List<StyleTypeValueModel> list = [];

  /// Searches for taggables based on the tag prefix (e.g. '@') and query (e.g.
  /// 'Ali').
  final FutureOr<Iterable<T>> Function(String prefix, String? query)
      searchTaggables;

  /// Builds the list of taggables, if any.
  final Future<T?> Function(FutureOr<Iterable<T>> taggables) buildTaggables;

  /// Converts a taggable to a string to display in the linked text field.
  final String Function<T>(T taggable) toFrontendConverter;

  /// Converts a taggable to a unique identifier for internal and backend use.
  final String Function<T>(T taggable) toBackendConverter;

  /// A list of [TagStyle] styles that are supported by the controller.
  final List<TagStyle> tagStyles;

  /// Checks if a character is a formatting marker.
  ///
  /// Returns true if the character is one of the formatting markers defined
  /// in [TypesetReserved].
  bool _isFormattingMarker(String char) {
    return char == TypesetReserved.boldChar ||
        char == TypesetReserved.italicChar ||
        char == TypesetReserved.strikethroughChar ||
        char == TypesetReserved.monospaceChar ||
        char == TypesetReserved.linkChar;
  }

  TextStyle _getStyleForMarker() {
    return TextStyle(color: markerColor);
  }

  /// Gets the content style for a specific marker.
  ///
  /// This method returns a [TextStyle] for the content between formatting
  /// markers.
  ///
  /// [marker] is the formatting marker character.
  /// [baseStyle] is the base style to extend from if needed.
  TextStyle _getContentStyleForMarker(String marker, TextStyle? baseStyle) {
    switch (marker) {
      case TypesetReserved.boldChar:
        return boldStyle ?? const TextStyle(fontWeight: FontWeight.bold);
      case TypesetReserved.italicChar:
        return const TextStyle(fontStyle: FontStyle.italic);
      case TypesetReserved.strikethroughChar:
        return const TextStyle(decoration: TextDecoration.lineThrough);
      case TypesetReserved.monospaceChar:
        return monospaceStyle ?? const TextStyle(fontFamily: 'Courier');
      case TypesetReserved.linkChar:
        return linkStyle ??
            const TextStyle(
              color: Colors.blue,
              decoration: TextDecoration.underline,
            );
      default:
        return baseStyle ?? const TextStyle();
    }
  }

  /// Handles a link formatting in the text.
  ///
  /// This method processes link formatting and adds appropriate [TextSpan]s
  /// to the [spans] list.
  ///
  /// [spans] is the list of [TextSpan]s to add to.
  /// [content] is the content between link markers.
  /// [contentStyle] is the style to apply to the link text.
  /// [closingIndex] is the index of the closing marker.
  /// Returns the index to continue processing from, or -1 to continue normal
  /// processing.
  int _handleLinkFormatting({
    required List<TextSpan> spans,
    required String content,
    required TextStyle contentStyle,
    required int closingIndex,
    required BuildContext context,
  }) {
    final linkParts = content.split(TypesetReserved.linkSplitChar);
    final linkText = linkParts.isNotEmpty ? linkParts[0] : '';
    final url = linkParts.length > 1 ? linkParts[1] : '';

    // Always apply link style, but only add recognizer if we have one
    if (linkRecognizerBuilder != null && url.isNotEmpty) {
      // For links with recognizer, split into clickable text and URL
      spans.add(
        TextSpan(
          text: linkText,
          style: contentStyle,
          recognizer: linkRecognizerBuilder?.call(linkText, url),
        ),
      );

      // If there's a separator, add it with marker style
      if (linkParts.length > 1) {
        spans
          ..add(
            TextSpan(
              text: TypesetReserved.linkSplitChar,
              style: TextStyle(color: markerColor),
            ),
          )
          ..add(
            TextSpan(
              text: url,
              style: contentStyle,
            ),
          );
      }
    } else {
      // For links without recognizer, show the whole content with link style
      spans.add(
        TextSpan(
          text: content,
          style: contentStyle,
        ),
      );
    }

    // Skip to after the closing marker in both cases
    return closingIndex;
  }

  /// Finds the index of the next formatting marker in the text.
  ///
  /// [startIndex] is the index to start searching from.
  /// [textLength] is the length of the text.
  /// Returns the index of the next marker, or [textLength] if none is found.
  int _findNextMarkerIndex(int startIndex, int textLength) {
    var nextMarkerIndex = textLength;
    for (final marker in TypesetReserved.all) {
      final index = text.indexOf(marker, startIndex);
      if (index != -1 && index < nextMarkerIndex) {
        nextMarkerIndex = index;
      }
    }
    return nextMarkerIndex;
  }

  /// Handles escaped formatting markers in the text.
  ///
  /// [spans] is the list of [TextSpan]s to add to.
  /// [currentIndex] is the current index in the text.
  /// [style] is the base style to apply to the escaped character.
  /// Returns the new index after processing the escaped character.
  int _handleEscapedMarker({
    required List<TextSpan> spans,
    required int currentIndex,
    required TextStyle? style,
  }) {
    spans
      ..add(
        TextSpan(
          text: TypesetReserved.escapeLiteral,
          style: TextStyle(color: markerColor),
        ),
      )
      ..add(
        TextSpan(
          text: text[currentIndex + 1],
          style: style,
        ),
      );
    return currentIndex + 2;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // Handle empty text case
    if (text.isEmpty) {
      return TextSpan(style: style);
    }

    // Create a list to hold our text spans
    final spans = <TextSpan>[];

    // Process the text to find formatting markers and create appropriate spans
    var currentIndex = 0;
    final textLength = text.length;

    // Process the text character by character
    while (currentIndex < textLength) {
      final currentChar = text[currentIndex];

      // Check if the current character is a formatting marker
      if (_isFormattingMarker(currentChar)) {
        // Add the marker with a special style
        spans.add(
          TextSpan(
            text: currentChar,
            style: _getStyleForMarker(),
          ),
        );

        // Find the matching closing marker
        final closingIndex = text.indexOf(currentChar, currentIndex + 1);
        if (closingIndex != -1) {
          // Extract the content between markers
          final content = text.substring(currentIndex + 1, closingIndex);

          // Add the content with appropriate styling
          if (content.isNotEmpty) {
            final contentStyle = _getContentStyleForMarker(currentChar, style);

            // Special handling for links
            if (currentChar == TypesetReserved.linkChar) {
              final newIndex = _handleLinkFormatting(
                spans: spans,
                content: content,
                contentStyle: contentStyle,
                closingIndex: closingIndex,
                context: context,
              );

              if (newIndex != -1) {
                currentIndex = newIndex;
                continue;
              }
            } else {
              // Add the styled content for non-link formatting
              final tagSpan = getTaggableSpan<T>(
                content: content,
                context: context,
                style: contentStyle,
                toFrontendConverter: toFrontendConverter,
                toBackendConverter: toBackendConverter,
                textStyleBuilder: textStyleBuilder,
                tagStyles: tagStyles,
                tagBackendFormatsToTaggables: _tagBackendFormatsToTaggables,
              );
              // Add span directly or add its children if it has any
              if (tagSpan.text != null || tagSpan.recognizer != null) {
                spans.add(tagSpan);
              } else if (tagSpan.children != null) {
                // Merge the parent style with each child's style
                spans.addAll(
                  tagSpan.children!.whereType<TextSpan>().map(
                        (child) => TextSpan(
                          text: child.text,
                          style: contentStyle.merge(child.style),
                          recognizer: child.recognizer,
                          children: child.children,
                        ),
                      ),
                );
              }
            }
          }

          // Add the closing marker with special style
          spans.add(
            TextSpan(
              text: currentChar,
              style: _getStyleForMarker(),
            ),
          );

          // Move the index past the closing marker
          currentIndex = closingIndex + 1;
        } else {
          // No closing marker found, treat as normal text
          currentIndex++;
        }
      } else if (currentChar == TypesetReserved.escapeLiteral &&
          currentIndex + 1 < textLength &&
          _isFormattingMarker(text[currentIndex + 1])) {
        // Handle escaped formatting markers
        currentIndex = _handleEscapedMarker(
          spans: spans,
          currentIndex: currentIndex,
          style: style,
        );
      } else {
        // Handle normal text
        final nextMarkerIndex = _findNextMarkerIndex(currentIndex, textLength);

        // Add the text up to the next marker
        if (nextMarkerIndex > currentIndex) {
          final tagSpan = getTaggableSpan<T>(
            content: text.substring(currentIndex, nextMarkerIndex),
            context: context,
            style: style,
            toFrontendConverter: toFrontendConverter,
            toBackendConverter: toBackendConverter,
            textStyleBuilder: textStyleBuilder,
            tagStyles: tagStyles,
            tagBackendFormatsToTaggables: _tagBackendFormatsToTaggables,
          );
          // Add span directly or add its children if it has any
          if (tagSpan.text != null || tagSpan.recognizer != null) {
            spans.add(tagSpan);
          } else if (tagSpan.children != null) {
            // Merge parent style with each child's style
            spans.addAll(
              tagSpan.children!.whereType<TextSpan>().map(
                    (child) => TextSpan(
                      text: child.text,
                      style: style?.merge(child.style) ?? child.style,
                      recognizer: child.recognizer,
                      children: child.children,
                    ),
                  ),
            );
          }
          currentIndex = nextMarkerIndex;
        } else {
          // No more markers, add the rest of the text
          final tagSpan = getTaggableSpan<T>(
            content: text.substring(currentIndex),
            context: context,
            style: style,
            toFrontendConverter: toFrontendConverter,
            toBackendConverter: toBackendConverter,
            textStyleBuilder: textStyleBuilder,
            tagStyles: tagStyles,
            tagBackendFormatsToTaggables: _tagBackendFormatsToTaggables,
          );
          // Add span directly or add its children if it has any
          if (tagSpan.text != null || tagSpan.recognizer != null) {
            spans.add(tagSpan);
          } else if (tagSpan.children != null) {
            // Merge parent style with each child's style
            spans.addAll(
              tagSpan.children!.whereType<TextSpan>().map(
                    (child) => TextSpan(
                      text: child.text,
                      style: style?.merge(child.style) ?? child.style,
                      recognizer: child.recognizer,
                      children: child.children,
                    ),
                  ),
            );
          }
          break;
        }
      }
    }

    return TextSpan(
      style: style,
      children: spans,
    );
  }

  /// Manipulates a given string by identifying specific characters and
  /// assigning corresponding style types to them.
  ///
  /// Returns a list of [StyleTypeValueModel] objects, where each object
  /// represents a segment of the manipulated string with its
  /// corresponding style type.
  ///
  /// Example Usage:
  /// ```dart
  /// var result = manipulateString();
  /// ```
  List<StyleTypeValueModel> manipulateString() {
    // Define literals in a map for easy access
    //to their corresponding style types.
    const literalsMap = <String, StyleTypeEnum>{
      TypesetReserved.boldChar: StyleTypeEnum.bold,
      TypesetReserved.italicChar: StyleTypeEnum.italic,
      TypesetReserved.monospaceChar: StyleTypeEnum.monospace,
      TypesetReserved.strikethroughChar: StyleTypeEnum.strikethrough,
      TypesetReserved.linkChar: StyleTypeEnum.link,
    };

    var currentStyle = StyleTypeEnum.plain;
    final currentContent = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      if (i < text.length - 1 &&
          text[i] == TypesetReserved.escapeLiteral &&
          literalsMap.containsKey(text[i + 1])) {
        // Skip literal character and add the next char as normal text.
        currentContent.write(text[++i]);
        continue;
      }

      if (literalsMap.containsKey(text[i]) &&
          currentStyle == StyleTypeEnum.plain) {
        // Add any existing plain text to the list.
        if (currentContent.isNotEmpty) {
          list.add(
            StyleTypeValueModel(
              styleType: currentStyle,
              value: currentContent.toString(),
            ),
          );
          currentContent.clear();
        }
        // Update the style for the subsequent text.
        currentStyle = literalsMap[text[i]]!;
      } else if (literalsMap.containsKey(text[i]) &&
          literalsMap[text[i]] == currentStyle) {
        // End the current styled text and reset style to plain.
        list.add(
          StyleTypeValueModel(
            styleType: currentStyle,
            value: currentContent.toString(),
          ),
        );
        currentContent.clear();
        currentStyle = StyleTypeEnum.plain;
      } else {
        // Add the current character as part of the current text segment.
        currentContent.write(text[i]);
      }
    }

    // Add any leftover text as plain text.
    if (currentContent.isNotEmpty) {
      list.add(
        StyleTypeValueModel(
          styleType: currentStyle,
          value: currentContent.toString(),
        ),
      );
    }

    return list;
  }

  @override
  void dispose() {
    removeListener(taggingListeners);
    super.dispose();
  }

  @override
  void clear() {
    _tagBackendFormatsToTaggables = {};
    super.clear();
  }

  /// A listener that triggers all tagging-related listeners.
  void taggingListeners() {
    _checkTagRecognizabilityController();
    _cursorController();
    final query = _checkTagQueryController();
    if (query != null) {
      _availableTaggablesController(query.$1, query.$2);
    }
    _updatePreviousCursorPosition();
  }

  /// A function that builds a text style for a taggable based on the tag style.
  ///
  /// If this function is not provided, the text style will be the same as the
  /// default text style of the text field.
  final TextStyle? Function(BuildContext context, String prefix)
      textStyleBuilder;

  /// A map that maps taggable backend formats to taggable objects.
  Map<String, T> _tagBackendFormatsToTaggables = {};

  /// The cursor position before the last change. Used for intuitive cursor
  /// movement.
  int _previousCursorPosition = 0;

  /// A function that converts incoming backend data into a taggable object.
  ///
  /// Takes two [String] parameters:
  /// - First parameter: The raw string data from the backend
  /// - Second parameter: The identifier or key for the data
  ///
  /// Returns a [FutureOr<T>] which can be either an immediate value or a Future
  /// containing the converted taggable object of type T.
  FutureOr<T> Function(String, String) toTaggableFromBackend;

  /// The text formatted in backend format. Do not use `controller.text`
  /// directly.
  String get textInBackendFormat => text.replaceAll(spaceMarker, '');

  /// Sets the initial text of the text field, converting backend strings to
  /// taggables.
  ///
  /// The `backendToTaggable` function is used to convert backend strings to
  /// taggables.
  /// It has the 'FutureOr' signature to allow for asynchronous operations.
  Future<void> setText(
    String backendText,
    FutureOr<T?> Function(String prefix, String backendString)
        backendToTaggable,
  ) async {
    final tmpText = StringBuffer();
    var position = 0;

    for (final match in getTagMatches(backendText, tagStyles)) {
      final textBeforeMatch = backendText.substring(position, match.start);
      tmpText.write(textBeforeMatch);
      position = match.end;

      final tagStyle = tagStyles
          .where((style) => match.group(0)!.startsWith(style.prefix))
          .firstOrNull;
      if (tagStyle == null) {
        tmpText.write(match.group(0));
        continue;
      }
      final taggable = await backendToTaggable(
        tagStyle.prefix,
        match.group(0)!.substring(tagStyle.prefix.length),
      );
      if (taggable == null) {
        tmpText.write(match.group(0));
        continue;
      }
      final tag = Tag<T>(taggable: taggable, style: tagStyle);
      final tagText = tag.toModifiedString(
        toFrontendConverter,
        toBackendConverter,
        isFrontend: false,
      );

      _tagBackendFormatsToTaggables[tagText] = taggable;

      tmpText.write(tagText);
    }

    final textAfterAllTags =
        backendText.substring(position, backendText.length);
    tmpText.write(textAfterAllTags);

    text = tmpText.toString().trimRight();
  }

  /// A listener that ensures that the cursor is always outside of a tag.
  ///
  /// If the cursor is inside a tag, it is moved to the nearest side, unless the
  /// user moved into the tag with the arrow keys, in which case the cursor is
  /// moved to the other side.
  ///
  /// If a range is selected, any tags included in the range are selected as a
  /// whole.
  void _cursorController() {
    final baseOffset = selection.baseOffset;
    final extentOffset = selection.extentOffset;
    final isCollapsed = selection.isCollapsed;
    if (baseOffset == -1) return;

    if (isCollapsed) {
      // Check if the cursor is inside a tag
      final matchWithCursor = getTagMatches(text, tagStyles)
          .where((match) => match.start <= baseOffset && match.end > baseOffset)
          .firstOrNull;

      if (matchWithCursor == null) {
        // The cursor is not inside a tag.
        return;
      }

      // The cursor is inside a tag.
      if ((baseOffset - _previousCursorPosition).abs() == 1) {
        // The user probably moved into the tag with the arrow keys.
        // Move the cursor to the other side.
        // This is not flawless, as the user could have moved into the tag
        // by some other means, but this is the most common case.
        selection = TextSelection.collapsed(
          offset: (baseOffset - _previousCursorPosition) == 1
              ? matchWithCursor.end
              : matchWithCursor.start,
        );
        return;
      }
      // The user probably clicked into the tag.
      //Move it to the nearest side.
      final matchText = matchWithCursor.group(0)!;
      final taggable = _tagBackendFormatsToTaggables[matchText];
      if (taggable == null) {
        // The tag is not recognisable. This case will be handled by the
        // _checkTagRecognizabilityController.
        return;
      }

      final lengthDifference =
          (matchText.length - toFrontendConverter(taggable).length)
              .clamp(0, matchText.length);
      selection = TextSelection.collapsed(
        offset: baseOffset - lengthDifference - matchWithCursor.start <
                matchWithCursor.end - baseOffset
            ? matchWithCursor.start
            : matchWithCursor.end,
      );
    } else {
      // Check if the selection covers a tag
      final matchWithBase = getTagMatches(text, tagStyles)
          .where((match) => match.start < baseOffset && match.end > baseOffset)
          .firstOrNull;
      final matchWithExtent = getTagMatches(text, tagStyles)
          .where(
            (match) => match.start < extentOffset && match.end > extentOffset,
          )
          .firstOrNull;
      final baseBeforeExtent = baseOffset < extentOffset;

      if (matchWithBase == null && matchWithExtent == null) {
        // The selection does not cover a tag.
        return;
      }
      // The selection covers a tag. Select the tag as a whole.
      selection = TextSelection(
        baseOffset: baseBeforeExtent
            ? matchWithBase?.start ?? baseOffset
            : matchWithBase?.end ?? baseOffset,
        extentOffset: baseBeforeExtent
            ? matchWithExtent?.end ?? extentOffset
            : 1 + (matchWithExtent?.start ?? (extentOffset - 1)),
      );
    }
  }

  /// Checks if a tag can be created at the current cursor.
  ///
  /// If a tag can be created, the prefix and the prompt are returned.
  (String prefix, String prompt)? _checkTagQueryController() {
    if (!selection.isCollapsed) {
      // A range is selected, so no tag can be created
      return null;
    }
    final currentPos = selection.baseOffset;
    if (currentPos == -1) return null;
    // Get the last position of a tag prefix before the cursor
    final tagStartPosition = text.substring(0, currentPos).lastIndexOf(
          RegExp(tagStyles.map((style) => style.prefix).join('|')),
        );
    if (tagStartPosition == -1) {
      return null;
    }
    final query = text.substring(tagStartPosition, currentPos);
    final tagStyle =
        tagStyles.where((style) => query.startsWith(style.prefix)).first;
    return (tagStyle.prefix, query.substring(tagStyle.prefix.length));
  }

  /// A listener that ensures that that tags are recognisable.
  ///
  /// If a tag is not recognisable, it is assumed to be invalid and is removed.
  /// This happens for example when the user backspaces over a tag or adds a
  /// character to the end of a tag that results in the regular expression not
  /// matching the tag anymore.
  void _checkTagRecognizabilityController() {
    // First, check for tags that are still detected but not valid
    for (final match in getTagMatches(text, tagStyles)) {
      // If the match can be parsed as a tag, it is valid
      if (parseTagString(
            match.group(0)!,
            tagStyles: tagStyles,
            tagBackendFormatsToTaggables: _tagBackendFormatsToTaggables,
          ) !=
          null) {
        continue;
      }

      // The tag is not recognisable, so it is invalid
      // Check if the match is a superstring of a valid tag
      final originalTag = _tagBackendFormatsToTaggables.keys
          .where((key) => match.group(0)!.contains(key))
          .firstOrNull;

      if (originalTag == null) {
        // The tag is not a superstring of a valid tag, nor is it a valid tag
        // It is still detected by the regular expression, so it must have been
        // trimmed at the end. Check if it is a valid tag without the last char
        final missesFinalCharacter = _tagBackendFormatsToTaggables.keys
            .any((key) => key.substring(0, key.length - 1) == match.group(0));
        // If the final character is missing, remove the tag.
        // Otherwise, the user is probably still typing the tag.
        if (missesFinalCharacter) {
          value = TextEditingValue(
            text: text.replaceFirst(match.group(0)!, ''),
            selection: TextSelection.collapsed(offset: match.start),
          );
        }
        continue;
      }
      final taggable = _tagBackendFormatsToTaggables[originalTag] as T;
      final tagStyle = tagStyles
          .where((style) => originalTag.startsWith(style.prefix))
          .first;
      final tagFrontendFormat = toFrontendConverter(taggable);
      final replacement = tagStyle.prefix + tagFrontendFormat;

      // Break the tag by replacing the tagValue with the tagFrontendFormat
      // This ensures the user sees the same text as before, without the tag
      value = TextEditingValue(
        text: text.replaceFirst(originalTag, replacement, match.start),
        selection: TextSelection.collapsed(
          offset:
              selection.baseOffset - originalTag.length + replacement.length,
        ),
      );
    }
    // Next, check for tags that have been broken by trimming at the start
    // For these tags, the prefix is missing its first character
    final brokenTags = _tagBackendFormatsToTaggables.keys.expand((key) {
      // Create a regexp that matches occurences of 'key' without the first
      // character. e.g. if 'key' is '@tag', the regexp should match 'tag'
      // but not '@tag'.
      final pattern = '(?<!${key.substring(0, 1)})${key.substring(1)}';
      return RegExp(pattern).allMatches(text);
    });
    for (final brokenTag in brokenTags) {
      // Remove the entire tag. The selection can remain the same.
      value = TextEditingValue(
        text: text.replaceRange(brokenTag.start, brokenTag.end, ''),
        selection: TextSelection.collapsed(offset: brokenTag.start),
      );
    }
  }

  /// A listener that searches for taggables based on the current tag prompt.
  ///
  /// If taggable options are found, the user is prompted to select one.
  Future<void> _availableTaggablesController(
    String prefix,
    String prompt,
  ) async {
    final taggables = searchTaggables(prefix, prompt);
    await buildTaggables(taggables).then((taggable) {
      if (taggable == null) return;
      insertTaggable(prefix, taggable, prompt.length + prefix.length);
    });
  }

  /// Inserts a [taggable] into the text field at the current cursor position.
  ///
  /// Insertion typically replaces any tag prompt with the taggable. The number
  /// of characters to replace is given by [charactersToReplace].
  void insertTaggable(String prefix, T taggable, int charactersToReplace) {
    final tagStyle = tagStyles.where((style) => prefix == style.prefix).first;
    final tag = Tag<T>(taggable: taggable, style: tagStyle);
    final tagText = tag.toModifiedString(
      toFrontendConverter,
      toBackendConverter,
      isFrontend: false,
    );

    _tagBackendFormatsToTaggables[tagText] = taggable;

    final end = selection.baseOffset;
    final start = end - charactersToReplace;

    value = TextEditingValue(
      text: text.replaceRange(start, end, tagText),
      selection: TextSelection.collapsed(offset: start + tagText.length),
    );
  }

  /// Updates the previous cursor position. This is used for intuitive cursor
  /// movement.
  void _updatePreviousCursorPosition() {
    _previousCursorPosition = selection.baseOffset;
  }
}
