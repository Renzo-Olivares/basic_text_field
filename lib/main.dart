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
      home: const MyHomePage(title: 'Flutter Delta Text Field Demo'),
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
  final ReplacementTextEditingController _replacementTextEditingController =
  ReplacementTextEditingController(
    text: 'The quick brown fox jumps over the lazy \uffff dog.',
    replacements: <TextEditingInlineSpanReplacement>[
      TextEditingInlineSpanReplacement(
        const TextRange(start: 40, end: 41),
            (String value, TextRange range) {
          return const WidgetSpan(
            child: FlutterLogo(),
          );
        },
      ),
    ],
  );
  final FocusNode _focusNode = FocusNode();
  final List<bool> isSelected = [false];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          children: [
            ButtonBar(
              alignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: (){
                    _replacementTextEditingController.applyReplacement(
                        TextEditingInlineSpanReplacement(
                            TextRange(
                                start: _replacementTextEditingController.selection.start,
                                end: _replacementTextEditingController.selection.end,
                            ),
                                (string, range) => TextSpan(text: string, style: const TextStyle(fontWeight: FontWeight.bold))
                        ),
                    );
                    setState(() {});
                    },
                  child: const Icon(Icons.format_bold),
                ),
                OutlinedButton(
                  onPressed: (){
                    _replacementTextEditingController.applyReplacement(
                      TextEditingInlineSpanReplacement(
                          TextRange(
                            start: _replacementTextEditingController.selection.start,
                            end: _replacementTextEditingController.selection.end,
                          ),
                              (string, range) => TextSpan(text: string, style: const TextStyle(fontStyle: FontStyle.italic))
                      ),
                    );
                    setState(() {});
                  },
                  child: const Icon(Icons.format_italic),
                ),
                OutlinedButton(
                  onPressed: (){
                    _replacementTextEditingController.applyReplacement(
                      TextEditingInlineSpanReplacement(
                          TextRange(
                            start: _replacementTextEditingController.selection.start,
                            end: _replacementTextEditingController.selection.end,
                          ),
                              (string, range) => TextSpan(text: string, style: const TextStyle(decoration: TextDecoration.underline))
                      ),
                    );
                    setState(() {});
                  },
                  child: const Icon(Icons.format_underline),
                ),
              ],
            ),
            BasicTextField(
              controller: _replacementTextEditingController,
              style: const TextStyle(color: Colors.black),
              focusNode: _focusNode,
            ),
          ],
        ),
      ),
    );
  }
}
