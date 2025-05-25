import 'dart:async';
import 'dart:core';

import 'package:flutter/widgets.dart';
import 'package:typeset_tag/typeset.dart';

class TagParserParts<T> {
  TagParserParts({
    required this.toFrontendConverter,
    required this.toBackendConverter,
    required this.backendToTaggable,
    required this.taggableToInlineSpan,
    required this.textStyleBuilder,
    required this.context,
    required this.tagStyles,
  });

  final String Function<T>(T taggable)? toFrontendConverter;
  final String Function<T>(T taggable)? toBackendConverter;
  final FutureOr<T?> Function(String prefix, String id) backendToTaggable;
  final InlineSpan Function(T, TagStyle) taggableToInlineSpan;
  final TextStyle? Function(BuildContext context, String prefix)
      textStyleBuilder;
  final List<TagStyle> tagStyles;
  final BuildContext context;
}
