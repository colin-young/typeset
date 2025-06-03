// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:typeset_tag/src/core/typeset_parser.dart';
import 'typeset_widget.dart';

/// A class representing a taggable item with an ID and name for testing
/// purposes.
class Taggable {
  const Taggable({required this.id, required this.name});

  final String id;
  final String name;
}

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

      testWidgets(
        'TypeSet widget handles font size formatting',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const TypeSetTest(
              title: 'Hello *World<24>* and _text<18>_',
              key: Key('font_size_test'),
            ),
          );

          expect(find.byKey(const Key('font_size_test')), findsOneWidget);
        },
      );

      testWidgets(
        'TypeSet widget handles sequential formatting',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const TypeSetTest(
              title: 'Hello *bold* _italic_ ~strike~',
              key: Key('sequential_format_test'),
            ),
          );

          expect(
            find.byKey(const Key('sequential_format_test')),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'TypeSet widget handles empty text gracefully',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const TypeSetTest(
              title: '',
              key: Key('empty_text_test'),
            ),
          );

          expect(find.byKey(const Key('empty_text_test')), findsOneWidget);
        },
      );

      testWidgets(
        'TypeSet widget handles malformed tags gracefully',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const TypeSetTest(
              title: 'Hello *World and _text',
              key: Key('malformed_tags_test'),
            ),
          );

          expect(find.byKey(const Key('malformed_tags_test')), findsOneWidget);
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
        await TypesetParser.parser<Taggable>(inputText: inputText),
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
        await TypesetParser.parser<Taggable>(inputText: inputText),
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
        await TypesetParser.parser<Taggable>(inputText: inputText),
        allOf(
          hasLength(3),
          predicate(
            (List<TextSpan> s) =>
                s[1].children![0].style?.decoration ==
                TextDecoration.lineThrough,
          ),
        ),
      );
    });

    test('parses font size correctly', () async {
      const inputText = 'This is *text<24>* and _more<18>_';
      final spans = await TypesetParser.parser<Taggable>(inputText: inputText);

      expect(spans.length, 4);
      expect((spans[1].children![0] as TextSpan).style?.fontSize, 24);
      expect((spans[3].children![0] as TextSpan).style?.fontSize, 18);
    });

    test('handles sequential formatting correctly', () async {
      const inputText = 'This is *bold* _italic_ ~strike~';
      final spans = await TypesetParser.parser<Taggable>(inputText: inputText);

      expect(spans.length, equals(6));

      // Check bold
      final boldSpan = spans[1].children![0] as TextSpan;
      expect(boldSpan.style?.fontWeight, FontWeight.bold);

      // Check italic
      final italicSpan = spans[3].children![0] as TextSpan;
      expect(italicSpan.style?.fontStyle, FontStyle.italic);

      // Check strikethrough
      final strikeSpan = spans[5].children![0] as TextSpan;
      expect(strikeSpan.style?.decoration, TextDecoration.lineThrough);
    });

    test('treats malformed links as plain text', () async {
      const inputText = 'Bad link §missing parts§ and §noUrl§';
      final spans = await TypesetParser.parser<Taggable>(
        inputText: inputText,
        linkRecognizerBuilder: (linkText, url) => TapGestureRecognizer(),
      );

      // For malformed links, the text should be parsed as plain text
      expect(
        spans.map((s) => s.toPlainText()).join(),
        'Bad link missing parts and noUrl',
      );
    });

    test('handles well-formed links correctly', () async {
      const inputText = '§Click here|https://example.com§';
      final spans = await TypesetParser.parser<Taggable>(
        inputText: inputText,
        linkRecognizerBuilder: (linkText, url) => TapGestureRecognizer()
          ..onTap = () {
            debugPrint('Link tapped');
          },
        linkStyle: const TextStyle(color: Colors.blue),
      );

      expect(spans.length, 1);
      final linkSpan = spans[0];
      expect(linkSpan.text, 'Click here');
      expect(linkSpan.style?.color, Colors.blue);
      expect(linkSpan.recognizer, isA<TapGestureRecognizer>());
    });

    test('handles escaped characters correctly', () async {
      const inputText = 'This is ¦*not bold¦* but *this is bold*';
      final spans = await TypesetParser.parser<Taggable>(inputText: inputText);

      // The escaped characters should remain as plain text
      expect(spans[0].toPlainText(), 'This is *not bold* but ');

      final boldSpan = spans[1];
      expect(boldSpan.children!.first.style?.fontWeight, FontWeight.bold);
      expect(boldSpan.toPlainText(), 'this is bold');
    });

    test('handles consecutive formatting markers', () async {
      const inputText = '*bold*_italic_~strike~';
      final spans = await TypesetParser.parser<Taggable>(inputText: inputText);

      expect(spans.length, 3);

      // Check each formatting style is applied correctly
      final boldSpan = spans[0].children!.first;
      final italicSpan = spans[1].children!.first;
      final strikeSpan = spans[2].children!.first;

      expect(boldSpan.style?.fontWeight, FontWeight.bold);
      expect(italicSpan.style?.fontStyle, FontStyle.italic);
      expect(strikeSpan.style?.decoration, TextDecoration.lineThrough);

      // Check the text content
      expect(spans[0].toPlainText(), 'bold');
      expect(spans[1].toPlainText(), 'italic');
      expect(spans[2].toPlainText(), 'strike');
    });

    test('handles consecutive formatted sections', () async {
      const inputText = 'Text with *bold*_italic_~strike~';
      final spans = await TypesetParser.parser<Taggable>(inputText: inputText);

      // 4 sections: plain text + 3 formatted sections
      expect(spans.length, 4);

      // Plain text prefix
      expect(spans[0].toPlainText(), 'Text with ');

      // Bold section
      expect(spans[1].toPlainText(), 'bold');
      final boldSpanChild = spans[1].children!.first as TextSpan;
      expect(boldSpanChild.style!.fontWeight, FontWeight.bold);

      // Italic section
      expect(spans[2].toPlainText(), 'italic');
      final italicSpanChild = spans[2].children!.first as TextSpan;
      expect(italicSpanChild.style!.fontStyle, FontStyle.italic);

      // Strikethrough section
      expect(spans[3].toPlainText(), 'strike');
      final strikeSpanChild = spans[3].children!.first as TextSpan;
      expect(strikeSpanChild.style!.decoration, TextDecoration.lineThrough);
    });

    test('handles complex link styling', () async {
      const inputText =
          '§Click me|https://example.com§ and §Contact|mailto:test@example.com§';
      final recognizers = <TapGestureRecognizer>[];

      final spans = await TypesetParser.parser<Taggable>(
        inputText: inputText,
        linkRecognizerBuilder: (text, url) {
          final recognizer = TapGestureRecognizer();
          recognizers.add(recognizer);
          return recognizer;
        },
        linkStyle: const TextStyle(color: Colors.red),
      );

      expect(spans.length, 3);
      expect(spans[0].text, 'Click me');
      expect(spans[0].style?.color, Colors.red);
      expect(spans[2].text, 'Contact');
      expect(spans[2].style?.color, Colors.red);
      expect(recognizers.length, 2);

      // Clean up recognizers
      for (final recognizer in recognizers) {
        recognizer.dispose();
      }
    });

    test('handles combined text styling', () async {
      const inputText = '*bold _and_ bold* and *bold ~strike~ bold*';
      final spans = await TypesetParser.parser<Taggable>(inputText: inputText);

      // Bold text with inner formatting markers preserved
      expect(spans[0].toPlainText(), 'bold _and_ bold');
      expect(
        (spans[0].children!.first as TextSpan).style?.fontWeight,
        FontWeight.bold,
      );

      // Plain text between formatted sections
      expect(spans[1].toPlainText(), ' and ');

      // Second bold section with strike markers preserved
      expect(spans[2].toPlainText(), 'bold ~strike~ bold');
      expect(
        (spans[2].children!.first as TextSpan).style?.fontWeight,
        FontWeight.bold,
      );
    });

    test('handles whitespace in formatted text correctly', () async {
      const inputText = 'Text with *  spaced  * and _  padded  _ content';
      final spans = await TypesetParser.parser<Taggable>(inputText: inputText);

      // Check that whitespace is preserved in bold section
      final boldSpan = spans[1];
      expect(boldSpan.toPlainText(), '  spaced  ');
      expect(
        (boldSpan.children!.first as TextSpan).style?.fontWeight,
        FontWeight.bold,
      );

      // Check that whitespace is preserved in italic section
      final italicSpan = spans[3];
      expect(italicSpan.toPlainText(), '  padded  ');
      expect(
        (italicSpan.children!.first as TextSpan).style?.fontStyle,
        FontStyle.italic,
      );
    });

    test('handles special characters in formatted text', () async {
      const inputText = '*bold with #&@ chars* and _italic with !%^ chars_';
      final spans = await TypesetParser.parser<Taggable>(inputText: inputText);

      final boldSpan = spans[0];
      expect(boldSpan.toPlainText(), 'bold with #&@ chars');
      expect(
        (boldSpan.children!.first as TextSpan).style?.fontWeight,
        FontWeight.bold,
      );

      final italicSpan = spans[2];
      expect(italicSpan.toPlainText(), 'italic with !%^ chars');
      expect(
        (italicSpan.children!.first as TextSpan).style?.fontStyle,
        FontStyle.italic,
      );
    });

    test('handles long formatted sections', () async {
      const inputText =
          // ignore: lines_longer_than_80_chars
          '*This is a very long bold text that spans multiple words and should be handled correctly by the parser without any issues*';
      final spans = await TypesetParser.parser<Taggable>(inputText: inputText);

      expect(spans.length, 1);
      final boldSpan = spans[0];
      expect(
        boldSpan.toPlainText(),
        // ignore: lines_longer_than_80_chars
        'This is a very long bold text that spans multiple words and should be handled correctly by the parser without any issues',
      );
      expect(
        (boldSpan.children!.first as TextSpan).style?.fontWeight,
        FontWeight.bold,
      );
    });

    // test('handles multiple unclosed formatting markers gracefully', () async {
    //   const inputText = 'Text with unclosed bold and _unclosed italic';
    //   final spans = await TypesetParser.parser<Taggable>(inputText: inputText);

    //   // The text should preserve unclosed markers as plain text
    //   final plainText = spans.map((s) => s.toPlainText()).join();
    //   expect(plainText, 'Text with unclosed bold and _unclosed italic');

    //   // All spans should be plain text, no styling applied
    //   for (final span in spans) {
    //     final childSpan = span.children!.first as TextSpan;
    //     expect(childSpan.style?.fontWeight, null); // No bold
    //     expect(childSpan.style?.fontStyle, null); // No italic
    //   }
    // });

    test('handles escaped characters within formatting', () async {
      const inputText = '*bold with ¦* escaped* and _italic with ¦_ escaped_';
      final spans = await TypesetParser.parser<Taggable>(inputText: inputText);

      // First span should be bold and include the escaped * character
      final boldSpan = spans[0];
      expect(boldSpan.toPlainText(), 'bold with * escaped');
      expect(
        (boldSpan.children!.first as TextSpan).style?.fontWeight,
        FontWeight.bold,
      );

      // Second span should be italic and include the escaped _ character
      final italicSpan = spans[2];
      expect(italicSpan.toPlainText(), 'italic with _ escaped');
      expect(
        (italicSpan.children!.first as TextSpan).style?.fontStyle,
        FontStyle.italic,
      );
    });

    test('handles monospace sections', () async {
      const inputText = '`monospace text` and `more code`';
      final spans = await TypesetParser.parser<Taggable>(inputText: inputText);

      final firstMonoSpan = spans[0];
      expect(firstMonoSpan.toPlainText(), 'monospace text');
      expect(
        (firstMonoSpan.children!.first as TextSpan).style?.fontFamily,
        'Courier',
      );

      final secondMonoSpan = spans[2];
      expect(secondMonoSpan.toPlainText(), 'more code');
      expect(
        (secondMonoSpan.children!.first as TextSpan).style?.fontFamily,
        'Courier',
      );
    });

    test('handles empty formatted sections', () async {
      const inputText = 'Text with ** _empty_ ~~ content';
      final spans = await TypesetParser.parser<Taggable>(inputText: inputText);

      // TODO:Empty formatting markers should be removed
      expect(spans.length, 7);
      expect(spans[0].toPlainText(), 'Text with ');
      // expect(spans[6].children?[0].toPlainText(), ' empty  content');
      expect(spans[6].children?[0].toPlainText(), ' content');
    });
  });
}
