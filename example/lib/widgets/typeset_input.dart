import 'dart:async';
import 'package:flutter/material.dart';
import 'package:typeset_tag/typeset.dart';
import '../main.dart';

/// A reusable input widget that shows suggestions when typing @ or #
class TypeSetInput extends StatefulWidget {
  const TypeSetInput({
    super.key,
    required this.users,
    required this.topics,
    this.text = '',
    this.decoration = const InputDecoration(
      border: OutlineInputBorder(),
      hintText: 'Enter text here...',
    ),
    this.maxLines = 3,
    this.onChanged,
  });

  final Future<List<Taggable>> users;
  final Future<List<Taggable>> topics;
  final String text;
  final InputDecoration decoration;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  State<TypeSetInput> createState() => _TypeSetInputState();
}

class _TypeSetInputState extends State<TypeSetInput> {
  late final TypeSetEditingController<Taggable> _controller;
  OverlayEntry? _overlayEntry;
  final _formKey = GlobalKey<FormState>();
  final _layerLink = LayerLink();
  late FocusNode _focusNode;

  TextStyle? _textStyleBuilder(BuildContext context, String prefix) {
    return switch (prefix) {
      '@' => TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          fontWeight: FontWeight.bold,
        ),
      '#' => TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      '*' => const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      '_' => const TextStyle(
          fontStyle: FontStyle.italic,
        ),
      '~' => const TextStyle(
          decoration: TextDecoration.lineThrough,
        ),
      '`' => const TextStyle(
          fontFamily: 'Courier',
        ),
      '§' => const TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
      _ => null,
    };
  }

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    // Initialize the controller with all necessary configuration
    _controller = TypeSetEditingController<Taggable>(
      text: widget.text,
      searchTaggables: _searchTaggables,
      buildTaggables: _buildTaggablesList,
      toFrontendConverter: <T>(T taggable) => (taggable as Taggable).name,
      toBackendConverter: <T>(T taggable) => (taggable as Taggable).id,
      toTaggableFromBackend: (prefix, id) async {
        final taggable = switch (prefix) {
          '@' =>
            (await widget.users).where((user) => user.id == id).firstOrNull,
          '#' =>
            (await widget.topics).where((topic) => topic.id == id).firstOrNull,
          'all:' => [...await widget.users, ...await widget.topics]
              .where((taggable) => taggable.id == id)
              .firstOrNull,
          _ => null,
        };
        if (taggable == null) throw Exception('Taggable not found');
        return taggable;
      },
      tagStyles: const [TagStyle(prefix: '@'), TagStyle(prefix: '#')],
      textStyleBuilder: _textStyleBuilder,
      markerColor: Colors.grey.shade400,
      linkStyle: const TextStyle(color: Colors.blue),
      boldStyle: const TextStyle(fontWeight: FontWeight.bold),
      monospaceStyle: const TextStyle(fontFamily: 'Courier'),
    );

    // Add listener for text changes
    _controller.addListener(() {
      widget.onChanged?.call(_controller.text);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: TextField(
          controller: _controller,
          maxLines: widget.maxLines,
          decoration: widget.decoration,
          focusNode: _focusNode,
          onChanged: (val) {
            setState(() {});
          },
          contextMenuBuilder: (context, editableTextState) {
            return AdaptiveTextSelectionToolbar.buttonItems(
              anchors: editableTextState.contextMenuAnchors,
              buttonItems: [
                ...getTypesetContextMenus(
                  editableTextState: editableTextState,
                ),
                ...editableTextState.contextMenuButtonItems,
              ],
            );
          },
        ),
      ),
    );
  }

  Future<Iterable<Taggable>> _searchTaggables(
      String tagPrefix, String? tagName) async {
    if (tagName == null || tagName.isEmpty) {
      return [];
    }
    final lowercaseTagName = tagName.toLowerCase();
    return switch (tagPrefix) {
      '@' => (await widget.users)
          .where((user) => user.name.toLowerCase().startsWith(lowercaseTagName))
          .toList(),
      '#' => (await widget.topics)
          .where(
              (topic) => topic.name.toLowerCase().startsWith(lowercaseTagName))
          .toList(),
      'all:' => [...await widget.users, ...await widget.topics].where(
          (taggable) =>
              taggable.name.toLowerCase().startsWith(lowercaseTagName)),
      _ => [],
    };
  }

  Future<Taggable?> _buildTaggablesList(
      FutureOr<Iterable<Taggable>> taggables) async {
    final availableTaggables = await taggables;
    final completer = Completer<Taggable?>();

    _overlayEntry?.remove();
    if (availableTaggables.isEmpty) {
      _overlayEntry = null;
      completer.complete(null);
    } else {
      _overlayEntry = OverlayEntry(builder: (context) {
        final renderBox =
            _formKey.currentContext!.findRenderObject() as RenderBox;
        return Positioned(
          width: renderBox.size.width,
          bottom: renderBox.size.height + 8,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            followerAnchor: Alignment.bottomLeft,
            child: Material(
              child: ListView(
                shrinkWrap: true,
                children: availableTaggables.map((taggable) {
                  return ListTile(
                    leading: Icon(taggable.icon),
                    title: Text(taggable.name),
                    tileColor: Theme.of(context).colorScheme.primaryContainer,
                    onTap: () {
                      _overlayEntry?.remove();
                      _overlayEntry = null;
                      completer.complete(taggable);
                      _focusNode.requestFocus();
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        );
      });
      if (mounted) {
        Overlay.of(context).insert(_overlayEntry!);
      }
    }
    return completer.future;
  }
}
