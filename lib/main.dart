import 'package:basic_text_input_client_sample/replacement_text_editing_controller.dart';
import 'package:flutter/material.dart';

import 'basic_text_field.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Basic TextField Demo'),
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
  final FocusNode _focusNode = FocusNode();
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
          return WidgetSpan(
            child: Image.asset('assets/flutter_f.png'),
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: BasicTextField(
          controller: _controller,
          maxLines: null,
          textAlign: TextAlign.left,
          focusNode: _focusNode,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 26.0,
          ),
        ),
      ),
    );
  }
}
