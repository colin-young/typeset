import 'package:flutter/material.dart';

/// A widget that provides tagging functionality.
///
/// The [Taggable] class serves as a base class for implementing
/// tagging features in widgets. It allows for the creation of
/// interactive elements that can be tagged or labeled.
///
/// This class can be used to build features like:
/// * User mentions in text
/// * Hashtag implementations
/// * Social media style tagging
///
class Taggable {
  /// {@template taggable}
  /// Creates a [Taggable] widget.
  ///
  /// The [id] parameter is a unique identifier for the taggable item.
  /// The [name] parameter is the display name of the taggable item.
  /// The [icon] parameter is the icon to display alongside the taggable item.
  /// 
  /// {@endtemplate}
  const Taggable({required this.id, required this.name, required this.icon});

  /// A unique identifier for the taggable item.
  final String id;

  /// The display name of the taggable widget.
  final String name;

  /// The icon to display in the tag.
  final IconData icon;
}
