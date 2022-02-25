import 'package:deltaclientguide/basic_text_input_client.dart';
import 'package:flutter/material.dart';

/// A basic text field. Defines the appearance of a basic text input client.
class BasicTextField extends StatefulWidget {
  BasicTextField({required this.controller, required this.style});

  final TextEditingController controller;
  final TextStyle style;

  @override
  State<BasicTextField> createState() => _BasicTextFieldState();

}

class _BasicTextFieldState extends State<BasicTextField> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      width: 300,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue),
        borderRadius: const BorderRadius.all(Radius.circular(4.0)),
      ),
      child: BasicTextInputClient(
        controller: widget.controller,
        style: widget.style,
      ),
    );
  }
}