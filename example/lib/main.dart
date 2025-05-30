import 'dart:async';

import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:typeset_tag/typeset.dart';
import 'widgets/typeset_input.dart';

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
Future<List<User>> getUsers() async => const <User>[
    User(id: 'aliceUniqueId', name: 'Alice'),
    User(id: 'otherAliceUniqueId', name: 'Alice', icon: Icons.person_outline), 
    User(id: 'bobUniqueId', name: 'Bob'),
    User(id: 'charLieUniqueId', name: 'Charlie'),
    User(id: 'carolUniqueId', name: 'Carol'),
    User(id: 'hawkingUniqueId', name: 'Stephen Hawking'),
  ];

/// A list of topics to search from.
Future<List<Topic>> getTopics() async => const <Topic>[
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
  late final TypeSetEditingController<Taggable> _controller;
  String backendFormat = '';
  String displayText = '';

  @override
  void initState() {
    super.initState();
    _controller = TypeSetEditingController<Taggable>(
      text: 'This is *bold*, _italic_, ~strikethrough~, `monospace`, and a §link|https://flutter.dev§',
      markerColor: Colors.grey.shade400,
      linkStyle: const TextStyle(color: Colors.blue),
      boldStyle: const TextStyle(fontWeight: FontWeight.bold),
      monospaceStyle: const TextStyle(fontFamily: 'Courier'),
      searchTaggables: searchTaggables,
      buildTaggables: (taggables) async => null, // Will be handled by TypeSetInput
      toFrontendConverter: <T>(T taggable) => (taggable as Taggable).name,
      toBackendConverter: <T>(T taggable) => (taggable as Taggable).id,
      toTaggableFromBackend: (prefix, id) => Future.value(Taggable(
        id: id,
        name: id,
        icon: prefix == '@' ? Icons.person : Icons.topic,
      )),
      tagStyles: const [TagStyle(prefix: '@'), TagStyle(prefix: '#')],
      textStyleBuilder: textStyleBuilder,
    );

    // Add a listener to update the [backendFormat] when the text changes.
    _controller.addListener(
        () => setState(() => backendFormat = _controller.textInBackendFormat));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var tagParserParts = TagParserParts<Taggable>(
      toFrontendConverter: <T>(T taggable) => (taggable as Taggable).name,
      toBackendConverter: <T>(T taggable) => (taggable as Taggable).id,
      backendToTaggable: backendToTaggable,
      taggableToInlineSpan: <T>(taggable, tagStyle) {
        final t = taggable as Taggable;
        return TextSpan(
          text: '${tagStyle.prefix}${t.name}',
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
                  TypeSetInput(
                    users: getUsers(),
                    topics: getTopics(),
                    text: _controller.text,
                    onChanged: (value) {
                      setState(() {
                        backendFormat = _controller.textInBackendFormat;
                        displayText = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Preview',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TypeSetTag<Taggable>(
                    // _controller.text,
                    displayText,
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

  Future<Iterable<Taggable>> searchTaggables(String tagPrefix, String? tagName) async {
    // This function is still needed for the TypeSetEditingController
    if (tagName == null || tagName.isEmpty) {
      return [];
    }
    return switch (tagPrefix) {
      '@' => (await getUsers())
          .where((user) =>
              user.name.toLowerCase().startsWith(tagName.toLowerCase()))
          .toList(),
      '#' => (await getTopics())
          .where((topic) =>
              topic.name.toLowerCase().startsWith(tagName.toLowerCase()))
          .toList(),
      'all:' => [...(await getUsers()), ...(await getTopics())].where((taggable) =>
          taggable.name.toLowerCase().startsWith(tagName.toLowerCase())),
      _ => [],
    };
  }

  FutureOr<Taggable?> backendToTaggable(String prefix, String id) async {
    return switch (prefix) {
      '@' => (await getUsers()).where((user) => user.id == id).firstOrNull,
      '#' => (await getTopics()).where((topic) => topic.id == id).firstOrNull,
      'all:' => [...(await getUsers()), ...(await getTopics())]
          .where((taggable) => taggable.id == id)
          .firstOrNull,
      _ => null,
    };
  }
}
