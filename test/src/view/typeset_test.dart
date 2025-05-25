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
      expect(
        await TypesetParser.parser(inputText: inputText),
        allOf(
          hasLength(3),
          predicate(
            (List<TextSpan> s) =>
                s[1].children![0].style?.fontWeight == FontWeight.bold,
          ),
        ),
      );
    });

    test('parses italic text', () async {
      const inputText = 'This _word_ is italic';
      expect(
        await TypesetParser.parser(inputText: inputText),
        allOf(
          hasLength(3),
          predicate(
            (List<TextSpan> s) =>
                s[1].children![0].style?.fontStyle == FontStyle.italic,
          ),
        ),
      );
    });

    test('parses strikethrough text', () async {
      const inputText = 'This ~word~ is strikethrough';
      expect(
        await TypesetParser.parser(inputText: inputText),
        allOf(
          hasLength(3),
          predicate(
            (List<TextSpan> s) =>
                s[1].children![0].style?.decoration == TextDecoration.lineThrough,
          ),
        ),
      );
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
      expect(linkSpan.text, 'Example');
      expect(linkSpan.style?.color, Colors.blue);
      expect(linkSpan.style?.decoration, TextDecoration.underline);
      expect(linkSpan.recognizer, isA<TapGestureRecognizer>());
    });
  });
}
