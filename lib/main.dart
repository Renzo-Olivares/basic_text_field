import 'package:flutter/material.dart';

import 'basic_text_field.dart';
import 'replacements.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Delta Text Field Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Delta Text Field Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  final ReplacementTextEditingController _replacementTextEditingController =
  ReplacementTextEditingController(
    text: 'The quick brown fox jumps over the lazy \uffff dog.',
    replacements: <TextEditingInlineSpanReplacement>[
      TextEditingInlineSpanReplacement(
        const TextRange(start: 0, end: 3),
            (String value, TextRange range) {
          return TextSpan(
            text: value,
            style: const TextStyle(color: Colors.blue),
          );
        },
      ),
      TextEditingInlineSpanReplacement(
        const TextRange(start: 4, end: 9),
            (String value, TextRange range) {
          return TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          );
        },
      ),
      TextEditingInlineSpanReplacement(
        const TextRange(start: 10, end: 15),
            (String value, TextRange range) {
          return TextSpan(
            text: value,
            style: const TextStyle(color: Colors.green),
          );
        },
      ),
      TextEditingInlineSpanReplacement(
        const TextRange(start: 16, end: 19),
            (String value, TextRange range) {
          return TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.yellow,
            ),
          );
        },
      ),
      TextEditingInlineSpanReplacement(
        const TextRange(start: 20, end: 25),
            (String value, TextRange range) {
          return TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.pink,
              fontSize: 60.0,
            ),
          );
        },
      ),
      TextEditingInlineSpanReplacement(
        const TextRange(start: 26, end: 30),
            (String value, TextRange range) {
          return TextSpan(
            text: value,
            style: const TextStyle(color: Colors.indigo),
          );
        },
      ),
      TextEditingInlineSpanReplacement(
        const TextRange(start: 31, end: 34),
            (String value, TextRange range) {
          return TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.purple,
              decoration: TextDecoration.underline,
            ),
          );
        },
      ),
      TextEditingInlineSpanReplacement(
        const TextRange(start: 35, end: 39),
            (String value, TextRange range) {
          return TextSpan(
            text: value,
            style: const TextStyle(color: Colors.teal),
          );
        },
      ),
      TextEditingInlineSpanReplacement(
        const TextRange(start: 40, end: 41),
            (String value, TextRange range) {
          return const WidgetSpan(
            child: FlutterLogo(),
          );
        },
      ),
      TextEditingInlineSpanReplacement(
        const TextRange(start: 42, end: 45),
            (String value, TextRange range) {
          return TextSpan(
            text: value,
            style: const TextStyle(color: Colors.lime),
          );
        },
      ),
    ],
  );
  final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: BasicTextField(
          controller: _replacementTextEditingController,
          style: const TextStyle(color: Colors.black),
          focusNode: _focusNode,
        ),
      ),
    );
  }
}
