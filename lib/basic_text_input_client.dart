import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A basic text input client. An implementation of [DeltaTextInputClient] meant to
/// send/receive information from the framework to the platform's text input plugin
/// and vice-versa.
class BasicTextInputClient extends StatefulWidget {
  BasicTextInputClient({
    Key? key,
    required this.controller,
    required this.style,
    required this.focusNode,
  }) : super(key: key);

  final TextEditingController controller;
  final TextStyle style;
  final FocusNode focusNode;

  @override
  State<BasicTextInputClient> createState() => BasicTextInputClientState();
}

class BasicTextInputClientState extends State<BasicTextInputClient> implements DeltaTextInputClient {
  final GlobalKey _textKey = GlobalKey();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    widget.focusNode.addListener(_handleFocusChanged);
  }

  /// [DeltaTextInputClient] method implementations.
  @override
  void connectionClosed() {
    // TODO: implement connectionClosed
  }

  @override
  // TODO: implement currentAutofillScope
  AutofillScope? get currentAutofillScope => throw UnimplementedError();

  @override
  // TODO: implement currentTextEditingValue
  TextEditingValue? get currentTextEditingValue => throw UnimplementedError();

  @override
  void insertTextPlaceholder(Size size) {
    // TODO: implement insertTextPlaceholder
  }

  @override
  void performAction(TextInputAction action) {
    // TODO: implement performAction
  }

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {
    // TODO: implement performPrivateCommand
  }

  @override
  void removeTextPlaceholder() {
    // TODO: implement removeTextPlaceholder
  }

  @override
  void showAutocorrectionPromptRect(int start, int end) {
    // TODO: implement showAutocorrectionPromptRect
  }

  @override
  void showToolbar() {
    // TODO: implement showToolbar
  }

  @override
  void updateEditingValue(TextEditingValue value) {
    // TODO: implement updateEditingValue
  }

  @override
  void updateEditingValueWithDeltas(List<TextEditingDelta> textEditingDeltas) {
    // TODO: implement updateEditingValueWithDeltas
  }

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {
    // TODO: implement updateFloatingCursor
  }

  /// Field focus + keyboard request.
  bool get _hasFocus => widget.focusNode.hasFocus;

  void requestKeyboard() {
    if (_hasFocus) {
      /// TODO: open input connection.
    } else {
      widget.focusNode.requestFocus();
    }
  }

  void _handleFocusChanged() {
    /// TODO: open/close input connection.
    if (_hasFocus) {
      print('we now have focus');
    } else {
      print('we lost focus');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      child: Text.rich(
        widget.controller.buildTextSpan(
          context: context,
          style: widget.style,
          withComposing: false,
        ),
        key: _textKey,
      ),
    );
  }
}