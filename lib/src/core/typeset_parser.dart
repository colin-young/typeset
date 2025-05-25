import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:typeset_tag/src/core/typeset_controller.dart';
import 'package:typeset_tag/src/core/typeset_formatter.dart';
import 'package:typeset_tag/src/taggable/utils/tag_parser_parts.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

/// TypesetParser handles parsing text with WhatsApp-style formatting markers
/// and converts them into properly formatted TextSpans without showing formatting characters
class TypesetParser extends TypesetFormatter {
  const TypesetParser({
    super.linkStyle,
    super.monospaceStyle,
    super.boldStyle,
  }) : super(showFormattingCharacters: false);

  /// Parse input text with formatting markers and return formatted TextSpans
  static Future<List<InlineSpan>> parser<T>({
    required String inputText,
    TextStyle? linkStyle,
    GestureRecognizer Function(String text, String url)? linkRecognizerBuilder,
    TextStyle? monospaceStyle,
    TextStyle? boldStyle,
    TagParserParts<T>? tagParserParts,
  }) async {
    final parser = TypesetParser(
      linkStyle: linkStyle,
      monospaceStyle: monospaceStyle,
      boldStyle: boldStyle,
    );

    final controller = TypesetController(input: inputText);
    final spans = <InlineSpan>[];

    for (final text in controller.manipulateString()) {
      spans.addAll(
        await parser.processTextSegment(
          text: text.value,
          styleType: text.styleType,
          baseStyle: null,
          context: null,
          linkRecognizerBuilder: linkRecognizerBuilder ?? _launch,
        ),
      );
    }

    return spans;
  }

  /// Default link handler that launches URLs
  static GestureRecognizer _launch(String text, String url) {
    return TapGestureRecognizer()
      ..onTap = () async {
        final uri = Uri.parse(url);
        if (await launcher.canLaunchUrl(uri)) {
          await launcher.launchUrl(uri);
        }
      };
  }
}
