import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:typeset_tag/src/core/typeset_parser.dart';

void main() {
  group(
    'TypesetParser Tests',
    () {
      test('Parser with bold, italics, link', testBoldItalicLinkInParser);
      test('Parser with monospace', testMonoSpaceInParser);
      test('Parser with custom styling', testCustomStyling);
      test('Parser with font size', testFontSize);
      test('Parser with recognizer', testUrlLauncher);
    },
  );
}

class Taggable {
  const Taggable({required this.id, required this.name});

  final String id;
  final String name;
}

Future<void> testBoldItalicLinkInParser() async {
  const inputText =
      'This is *bold* and _italic_ text with a §link|https://example.com§';
  final spans = await TypesetParser.parser<Taggable>(
    inputText: inputText,
  );

  expect(spans.length, 6);
  expect((spans[0].children!.first as TextSpan).text, 'This is ');
  expect((spans[1].children!.first as TextSpan).text, 'bold');
  expect((spans[2].children!.first as TextSpan).text, ' and ');
  expect((spans[3].children!.first as TextSpan).text, 'italic');
  expect((spans[4].children!.first as TextSpan).text, ' text with a ');
  expect(spans[5].text, 'link');

  expect((spans[1].children!.first as TextSpan).style!.fontWeight,
      FontWeight.w700,);
  expect((spans[3].children!.first as TextSpan).style!.fontStyle,
      FontStyle.italic,);
  expect(spans[5].style!.color, Colors.blue);
}

Future<void> testMonoSpaceInParser() async {
  const inputText = 'This is `monospace` text';
  final spans = await TypesetParser.parser<Taggable>(
    inputText: inputText,
  );

  expect(spans.length, 3);
  expect((spans[0].children!.first as TextSpan).text, 'This is ');
  expect((spans[1].children!.first as TextSpan).text, 'monospace');
  expect((spans[2].children!.first as TextSpan).text, ' text');

  expect((spans[1].children!.first as TextSpan).style!.fontFamily, 'Courier');
}

Future<void> testCustomStyling() async {
  const inputText =
      'This is *bold* and _italic_ text with a §link|https://example.com§';
  const linkStyle = TextStyle(color: Colors.red);
  const boldStyle = TextStyle(fontWeight: FontWeight.w600);
  final recognizer = TapGestureRecognizer()
    ..onTap = () => debugPrint('Link tapped!');
  final spans = await TypesetParser.parser<Taggable>(
    inputText: inputText,
    linkStyle: linkStyle,
    linkRecognizerBuilder: (linkText, url) => recognizer,
    boldStyle: boldStyle,
  );

  expect(spans.length, 6);
  expect((spans[0].children!.first as TextSpan).text, 'This is ');
  expect((spans[1].children!.first as TextSpan).text, 'bold');
  expect((spans[2].children!.first as TextSpan).text, ' and ');
  expect((spans[3].children!.first as TextSpan).text, 'italic');
  expect((spans[4].children!.first as TextSpan).text, ' text with a ');
  expect(spans[5].text, 'link');

  expect((spans[1].children!.first as TextSpan).style!.fontWeight,
      FontWeight.w600,);
  expect((spans[3].children!.first as TextSpan).style!.fontStyle,
      FontStyle.italic,);
  expect(spans[5].style!.color, Colors.red);
  expect(spans[5].recognizer, recognizer);
}

Future<void> testFontSize() async {
  const inputText = 'This is *body<10>* and _title<40>_ size';
  final spans = await TypesetParser.parser<Taggable>(
    inputText: inputText,
  );

  expect(spans.length, 5);
  expect((spans[0].children!.first as TextSpan).text, 'This is ');
  expect((spans[1].children!.first as TextSpan).text, 'body');
  expect((spans[2].children!.first as TextSpan).text, ' and ');
  expect((spans[3].children!.first as TextSpan).text, 'title');
  expect((spans[4].children!.first as TextSpan).text, ' size');

  expect((spans[1].children!.first as TextSpan).style!.fontSize, 10);
  expect((spans[3].children!.first as TextSpan).style!.fontSize, 40);
}

Future<void> testUrlLauncher() async {
  const inputText = 'This is a §link|https://google.com§';
  final spans = await TypesetParser.parser<Taggable>(
    inputText: inputText,
    linkRecognizerBuilder: (text, url) => TapGestureRecognizer()
      ..onTap = () => debugPrint('URL: $url and Text: $text'),
  );

  expect(spans[1].recognizer.runtimeType, TapGestureRecognizer);
}
