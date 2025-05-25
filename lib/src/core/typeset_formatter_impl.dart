import 'package:typeset_tag/src/core/typeset_formatter.dart';

/// Concrete implementation of the TypesetFormatter abstract class
class TypesetFormatterImpl extends TypesetFormatter {
  const TypesetFormatterImpl({
    required super.showFormattingCharacters,
    required super.markerColor,
    super.linkStyle,
    super.monospaceStyle,
    super.boldStyle,
  });
}
