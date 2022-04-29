import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        useMaterial3: true,
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
    text: 'The quick brown fox jumps over the lazy dog.',
  );
  final FocusNode _focusNode = FocusNode();
  final List<bool> _isSelected = [false, false, false];
  final List<Widget> _textEditingDeltaHistory = [];

  void _updateTextEditingDeltaHistory(List<TextEditingDelta> textEditingDeltas) {
    for (final TextEditingDelta delta in textEditingDeltas) {
      final TextEditingDeltaView deltaView;

      if (delta is TextEditingDeltaInsertion) {
        deltaView = TextEditingDeltaView(
          deltaType: delta.runtimeType.toString().replaceAll('TextEditingDelta', ''),
          deltaText: delta.textInserted,
          deltaRange: TextRange.collapsed(delta.insertionOffset),
          newSelection: delta.selection,
          newComposing: delta.composing,
        );
      } else if (delta is TextEditingDeltaDeletion) {
        deltaView = TextEditingDeltaView(
          deltaType: delta.runtimeType.toString().replaceAll('TextEditingDelta', ''),
          deltaText: delta.textDeleted,
          deltaRange: delta.deletedRange,
          newSelection: delta.selection,
          newComposing: delta.composing,
        );
      } else if (delta is TextEditingDeltaReplacement) {
        deltaView = TextEditingDeltaView(
          deltaType: delta.runtimeType.toString().replaceAll('TextEditingDelta', ''),
          deltaText: delta.replacementText,
          deltaRange: delta.replacedRange,
          newSelection: delta.selection,
          newComposing: delta.composing,
        );
      } else if (delta is TextEditingDeltaNonTextUpdate) {
        deltaView = TextEditingDeltaView(
          deltaType: delta.runtimeType.toString().replaceAll('TextEditingDelta', ''),
          deltaText: '',
          deltaRange: TextRange.empty,
          newSelection: delta.selection,
          newComposing: delta.composing,
        );
      } else {
        deltaView = const TextEditingDeltaView(
          deltaType: 'Error',
          deltaText: 'Error',
          deltaRange: TextRange.empty,
          newSelection: TextRange.empty,
          newComposing: TextRange.empty,
        );
      }

      _textEditingDeltaHistory.add(deltaView);
    }

    setState(() {});
  }

  void _updateToggleButtonStateOnSelectionChanged(TextSelection selection) {
    // When the selection changes we want to check the replacements at the new
    // selection. Enable/disable toggle buttons based on the replacements found
    // at the new selection.
    final List<TextStyle> replacementStyles = _replacementTextEditingController.getReplacementsAtSelection(selection);
    final List<bool> hasChanged = [false, false, false];

    print('updating toggle buttons on selection changed');
    print(replacementStyles.length);
    print('toggle buttons before $_isSelected');

    if (replacementStyles.isEmpty) {
      _isSelected.fillRange(0, _isSelected.length, false);
    }

    for (final TextStyle style in replacementStyles) {
      if (style.fontWeight != null && !hasChanged[0]) {
        _isSelected[0] = true;
        hasChanged[0] = true;
      }

      if (style.fontStyle != null && !hasChanged[1]) {
        _isSelected[1] = true;
        hasChanged[1] = true;
      }

      if (style.decoration != null && !hasChanged[2]) {
        _isSelected[2] = true;
        hasChanged[2] = true;
      }
    }

    for (final TextStyle style in replacementStyles) {
      if (style.fontWeight == null && !hasChanged[0]) {
        _isSelected[0] = false;
        hasChanged[0] = true;
      }

      if (style.fontStyle == null && !hasChanged[1]) {
        _isSelected[1] = false;
        hasChanged[1] = true;
      }

      if (style.decoration == null && !hasChanged[2]) {
        _isSelected[2] = false;
        hasChanged[2] = true;
      }
    }

    print('toggle buttonz updated $_isSelected');

    setState(() {});
  }

  Widget _buildTextEditingDeltaViewHeading(String text) {
    return Text(
      text,
      style: const TextStyle(
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
      ),
    );
  }

  Widget _buildTextEditingDeltaViewHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35.0, vertical: 10.0),
      child: Row(
        children: [
          Expanded(child: _buildTextEditingDeltaViewHeading('Delta Type')),
          Expanded(child: _buildTextEditingDeltaViewHeading('Delta Text')),
          Expanded(child: _buildTextEditingDeltaViewHeading('Delta Offset')),
          Expanded(child: _buildTextEditingDeltaViewHeading('New Selection')),
          Expanded(child: _buildTextEditingDeltaViewHeading('New Composing')),
        ],
      ),
    );
  }

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
                ToggleButtons(
                  borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                  children: const [
                    Icon(Icons.format_bold),
                    Icon(Icons.format_italic),
                    Icon(Icons.format_underline),
                  ],
                  isSelected: _isSelected,
                  onPressed: (int index) {
                    Map<int, TextStyle> attributeMap = const <int, TextStyle>{
                      0 : TextStyle(fontWeight: FontWeight.bold),
                      1 : TextStyle(fontStyle: FontStyle.italic),
                      2 : TextStyle(decoration: TextDecoration.underline),
                    };

                    final TextRange replacementRange = TextRange(
                      start: _replacementTextEditingController.selection.start,
                      end: _replacementTextEditingController.selection.end,
                    );

                    _isSelected[index] = !_isSelected[index];
                    if (_isSelected[index]) {
                      print('applying replacement at $replacementRange style ${attributeMap[index]}');
                      _replacementTextEditingController.applyReplacement(
                        TextEditingInlineSpanReplacement(
                          replacementRange,
                              (string, range) => TextSpan(text: string, style: attributeMap[index]),
                          true,
                        ),
                      );
                      setState(() {});
                    } else {
                      _replacementTextEditingController.disableExpand(attributeMap[index]!);
                      _replacementTextEditingController.removeReplacementsAtRange(replacementRange, attributeMap[index]);
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35.0),
                child: BasicTextField(
                  controller: _replacementTextEditingController,
                  style: const TextStyle(color: Colors.black),
                  focusNode: _focusNode,
                  updateToggleButtonStateOnSelectionChanged: _updateToggleButtonStateOnSelectionChanged,
                  updateTextEditingDeltaHistory: _updateTextEditingDeltaHistory,
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  _buildTextEditingDeltaViewHeader(),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 35.0),
                      itemBuilder: (BuildContext context, int index) {
                        return _textEditingDeltaHistory.reversed.toList()[index];
                      },
                      itemCount: _textEditingDeltaHistory.length,
                      separatorBuilder: (BuildContext context, int index) {
                        return const Divider(height: 5.0);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TextEditingDeltaView extends StatelessWidget {
  const TextEditingDeltaView({
    Key? key,
    required this.deltaType,
    required this.deltaText,
    required this.deltaRange,
    required this.newSelection,
    required this.newComposing
  }) : super(key: key);

  final String deltaType;
  final String deltaText;
  final TextRange deltaRange;
  final TextRange newSelection;
  final TextRange newComposing;

  @override
  Widget build(BuildContext context) {
    late final Color rowColor;

    switch (deltaType) {
      case 'Insertion':
        rowColor = Colors.greenAccent;
        break;
      case 'Deletion':
        rowColor = Colors.redAccent;
        break;
      case 'Replacement':
        rowColor = Colors.yellowAccent;
        break;
      case 'NonTextUpdate':
        rowColor = Colors.blueAccent;
        break;
      default:
        rowColor = Colors.white;
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(4.0)),
        color: rowColor,
      ),
      child: Row(
        children: [
          Expanded(child: Text(deltaType)),
          Expanded(child: Text(deltaText)),
          Expanded(child: Text('(${deltaRange.start}, ${deltaRange.end})')),
          Expanded(child: Text('(${newSelection.start}, ${newSelection.end})')),
          Expanded(child: Text('(${newComposing.start}, ${newComposing.end})')),
        ],
      ),
    );
  }
}
