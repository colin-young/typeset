import 'package:flutter/widgets.dart';
import 'package:typeset_tag/src/taggable/constants.dart';
import 'package:typeset_tag/src/taggable/utils/tag.dart';
import 'package:typeset_tag/typeset.dart';

/// Returns a [TextSpan] based on the parsed tags and text content
///
/// The generic type [T] represents the type of data associated with the tags
/// that will be parsed and converted into the resulting [TextSpan].
///
/// A [TextSpan] is a segment of text that can have its own style and gesture
/// recognizers, which makes it suitable for rich text rendering.
TextSpan getTaggableSpan<T>({
    required String content,
    required BuildContext context,
    TextStyle? style,
    required String Function<T>(T taggable) toFrontendConverter,
    required String Function<T>(T taggable) toBackendConverter,
    required TextStyle? Function(BuildContext, String) textStyleBuilder,
    required Map<String, T> tagBackendFormatsToTaggables,
    required List<TagStyle> tagStyles,
  }) {
    final spans = <TextSpan>[];

    var position = 0;

    for (final match in getTagMatches(content, tagStyles)) {
      final textBeforeTag = content.substring(position, match.start);
      spans.add(TextSpan(text: textBeforeTag));

      position = match.end;

      final tag = parseTagString(
        match.group(0)!,
        tagStyles: tagStyles,
        tagBackendFormatsToTaggables: tagBackendFormatsToTaggables,
      );
      if (tag == null) {
        spans.add(TextSpan(text: match.group(0)));
        continue;
      }

      final tagText = tag.toModifiedString(
        toFrontendConverter,
        toBackendConverter,
        isFrontend: true,
      );
      // final tagText = toFrontendConverter(tag.taggable);

      // final taggable = toTaggableFromBackend('', tagText);
      // final tagSpan = await convertTagTextToInlineSpans<T>(
      //   tagText,
      //   tagStyles: tagStyles,
      //   backendToTaggable: toTaggableFromBackend,
      //   taggableToInlineSpan: (T taggable, TagStyle tagStyle) {
      //     return TextSpan(
      //       text: '${tagStyle.prefix}$tagText',
      //       style: textStyleBuilder(context, tagStyle.prefix, taggable),
      //     );
      //   },
      // );

      final textStyle =
          textStyleBuilder.call(context, tag.style.prefix) ??
              style;
      // The Flutter engine does not render zero-width spaces with actual zero
      // width, so we need to split the tag into two parts: the leading space
      // markers and the actual tag text, while applying a zero letter spacing
      // to the former. This issue is tracked on the Flutter GitHub repository:
      // https://github.com/flutter/flutter/issues/160251
      final lastSpaceMarker = tagText.lastIndexOf(spaceMarker);
      if (lastSpaceMarker != -1) {
        spans
          ..add(
            TextSpan(
              text: tagText.substring(0, lastSpaceMarker + 1),
              style: const TextStyle(letterSpacing: 0),
            ),
          )
          ..add(
            TextSpan(
              text: tagText.substring(lastSpaceMarker + 1),
              style: textStyle,
            ),
          );
        continue;
      }

      spans.add(TextSpan(text: tagText, style: textStyle));
    }

    final textAfterAllTags = content.substring(position, content.length);
    spans.add(TextSpan(text: textAfterAllTags));

    return TextSpan(
      children: spans,
      style: style,
    );
  }


/// Returns all matching tags in the text based on the tag styles.
Iterable<Match> getTagMatches(String text, List<TagStyle> tagStyles) {
  final pattern = tagStyles
      .map(
        (style) =>
            '${RegExp.escape(style.prefix)}$spaceMarker*(${style.regExp})',
      )
      .join('|');
  return RegExp(pattern).allMatches(text);
}

/// Parses a tag string (e.g. "@tag") and returns a tag object.
Tag<T>? parseTagString<T>(
  String tagString, {
  required List<TagStyle> tagStyles,
  required Map<String, T> tagBackendFormatsToTaggables,
}) {
  final tagStyle = tagStyles
      .where((style) => tagString.startsWith(style.prefix))
      .firstOrNull;
  final taggable = tagBackendFormatsToTaggables[tagString];
  if (tagStyle == null || taggable == null) return null;

  return Tag<T>(taggable: taggable, style: tagStyle);
}
