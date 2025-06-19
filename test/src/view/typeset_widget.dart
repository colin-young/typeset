import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:typeset_tag/typeset.dart';

/// A test widget for TypeSet functionality that displays text with TypeSet
/// formatting.
/// 
/// This widget creates a centered column containing either a [TypeSetTag] or a 
/// typeset extension method application, based on the provided parameters.
class TypeSetTest extends StatelessWidget {
  /// Creates a [TypeSetTest] widget.
  /// 
  /// The [title] parameter is used with [TypeSetTag] when provided.
  /// The [titleForExt] parameter is used with the typeset extension method.
  /// The [style] parameter can be used to customize the text appearance for
  /// either display method.
  const TypeSetTest({
    super.key,
    this.title,
    this.style,
    this.titleForExt,
  });

  /// The text to be displayed using [TypeSetTag].
  final String? title;

  /// The style to be applied to the displayed text.
  final TextStyle? style;

  /// The text to be displayed using the typeset extension method.
  final String? titleForExt;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            children: [
              if (title != null)
                TypeSetTag<Taggable>(
                  title!,
                  style: style,
                  linkRecognizerBuilder: (linkText, url) =>
                      TapGestureRecognizer()
                        ..onTap = () {
                          debugPrint('Link tapped');
                        },
                ),
              if (titleForExt != null)
                titleForExt!.typeset<Taggable>(
                  style: style,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
