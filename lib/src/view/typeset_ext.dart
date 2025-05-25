import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';
import 'package:typeset_tag/src/view/typeset.dart';

///TypeSet extension on String to use [typeset] method
extension TypeSetExtension on String {
  ///[typeset] method to format the text with different styles
  TypeSetTag<T> typeset<T>({
    TextStyle? style,
    TextAlign textAlign = TextAlign.start,
    TextDirection? textDirection,
    Locale? locale,
    bool? softWrap,
    TextOverflow? overflow,
    TextScaler? textScaler,
    int? maxLines,
    String? semanticsLabel,
    TextWidthBasis? textWidthBasis,
    TextHeightBehavior? textHeightBehavior,
    Color? selectionColor,
    StrutStyle? strutStyle,
    GestureRecognizer Function(String linkText, String url)? recognizerBuilder,
    TextStyle? linkStyle,
    TextStyle? boldStyle,
    TextStyle? monospaceStyle,
    TextStyle? mentionStyle,
  }) {
    return TypeSetTag(
      this,
      style: style,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
      strutStyle: strutStyle,
      linkRecognizerBuilder: recognizerBuilder,
      linkStyle: linkStyle,
      boldStyle: boldStyle,
      monospaceStyle: monospaceStyle,
    );
  }
}
