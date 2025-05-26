// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:typeset_tag/src/core/typeset_parser.dart';

import '../core/typeset_parser_test.dart';
import 'typeset_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    'Tests for TypeSet Widget',
    () {
      testWidgets(
        'TypeSet widget displays bold, italic, and strikethrough text',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const TypeSetTest(
              title:
                  'Hello, *World* _World_ ~World~ //hello// [hello](https://google.com)',
              key: Key(
                'typeset_widget_test',
              ),
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
              ),
            ),
          );

          final boldItalicUnderlineText = find.byKey(
            const Key(
              'typeset_widget_test',
            ),
          );

          expect(
            boldItalicUnderlineText,
            findsOneWidget,
          );
        },
      );
    },
  );

  group('Tests for TypeSetExtension', () {
    testWidgets(
      'TypeSet widget displays through extension',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const TypeSetTest(
            titleForExt: 'Hello World',
            key: Key(
              'extensionTest',
            ),
          ),
        );

        final extensionTest = find.byKey(
          const Key(
            'extensionTest',
          ),
        );
        expect(
          extensionTest,
          findsOneWidget,
        );
      },
    );
  });

  group('TypesetParser parser', () {
    test('parses bold text', () async {
      const inputText = 'This *word* is bold';
      final spans = await TypesetParser.parser<dynamic>(inputText: inputText);

      expect(spans, hasLength(3));
      expect(spans[0], isA<TextSpan>());
      expect((spans[0] as TextSpan).text, 'This ');

      expect(spans[1], isA<TextSpan>());
      final boldSpan = spans[1] as TextSpan;
      expect(boldSpan.text, 'word');
      expect(boldSpan.style?.fontWeight, FontWeight.bold);

      expect(spans[2], isA<TextSpan>());
      expect((spans[2] as TextSpan).text, ' is bold');
    });

    test('parses italic text', () async {
      const inputText = 'This _word_ is italic';
      final spans = await TypesetParser.parser<dynamic>(inputText: inputText);

      expect(spans, hasLength(3));
      expect(spans[0], isA<TextSpan>());
      expect((spans[0] as TextSpan).text, 'This ');

      expect(spans[1], isA<TextSpan>());
      final italicSpan = spans[1] as TextSpan;
      expect(italicSpan.text, 'word');
      expect(italicSpan.style?.fontStyle, FontStyle.italic);

      expect(spans[2], isA<TextSpan>());
      expect((spans[2] as TextSpan).text, ' is italic');
    });

    test('parses strikethrough text', () async {
      const inputText = 'This ~word~ is strikethrough';
      final spans = await TypesetParser.parser<dynamic>(inputText: inputText);

      expect(spans, hasLength(3));
      expect(spans[0], isA<TextSpan>());
      expect((spans[0] as TextSpan).text, 'This ');

      expect(spans[1], isA<TextSpan>());
      final strikeSpan = spans[1] as TextSpan;
      expect(strikeSpan.text, 'word');
      expect(strikeSpan.style?.decoration, TextDecoration.lineThrough);

      expect(spans[2], isA<TextSpan>());
      expect((spans[2] as TextSpan).text, ' is strikethrough');
    });

    test('parses link correctly', () async {
      const inputText = '§Example|http://example.com§';

      final result = await TypesetParser.parser<Taggable>(
        inputText: inputText,
        linkRecognizerBuilder: (linkText, url) => TapGestureRecognizer()
          ..onTap = () {
            debugPrint('Link tapped');
          },
      );

      expect(result.length, 1);
      final linkSpan = result[0];
      expect((linkSpan as TextSpan).text, 'Example');
      expect(linkSpan.style?.color, Colors.blue);
      expect(linkSpan.style?.decoration, TextDecoration.underline);
      expect(linkSpan.recognizer, isA<TapGestureRecognizer>());
    });
  });
}
