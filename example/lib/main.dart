import 'dart:async';

import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:typeset_tag/typeset.dart';

void main() {
  runApp(const MyApp());
}

class Taggable {
  const Taggable({required this.id, required this.name, required this.icon});

  final String id;
  final String name;
  final IconData icon;
}

class User extends Taggable {
  const User(
      {required super.id, required super.name, super.icon = Icons.person});
}

class Topic extends Taggable {
  const Topic(
      {required super.id, required super.name, super.icon = Icons.topic});
}

/// A list of users to search from.
const users = <User>[
  User(id: 'aliceUniqueId', name: 'Alice'),
  User(id: 'otherAliceUniqueId', name: 'Alice', icon: Icons.person_outline),
  User(id: 'bobUniqueId', name: 'Bob'),
  User(id: 'charLieUniqueId', name: 'Charlie'),
  User(id: 'carolUniqueId', name: 'Carol'),
  User(id: 'hawkingUniqueId', name: 'Stephen Hawking'),
];

/// A list of topics to search from.
const topics = <Topic>[
  Topic(id: 'myDartId', name: 'Dart'),
  Topic(id: 'myFlutterId', name: 'Flutter'),
  Topic(id: 'myPubId', name: 'Pub'),
];

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      color: Color(0xFF2196F3),
      title: 'TypeSetTag Demo',
      home: TypeSetExample(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TypeSetExample extends StatefulWidget {
  const TypeSetExample({super.key});

  @override
  State<TypeSetExample> createState() => _TypeSetExampleState();
}

class _TypeSetExampleState extends State<TypeSetExample> {
  late final TypeSetEditingController _controller;
  OverlayEntry? _overlayEntry;
  final _formKey = GlobalKey<FormState>();
  final _layerLink = LayerLink();
  late FocusNode _focusNode;
  String backendFormat = '';

  @override
  void initState() {
    super.initState();
    _controller = TypeSetEditingController<Taggable>(
      text:
          'This is *bold*, _italic_, ~strikethrough~, `monospace`, and a §link|https://flutter.dev§',
      markerColor: Colors.grey.shade400,
      linkStyle: const TextStyle(color: Colors.blue),
      boldStyle: const TextStyle(fontWeight: FontWeight.bold),
      monospaceStyle: const TextStyle(fontFamily: 'Courier'),
      searchTaggables: searchTaggables,
      buildTaggables: buildTaggables,
      toFrontendConverter: (Taggable taggable) => taggable.name,
      toBackendConverter: (Taggable taggable) => taggable.id,
      toTaggableFromBackend: (prefix, id) => Future.value(Taggable(
        id: id,
        name: id,
        icon: prefix == '@' ? Icons.person : Icons.topic,
      )),
      tagStyles: const [TagStyle(prefix: '@'), TagStyle(prefix: '#')],
      textStyleBuilder: textStyleBuilder,
    );
    _focusNode = FocusNode();

    // Add a listener to update the [backendFormat] when the text changes.
    _controller.addListener(
        () => setState(() => backendFormat = _controller.textInBackendFormat));
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
    var tagParserParts = TagParserParts<Taggable>(
      toFrontendConverter: <Taggable>(taggable) => (taggable as dynamic).name,
      toBackendConverter: <Taggable>(taggable) => (taggable as dynamic).id,
      backendToTaggable: backendToTaggable,
      taggableToInlineSpan: <Taggable>(taggable, tagStyle) {
        return TextSpan(
          text: '${tagStyle.prefix}${taggable.name}',
          style: textStyleBuilder(context, tagStyle.prefix),
        );
      },
      textStyleBuilder: (context, prefix) {
        switch (prefix) {
          case '@':
            return TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              fontWeight: FontWeight.bold,
            );
          case '#':
            return TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            );
          default:
            return null;
        }
      },
      context: context,
      tagStyles: const [
        TagStyle(prefix: '@'),
        TagStyle(prefix: '#'),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('TypeSetTag Demo'),
      ),
      body: Center(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const Text(
                    'Usage',
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(
                    height: 12,
                  ),
                  const Text(
                    '''
Bold
→ Hello, *World!*

Italic
→ Hello, _World!_

Strikethrough
→ Hello, ~World!~

Underline
→ Hello, #World!#

Monospace
→ Hello, `World!`

Link
→ §google.com|https://google.com§
''',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),

                  const Divider(),
                  const Text(
                    'Samples',
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  const Divider(),

                  const SizedBox(
                    height: 12,
                  ),
                  const TypeSetTag(
                    '→ *TypeSetTag* _can_ #style# ~everything~ `you need` §with|https://rohanjsh.dev/§ _dynamic<18>_ _font<28>_ _size<25>_',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  const Divider(),
                  const Text(
                    'Supported Stylings',
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  const Divider(),

                  const SizedBox(
                    height: 12,
                  ),
                  const TypeSetTag(
                    'Bold:\n→ Hello *world*',
                    style: TextStyle(
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  const TypeSetTag(
                    'Italic:\n→ _Italic Text_ ',
                    style: TextStyle(
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  const TypeSetTag(
                    'Underline:\n→ #Underline Text#',
                    style: TextStyle(
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  const TypeSetTag(
                    'Strikethrough:\n→ ~Strikethrough Text~',
                    style: TextStyle(
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  const TypeSetTag(
                    'Monospace:\n→ `monospace text`',
                    style: TextStyle(
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),

                  //customized link textstyle and recognizer (tap recognizer)
                  TypeSetTag(
                    'Link:\n→ §google.com|https://google.com§',
                    style: const TextStyle(
                      fontSize: 24,
                    ),
                    linkRecognizerBuilder: (linkText, url) {
                      return TapGestureRecognizer()
                        ..onTap = () {
                          debugPrint('URL: $url and Text: $linkText');
                        };
                    },
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  const Divider(),
                  const Text(
                    'Chat - TypeSetTag Input',
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 12),
                  Form(
                    key: _formKey,
                    child: CompositedTransformTarget(
                      link: _layerLink,
                      child: TextField(
                        controller: _controller,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter text here...',
                        ),
                        onChanged: (val) {
                          setState(() {
                            debugPrint(val);
                          });
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
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Preview',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TypeSetTag<Taggable>(
                    _controller.text,
                    style: const TextStyle(fontSize: 16),
                    boldStyle: const TextStyle(fontWeight: FontWeight.bold),
                    monospaceStyle: const TextStyle(fontFamily: 'Courier'),
                    linkStyle: const TextStyle(
                      color: Colors.blue, 
                      decoration: TextDecoration.underline,
                    ),
                    tagParserParts: tagParserParts,
                    linkRecognizerBuilder: (linkText, url) {
                      return TapGestureRecognizer()
                        ..onTap = () {
                          debugPrint('URL: $url and Text: $linkText');
                        };
                    },
                  ),
                  const Divider(),
                  const SizedBox(height: 100),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<Taggable?> buildTaggables(
      FutureOr<Iterable<Taggable>> taggables) async {
    final availableTaggables = await taggables;

    // We use a [Completer] to return the selected taggable from the overlay.
    // This is because overlays do not return values directly.
    Completer<Taggable?> completer = Completer();

    // Remove the existing overlay if it exists.
    _overlayEntry?.remove();
    if (availableTaggables.isEmpty) {
      // If there are no taggables to show, we return null.
      _overlayEntry = null;
      completer.complete(null);
    } else {
      _overlayEntry = OverlayEntry(builder: (context) {
        // The following few lines are used to position the overlay above the
        // [TextField]. It moves along if the [TextField] moves.
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
                  // We show the list of taggables in a [ListView].
                  return ListTile(
                    leading: Icon(taggable.icon),
                    title: Text(taggable.name),
                    tileColor: Theme.of(context).colorScheme.primaryContainer,
                    onTap: () {
                      // When a taggable is selected, remove the overlay
                      _overlayEntry?.remove();
                      _overlayEntry = null;
                      // and complete the Completer with the selected taggable.
                      completer.complete(taggable);
                      // Focus the [TextField] to continue typing.
                      // Do this after completing the Completer to avoid
                      // interfering with the logic of adding the taggable.
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

  TextStyle? textStyleBuilder(BuildContext context, String prefix) {
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

  Future<Iterable<Taggable>> searchTaggables(
      String tagPrefix, String? tagName) async {
    if (tagName == null || tagName.isEmpty) {
      return [];
    }
    return switch (tagPrefix) {
      '@' => users
          .where((user) =>
              user.name.toLowerCase().startsWith(tagName.toLowerCase()))
          .toList(),
      '#' => topics
          .where((topic) =>
              topic.name.toLowerCase().startsWith(tagName.toLowerCase()))
          .toList(),
      'all:' => [...users, ...topics].where((taggable) =>
          taggable.name.toLowerCase().startsWith(tagName.toLowerCase())),
      _ => [],
    };
  }

  FutureOr<Taggable?> backendToTaggable(String prefix, String id) {
    return switch (prefix) {
      '@' => users.where((user) => user.id == id).firstOrNull,
      '#' => topics.where((topic) => topic.id == id).firstOrNull,
      'all:' => [...users, ...topics]
          .where((taggable) => taggable.id == id)
          .firstOrNull,
      _ => null,
    };
  }
}
