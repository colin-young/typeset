import 'dart:async';
import 'dart:core';

import 'package:flutter/widgets.dart';
import 'package:typeset_tag/typeset.dart';

/// A class for parsing and managing tags of type [T].
///
/// This utility class provides functionality to parse and process tags of a
/// generic type [T]. It helps in breaking down tag-related operations into
/// manageable parts and provides a structured way to handle tag parsing
/// operations.
///
/// Example:
/// ```dart
/// final parser = TagParserParts<String>();
/// ```
class TagParserParts<T> {
  /// Creates a [TagParserParts] instance.
  ///
  /// A utility class that helps parse and organize different parts of a tag
  /// structure. Used in tag parsing operations to break down tag components
  /// into manageable parts.
  TagParserParts({
    required this.toFrontendConverter,
    required this.toBackendConverter,
    required this.backendToTaggable,
    required this.taggableToInlineSpan,
    required this.textStyleBuilder,
    required this.context,
    required this.tagStyles,
  });

  /// Function that converts a taggable object of type [T] to its string
  /// representation for frontend display.
  ///
  /// This converter is optional and can be null. When provided, it transforms
  /// the taggable object into a string format suitable for display or
  /// processing in the frontend layer.
  ///
  /// Example:
  /// ```dart
  /// toFrontendConverter = (User user) => user.displayName;
  /// ```
  ///
  /// The function takes a single parameter of type [T] and returns a [String].
  final String Function<T>(T taggable)? toFrontendConverter;

  /// A function that converts a taggable object of type T to its string
  /// representation for backend storage.
  ///
  /// This function is optional and can be `null`. When provided, it's used to
  /// convert taggable objects to their string form before sending to the
  /// backend.
  ///
  /// Example:
  /// ```dart
  /// toBackendConverter: (User user) => user.id.toString()
  /// ```
  ///
  /// @param taggable The object to convert
  /// @returns A string representation of the taggable object
  final String Function<T>(T taggable)? toBackendConverter;

  /// A function that converts a tag backend representation to a taggable
  /// entity.
  ///
  /// Takes a prefix and id string parameters and returns a [FutureOr] that
  /// resolves to either a nullable [T] type instance or null.
  ///
  /// The prefix parameter typically represents the tag category or namespace.
  /// The id parameter is the unique identifier for the taggable entity.
  ///
  /// Example:
  /// ```dart
  /// backendToTaggable('user', '123') => Future<User?>
  /// ```
  final FutureOr<T?> Function(String prefix, String id) backendToTaggable;

  /// Function that converts a taggable object and its associated style into an
  /// [InlineSpan].
  ///
  /// Takes two parameters:
  /// * A generic type [T] representing the taggable object
  /// * A [TagStyle] object containing styling information
  ///
  /// Returns an [InlineSpan] that can be used in a [TextSpan] or similar
  /// widget.
  final InlineSpan Function(T, TagStyle) taggableToInlineSpan;

  /// A callback function that defines text style formatting rules.
  /// Used to build a `TextStyle` based on parsed tags and their attributes.
  final TextStyle? Function(BuildContext context, String prefix)
      textStyleBuilder;

  /// A list of [TagStyle] objects that define the styling rules for tags.
  ///
  /// This list contains the styling information that will be applied to text
  /// when specific tags are encountered during parsing. Each [TagStyle] in the
  /// list defines how a particular tag should be rendered.
  final List<TagStyle> tagStyles;

  /// The current build context.
  ///
  /// This context is used for accessing theme data, localization,
  /// and other widget tree dependencies.
  final BuildContext context;
}
