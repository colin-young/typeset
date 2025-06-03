import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:typeset_tag/src/taggable/constants.dart';
import 'package:typeset_tag/src/taggable/utils/tag_parser.dart';
import 'package:typeset_tag/src/taggable/utils/tag_style.dart';

void main() {
  group('TagParser', () {
    setUp(TestWidgetsFlutterBinding.ensureInitialized);

    group('getTagMatches', () {
      test('returns empty iterable when no tags present', () {
        final tagStyles = [
          const TagStyle(regExp: '[a-zA-Z]+'),
        ];

        final matches = getTagMatches('plain text without tags', tagStyles);

        expect(matches, isEmpty);
      });

      test('finds single tag in text', () {
        final tagStyles = [
          const TagStyle(regExp: '[a-zA-Z]+'),
        ];

        final matches = getTagMatches('Hello @user!', tagStyles).toList();

        expect(matches.length, 1);
        expect(matches[0].group(0), '@user');
      });

      test('finds multiple tags with different styles', () {
        final tagStyles = [
          const TagStyle(regExp: '[a-zA-Z]+'),
          const TagStyle(prefix: '#'),
        ];

        final matches =
            getTagMatches('Hello @user! Check out #tag123', tagStyles).toList();

        expect(matches.length, 2);
        expect(matches[0].group(0), '@user');
        expect(matches[1].group(0), '#tag123');
      });
    });

    group('parseTagString', () {
      test('returns null for invalid tag format', () {
        final tagStyles = [
          const TagStyle(regExp: '[a-zA-Z]+'),
        ];
        final tagBackendFormats = <String, String>{
          '@user': 'user',
        };

        final result = parseTagString<String>(
          'invalid',
          tagStyles: tagStyles,
          tagBackendFormatsToTaggables: tagBackendFormats,
        );

        expect(result, isNull);
      });

      test('returns Tag object for valid tag', () {
        final tagStyles = [
          const TagStyle(regExp: '[a-zA-Z]+'),
        ];
        final tagBackendFormats = <String, String>{
          '@user': 'user',
        };

        final result = parseTagString<String>(
          '@user',
          tagStyles: tagStyles,
          tagBackendFormatsToTaggables: tagBackendFormats,
        );

        expect(result, isNotNull);
        expect(result?.style.prefix, '@');
        expect(result?.taggable, 'user');
      });
    });

    group('getTaggableSpan', () {
      testWidgets('returns span containing given text without tags',
          (tester) async {
        await tester.pumpWidget(Container());
        final BuildContext context = tester.element(find.byType(Container));
        const style = TextStyle(fontSize: 16);
        final span = getTaggableSpan<String>(
          content: 'plain text',
          context: context,
          style: style,
          toFrontendConverter: <T>(T tag) => tag.toString(),
          toBackendConverter: <T>(T tag) => tag.toString(),
          textStyleBuilder: (_, __) => null,
          tagBackendFormatsToTaggables: {},
          tagStyles: [],
        );

        final texts =
            span.children?.whereType<TextSpan>().map((s) => s.text).toList() ??
                [];
        expect(texts.join(), equals('plain text'));
        expect(span.style, style);
      });

      testWidgets('splits text with tag into multiple spans', (tester) async {
        await tester.pumpWidget(Container());
        final BuildContext context = tester.element(find.byType(Container));
        const tagStyles = [
          TagStyle(regExp: '[a-zA-Z]+'),
        ];
        final tagBackendFormats = <String, String>{
          '@user': 'user',
        };

        final span = getTaggableSpan<String>(
          content: 'Hello @user!',
          context: context,
          toFrontendConverter: <T>(T tag) => tag.toString(),
          toBackendConverter: <T>(T tag) => tag.toString(),
          textStyleBuilder: (_, __) =>
              const TextStyle(fontWeight: FontWeight.w700),
          tagBackendFormatsToTaggables: tagBackendFormats,
          tagStyles: tagStyles,
        );

        final textSpans = span.children?.whereType<TextSpan>().toList() ?? [];
        expect(textSpans.length, equals(3));
        expect(textSpans[0].text, equals('Hello '));
        expect(textSpans[1].text, equals('@user'));
        expect(textSpans[1].style?.fontWeight, equals(FontWeight.w700));
        expect(textSpans[2].text, equals('!'));
      });

      testWidgets('handles space markers correctly', (tester) async {
        await tester.pumpWidget(Container());
        final BuildContext context = tester.element(find.byType(Container));
        const tagStyles = [
          TagStyle(regExp: '[a-zA-Z]+'),
        ];
        final tagBackendFormats = <String, String>{
          '@user': 'user',
        };

        final span = getTaggableSpan<String>(
          content: 'Hello @user!',
          context: context,
          toFrontendConverter: <T>(T tag) => tag.toString() + spaceMarker,
          toBackendConverter: <T>(T tag) => tag.toString(),
          textStyleBuilder: (_, __) =>
              const TextStyle(fontWeight: FontWeight.w700),
          tagBackendFormatsToTaggables: tagBackendFormats,
          tagStyles: tagStyles,
        );

        final textSpans = span.children?.whereType<TextSpan>().toList() ?? [];
        expect(
          textSpans.length,
          equals(3),
        ); // Text before, tag with space marker, text after

        // Check the spans in sequence
        expect(textSpans[0].text, equals('Hello ')); // Text before tag

        // Check that the tag has the style and starts with @user
        expect(textSpans[1].text?.startsWith('@user'), isTrue); // Tag text
        expect(
          textSpans[1].style?.fontWeight,
          equals(FontWeight.w700),
        ); // Tag style is applied
        expect(
          textSpans[1].text?.endsWith('\u200b'),
          isTrue,
        ); // Has space marker
        expect(
          textSpans[1].style?.letterSpacing,
          equals(0),
        ); // Zero letter spacing because it has marker

        expect(textSpans[2].text, equals('!')); // Text after tag
      });
    });
  });
}
