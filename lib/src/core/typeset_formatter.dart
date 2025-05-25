import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:typeset_tag/src/core/typeset_reserved.dart';
import 'package:typeset_tag/src/models/style_type_enum.dart';

/// Base class for TypesetParser and TypeSetEditingController that contains
/// shared formatting logic for parsing and formatting text with WhatsApp-style
/// formatting markers
abstract class TypesetFormatter {
  const TypesetFormatter({
    this.showFormattingCharacters = false,
    this.linkStyle,
    this.monospaceStyle,
    this.boldStyle,
    this.markerColor = const Color(0xFF9E9E9E),
  });

  /// Whether formatting characters should be displayed in the output
  final bool showFormattingCharacters;

  /// The style to apply to links in the text
  final TextStyle? linkStyle;

  /// The style to apply to monospace text
  final TextStyle? monospaceStyle;

  /// The style to apply to bold text
  final TextStyle? boldStyle;

  /// The color to use for formatting markers when they are visible
  final Color markerColor;

  /// Creates a TextStyle to be applied to formatting characters
  TextStyle? getFormattingMarkerStyle() {
    return showFormattingCharacters ? TextStyle(color: markerColor) : null;
  }

  /// Gets the style for formatted content between markers
  TextStyle getContentStyleForMarker(String marker, TextStyle? baseStyle, {double? fontSize}) {
    switch (marker) {
      case TypesetReserved.boldChar:
        return boldStyle?.copyWith(fontSize: fontSize) ?? TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize);
      case TypesetReserved.italicChar:
        return TextStyle(fontStyle: FontStyle.italic, fontSize: fontSize);
      case TypesetReserved.strikethroughChar:
        return TextStyle(decoration: TextDecoration.lineThrough, fontSize: fontSize);
      case TypesetReserved.underlineChar:
        return TextStyle(decoration: TextDecoration.underline, fontSize: fontSize);
      case TypesetReserved.monospaceChar:
        return monospaceStyle?.copyWith(fontSize: fontSize) ?? TextStyle(fontFamily: 'Courier', fontSize: fontSize);
      case TypesetReserved.linkChar:
        return linkStyle?.copyWith(fontSize: fontSize) ?? 
               TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: fontSize);
      default:
        return baseStyle?.copyWith(fontSize: fontSize) ?? TextStyle(fontSize: fontSize);
    }
  }

  /// Checks if a character is a formatting marker
  bool isFormattingMarker(String char) {
    return char == TypesetReserved.boldChar ||
           char == TypesetReserved.italicChar ||
           char == TypesetReserved.strikethroughChar ||
           char == TypesetReserved.underlineChar ||
           char == TypesetReserved.monospaceChar ||
           char == TypesetReserved.linkChar;
  }

  /// Process a text segment and return appropriate TextSpan(s)
  Future<List<TextSpan>> processTextSegment({
    required String text,
    required StyleTypeEnum styleType,
    required TextStyle? baseStyle,
    required BuildContext? context,
    GestureRecognizer Function(String text, String url)? linkRecognizerBuilder,
  }) async {
    final spans = <TextSpan>[];

    // Extract font size if present
    final regex = RegExp(TypesetReserved.fontSizeRegex);
    final match = regex.firstMatch(text);
    final content = match?.group(1) ?? text;
    final fontSize = match == null ? null : double.tryParse(match.group(2) ?? '');

    switch (styleType) {
      case StyleTypeEnum.link:
        final linkParts = content.split(TypesetReserved.linkSplitChar);
        final linkText = linkParts.isNotEmpty ? linkParts[0] : '';
        final url = linkParts.length == 2 ? linkParts[1] : '';

        if (showFormattingCharacters) {
          spans.add(TextSpan(text: linkText, style: getContentStyleForMarker(TypesetReserved.linkChar, baseStyle, fontSize: fontSize)));
          if (linkParts.length > 1) {
            spans.addAll([
              TextSpan(text: TypesetReserved.linkSplitChar, style: getFormattingMarkerStyle()),
              TextSpan(text: url, style: getContentStyleForMarker(TypesetReserved.linkChar, baseStyle)),
            ]);
          }
        } else {
          spans.add(
            TextSpan(
              text: linkText,
              style: getContentStyleForMarker(TypesetReserved.linkChar, baseStyle, fontSize: fontSize),
              recognizer: linkRecognizerBuilder?.call(linkText, url),
            ),
          );
        }
        break;

      case StyleTypeEnum.mention:
        // Handle mentions similar to plain text for now
        spans.add(TextSpan(text: content, style: baseStyle));
        break;

      case StyleTypeEnum.plain:
      case StyleTypeEnum.bold:
      case StyleTypeEnum.italic:
      case StyleTypeEnum.monospace:
      case StyleTypeEnum.strikethrough:
      case StyleTypeEnum.underline:
        final contentStyle = getContentStyleForMarker(
          getMarkerForStyleType(styleType),
          baseStyle,
          fontSize: fontSize,
        );
        spans.add(TextSpan(text: content, style: contentStyle));
        break;
    }

    return spans;
  }

  /// Get the marker character for a style type
  String getMarkerForStyleType(StyleTypeEnum type) {
    switch (type) {
      case StyleTypeEnum.bold:
        return TypesetReserved.boldChar;
      case StyleTypeEnum.italic:
        return TypesetReserved.italicChar;
      case StyleTypeEnum.monospace:
        return TypesetReserved.monospaceChar;
      case StyleTypeEnum.strikethrough:
        return TypesetReserved.strikethroughChar;
      case StyleTypeEnum.underline:
        return TypesetReserved.underlineChar;  
      case StyleTypeEnum.link:
        return TypesetReserved.linkChar;
      case StyleTypeEnum.mention:
      case StyleTypeEnum.plain:
        return '';
    }
  }
}
