import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'basic_text_field.dart';

typedef TextEditingDeltaHistoryUpdateCallback = void Function(List<TextEditingDelta> textEditingDeltas);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
  final TextEditingController _replacementTextEditingController = TextEditingController(
    text: 'The quick brown fox jumps over the lazy dog.',
  );
  final FocusNode _focusNode = FocusNode();
  final List<TextEditingDelta> _textEditingDeltaHistory = [];

  void _updateTextEditingDeltaHistory(List<TextEditingDelta> textEditingDeltas) {
    for (final TextEditingDelta delta in textEditingDeltas) {
      _textEditingDeltaHistory.add(delta);
    }

    setState(() {});
  }

  List<Widget> _buildTextEditingDeltaHistoryViews(List<TextEditingDelta> textEditingDeltas) {
    List<Widget> _textEditingDeltaViews = [];

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

      _textEditingDeltaViews.add(deltaView);
    }

    return _textEditingDeltaViews.reversed.toList();
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
          Expanded(
              child: Tooltip(
                message: 'The type of text input that is occurring.'
                    ' Check out the documentation for TextEditingDelta for more information.',
                child: _buildTextEditingDeltaViewHeading('Delta Type'),
              ),
          ),
          Expanded(
              child: Tooltip(
                message: 'The text that is being inserted or deleted',
                child: _buildTextEditingDeltaViewHeading('Delta Text'),
              ),
          ),
          Expanded(
              child: Tooltip(
                message: 'The offset in the text where the text input is occurring.',
                child: _buildTextEditingDeltaViewHeading('Delta Offset'),
              ),
          ),
          Expanded(
              child: Tooltip(
                message: 'The new text selection range after the text input has occurred.',
                child: _buildTextEditingDeltaViewHeading('New Selection'),
              ),
          ),
          Expanded(
              child: Tooltip(
                message: 'The new composing range after the text input has occurred.',
                child: _buildTextEditingDeltaViewHeading('New Composing'),
              ),
          ),
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
            const SizedBox(height: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35.0),
                child: TextEditingDeltaHistoryManager(
                  history: _textEditingDeltaHistory,
                  updateHistoryOnInput: _updateTextEditingDeltaHistory,
                  child: BasicTextField(
                    controller: _replacementTextEditingController,
                    style: const TextStyle(fontSize: 18.0, color: Colors.black),
                    focusNode: _focusNode,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  _buildTextEditingDeltaViewHeader(),
                  Expanded(
                    child: TextEditingDeltaHistoryManager(
                      history: _textEditingDeltaHistory,
                      updateHistoryOnInput: _updateTextEditingDeltaHistory,
                      child: Builder(
                        builder: (BuildContext innerContext) {
                          final TextEditingDeltaHistoryManager manager = TextEditingDeltaHistoryManager.of(innerContext);
                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 35.0),
                            itemBuilder: (BuildContext context, int index) {
                              return _buildTextEditingDeltaHistoryViews(manager.textEditingDeltaHistory)[index];
                            },
                            itemCount: manager.textEditingDeltaHistory.length,
                            separatorBuilder: (BuildContext context, int index) {
                              return const SizedBox(height: 2.0);
                            },
                          );
                        }
                      ),
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
        rowColor = Colors.greenAccent.shade100;
        break;
      case 'Deletion':
        rowColor = Colors.redAccent.shade100;
        break;
      case 'Replacement':
        rowColor = Colors.yellowAccent.shade100;
        break;
      case 'NonTextUpdate':
        rowColor = Colors.blueAccent.shade100;
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

class TextEditingDeltaHistoryManager extends InheritedWidget {
  const TextEditingDeltaHistoryManager({
    Key? key,
    required Widget child,
    required List<TextEditingDelta> history,
    required TextEditingDeltaHistoryUpdateCallback updateHistoryOnInput,
  })
      : _textEditingDeltaHistory = history,
        _updateTextEditingDeltaHistoryOnInput = updateHistoryOnInput,
        super(key: key, child: child);

  static TextEditingDeltaHistoryManager of(BuildContext context) {
    final TextEditingDeltaHistoryManager? result = context.dependOnInheritedWidgetOfExactType<TextEditingDeltaHistoryManager>();
    assert(result != null, 'No ToggleButtonsStateManager found in context');
    return result!;
  }

  final List<TextEditingDelta> _textEditingDeltaHistory;
  final TextEditingDeltaHistoryUpdateCallback _updateTextEditingDeltaHistoryOnInput;

  List<TextEditingDelta> get textEditingDeltaHistory => _textEditingDeltaHistory;
  TextEditingDeltaHistoryUpdateCallback get updateTextEditingDeltaHistoryOnInput => _updateTextEditingDeltaHistoryOnInput;

  @override
  bool updateShouldNotify(TextEditingDeltaHistoryManager oldWidget) {
    return textEditingDeltaHistory != oldWidget.textEditingDeltaHistory;
  }
}
