import 'package:flutter/material.dart';

import 'basic_text_input_client.dart';

/// A basic text field. Defines the appearance of a basic text input client.
class BasicTextField extends StatefulWidget {
  BasicTextField({
    required this.controller,
    required this.style,
    required this.focusNode
  });

  final TextEditingController controller;
  final TextStyle style;
  final FocusNode focusNode;

  @override
  State<BasicTextField> createState() => _BasicTextFieldState();

}

class _BasicTextFieldState extends State<BasicTextField> {
  final GlobalKey<BasicTextInputClientState> textInputClientKey = GlobalKey<BasicTextInputClientState>();
  BasicTextInputClientState? get _textInputClient => textInputClientKey.currentState;

  @override
  Widget build(BuildContext context) {
    return FocusTrapArea(
      focusNode: widget.focusNode,
      child: GestureDetector(
        onTap: () {
          _textInputClient!.requestKeyboard();
        },
        child: Container(
          height: 300,
          width: 300,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue),
            borderRadius: const BorderRadius.all(Radius.circular(4.0)),
          ),
          child: BasicTextInputClient(
            key: textInputClientKey,
            controller: widget.controller,
            style: widget.style,
            focusNode: widget.focusNode,
          ),
        ),
      ),
    );
  }
}