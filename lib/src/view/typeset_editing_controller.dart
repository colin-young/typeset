import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:typeset_tag/src/core/typeset_formatter_impl.dart';
import 'package:typeset_tag/src/core/typeset_reserved.dart';
import 'package:typeset_tag/src/taggable/constants.dart';
import 'package:typeset_tag/src/taggable/utils/tag_style.dart';

/// A custom [TextEditingController] that provides WhatsApp-style text
/// formatting capabilities in a text input field.
///
/// This controller extends the standard [TextEditingController] and overrides
/// the [buildTextSpan] method to apply formatting to the text as it's being
/// edited.
class TypeSetEditingController<T> extends TextEditingController {
  /// Creates a controller for an editable text field with WhatsApp-style
  /// text formatting capabilities.
  TypeSetEditingController({
    super.text,
    Color markerColor = const Color(0xFF9E9E9E),
    TextStyle? linkStyle,
    this.linkRecognizerBuilder,
    TextStyle? monospaceStyle,
    TextStyle? boldStyle,
    required this.searchTaggables,
    required this.buildTaggables,
    required this.toFrontendConverter,
    required this.toBackendConverter,
    required this.toTaggableFromBackend,
    required this.textStyleBuilder,
    this.tagStyles = const [],
  }) : _formatter = TypesetFormatterImpl(
         showFormattingCharacters: true,
         markerColor: markerColor,
         linkStyle: linkStyle,
         monospaceStyle: monospaceStyle,
         boldStyle: boldStyle,
       ) {
    addListener(_taggingListeners);
  }

  final TypesetFormatterImpl _formatter;
  final GestureRecognizer Function(String text, String url)? linkRecognizerBuilder;
  final List<TagStyle> tagStyles;

  // Tagging-related fields
  final FutureOr<Iterable<T>> Function(String prefix, String? query) searchTaggables;
  final Future<T?> Function(FutureOr<Iterable<T>> taggables) buildTaggables;
  final String Function(T taggable) toFrontendConverter;
  final String Function(T taggable) toBackendConverter;
  final FutureOr<T> Function(String, String) toTaggableFromBackend;
  final TextStyle? Function(BuildContext context, String prefix) textStyleBuilder;

  // State management
  final Map<String, T> _tagBackendFormatsToTaggables = {};
  int _previousCursorPosition = 0;

  /// The text formatted in backend format
  String get textInBackendFormat => text.replaceAll(spaceMarker, '');

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (text.isEmpty) {
      return TextSpan(style: style);
    }

    final spans = <TextSpan>[];
    var currentIndex = 0;
    final textLength = text.length;

    while (currentIndex < textLength) {
      final currentChar = text[currentIndex];

      if (_formatter.isFormattingMarker(currentChar)) {
        spans.add(TextSpan(text: currentChar, style: _formatter.getFormattingMarkerStyle()));

        final closingIndex = text.indexOf(currentChar, currentIndex + 1);
        if (closingIndex != -1) {
          final content = text.substring(currentIndex + 1, closingIndex);

          if (content.isNotEmpty) {
            final contentStyle = _formatter.getContentStyleForMarker(currentChar, style);

            if (currentChar == TypesetReserved.linkChar) {
              final parts = content.split(TypesetReserved.linkSplitChar);
              final linkText = parts.isNotEmpty ? parts[0] : '';
              final url = parts.length == 2 ? parts[1] : '';
              
              if (linkRecognizerBuilder != null) {
                spans.addAll([
                  TextSpan(
                    text: linkText,
                    style: contentStyle,
                    recognizer: linkRecognizerBuilder?.call(linkText, url),
                  ),
                  TextSpan(
                    text: TypesetReserved.linkSplitChar,
                    style: _formatter.getFormattingMarkerStyle(),
                  ),
                  TextSpan(
                    text: url,
                    style: contentStyle,
                  ),
                ]);
              } else {
                spans.add(TextSpan(
                  text: content,
                  style: contentStyle,
                  recognizer: linkRecognizerBuilder?.call(linkText, url),
                ),);
              }
            } else {
              final tagSpan = _getTaggableSpan(
                content: content,
                context: context,
                style: contentStyle,
              );
              
              if (tagSpan.text != null || tagSpan.recognizer != null) {
                spans.add(tagSpan);
              } else if (tagSpan.children != null) {
                spans.addAll(tagSpan.children!.whereType<TextSpan>());
              }
            }
          }

          spans.add(TextSpan(text: currentChar, style: _formatter.getFormattingMarkerStyle()));
          currentIndex = closingIndex + 1;
        } else {
          currentIndex++;
        }
      } else if (currentChar == TypesetReserved.escapeLiteral &&
                 currentIndex + 1 < textLength &&
                 _formatter.isFormattingMarker(text[currentIndex + 1])) {
        currentIndex = _handleEscapedMarker(
          spans: spans,
          currentIndex: currentIndex,
          style: style,
        );
      } else {
        final nextMarkerIndex = _findNextMarkerIndex(currentIndex, textLength);
        if (nextMarkerIndex > currentIndex) {
          final tagSpan = _getTaggableSpan(
            content: text.substring(currentIndex, nextMarkerIndex),
            context: context,
            style: style,
          );
          
          if (tagSpan.text != null || tagSpan.recognizer != null) {
            spans.add(tagSpan);
          } else if (tagSpan.children != null) {
            spans.addAll(tagSpan.children!.whereType<TextSpan>());
          }
          currentIndex = nextMarkerIndex;
        } else {
          spans.add(TextSpan(text: currentChar, style: style));
          currentIndex++;
        }
      }
    }

    return TextSpan(style: style, children: spans.isEmpty ? null : spans);
  }

  /// Finds the index of the next formatting marker in the text.
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
  int _handleEscapedMarker({
    required List<TextSpan> spans,
    required int currentIndex,
    required TextStyle? style,
  }) {
    spans.add(TextSpan(text: text[currentIndex + 1], style: style));
    return currentIndex + 2;
  }

  /// Gets a TextSpan for a taggable item.
  TextSpan _getTaggableSpan({
    required String content,
    required BuildContext context,
    TextStyle? style,
  }) {
    for (final tagStyle in tagStyles) {
      if (content.startsWith(tagStyle.prefix)) {
        final backendFormat = content.substring(tagStyle.prefix.length);
        final taggable = _tagBackendFormatsToTaggables[backendFormat];
        if (taggable != null) {
          return TextSpan(
            text: tagStyle.prefix + toFrontendConverter(taggable),
            style: textStyleBuilder(context, tagStyle.prefix)?.merge(style) ?? style,
          );
        }
      }
    }
    return TextSpan(text: content, style: style);
  }

  /// A listener that triggers all tagging-related listeners.
  void _taggingListeners() {
    _checkTagRecognizabilityController();
    _cursorController();
    final query = _checkTagQueryController();
    if (query != null) {
      _availableTaggablesController(query.$1, query.$2);
    }
    _updatePreviousCursorPosition();
  }

  /// Checks if a potential tag might be recognizable.
  Future<void> _checkTagRecognizabilityController() async {
    for (final tagStyle in tagStyles) {
      if (text.endsWith(tagStyle.prefix) ||
          text.contains('${tagStyle.prefix} ') ||
          text.contains('${tagStyle.prefix}\n')) {
        final results = await searchTaggables(tagStyle.prefix, null);
        final selectedTaggable = await buildTaggables(results);
        if (selectedTaggable != null) {
          _updateTaggableInTextField(selectedTaggable);
        }
      }
    }
  }

  /// Updates the cursor position.
  void _cursorController() {
    if (text.isEmpty) return;

    if (_previousCursorPosition > selection.baseOffset) {
      _removeTagFormatting();
    }
  }

  /// Checks for tag queries in the input text.
  (String, String)? _checkTagQueryController() {
    if (text.isEmpty) return null;
    
    // Check for each tag style if there's a potential query
    for (final tagStyle in tagStyles) {
      final tagIndex = text.lastIndexOf(tagStyle.prefix);
      if (tagIndex != -1 && tagIndex < selection.baseOffset) {
        final potentialQuery = text.substring(tagIndex + 1, selection.baseOffset);
        if (potentialQuery.isNotEmpty &&
            !potentialQuery.contains(' ') &&
            !potentialQuery.contains('\n')) {
          return (tagStyle.prefix, potentialQuery);
        }
      }
    }

    return null;
  }

  /// Processes available taggables based on the prefix and query.
  Future<void> _availableTaggablesController(String prefix, String? query) async {
    final results = await searchTaggables(prefix, query);
    final selectedTaggable = await buildTaggables(results);
    if (selectedTaggable != null) {
      _updateTaggableInTextField(selectedTaggable);
    }
  }

  /// Updates the previous cursor position.
  void _updatePreviousCursorPosition() {
    _previousCursorPosition = selection.baseOffset;
  }

  /// Updates the text field with a selected taggable item.
  void _updateTaggableInTextField(T selectedTaggable) {
    for (final tagStyle in tagStyles) {
      final tagIndex = text.lastIndexOf(tagStyle.prefix);
      if (tagIndex != -1) {
        final frontendTagFormat = tagStyle.prefix + toFrontendConverter(selectedTaggable);
        _tagBackendFormatsToTaggables[toBackendConverter(selectedTaggable)] = selectedTaggable;
        text = text.replaceRange(tagIndex, selection.baseOffset, frontendTagFormat);
      }
    }
  }

  /// Removes tag formatting when backspacing.
  void _removeTagFormatting() {
    for (final tagStyle in tagStyles) {
      final tagIndex = text.lastIndexOf(tagStyle.prefix);
      if (tagIndex != -1 && tagIndex < selection.baseOffset) {
        final potentialTag = text.substring(tagIndex, selection.baseOffset);
        for (final formatToTaggable in _tagBackendFormatsToTaggables.entries) {
          final backendTagFormat = tagStyle.prefix + formatToTaggable.key;
          final frontendTagFormat = tagStyle.prefix + toFrontendConverter(formatToTaggable.value);

          if (potentialTag == backendTagFormat || potentialTag == frontendTagFormat) {
            text = text.replaceRange(tagIndex, selection.baseOffset, '');
            break;
          }
        }
      }
    }
  }

  @override
  void dispose() {
    removeListener(_taggingListeners);
    super.dispose();
  }

  @override
  void clear() {
    _tagBackendFormatsToTaggables.clear();
    super.clear();
  }
}
