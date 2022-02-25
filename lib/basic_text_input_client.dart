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
    widget.controller.addListener(_didChangeTextEditingValue);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_didChangeTextEditingValue);
    super.dispose();
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
  TextEditingValue? get currentTextEditingValue => _value;

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
  void updateEditingValue(TextEditingValue value) { /* Not using */}

  @override
  void updateEditingValueWithDeltas(List<TextEditingDelta> textEditingDeltas) {
    TextEditingValue value = _value;

    for (final TextEditingDelta delta in textEditingDeltas) {
      value = delta.apply(value);
    }

    if (value == _value) {
      // This is possible, for example, when the numeric keyboard is input,
      // the engine will notify twice for the same value.
      // Track at https://github.com/flutter/flutter/issues/65811
      return;
    }

    _value = value;
  }

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {
    // TODO: implement updateFloatingCursor
  }

  /// Open/close [DeltaTextInputClient]
  TextInputConnection? _textInputConnection;
  bool get _hasInputConnection => _textInputConnection?.attached ?? false;
  TextEditingValue get _value => widget.controller.value;
  set _value(TextEditingValue value) {
    widget.controller.value = value;
  }

  void _openInputConnection() {
    // Open an input connection if one does not already exist, as well as set
    // its style. If one is active then show it.
    if (!_hasInputConnection) {
      final TextEditingValue localValue = _value;

      _textInputConnection = TextInput.attach(
        this,
        const TextInputConfiguration(
          enableDeltaModel: true,
          inputAction: TextInputAction.newline,
          inputType: TextInputType.multiline,
        ),
      );
      final TextStyle style = widget.style;
      _textInputConnection!
        ..setStyle(
          fontFamily: style.fontFamily,
          fontSize: style.fontSize,
          fontWeight: style.fontWeight,
          textDirection: _textDirection, // make this variable.
          textAlign: TextAlign.left, // make this variable.
        )
        ..setEditingState(localValue)
        ..show();
    } else {
      _textInputConnection!.show();
    }
  }

  void _closeInputConnectionIfNeeded() {
    // Close input connection if one is active.
    if (_hasInputConnection) {
      _textInputConnection!.close();
      _textInputConnection = null;
    }
  }

  void _openOrCloseInputConnectionIfNeeded() {
    // Open input connection on gaining focus.
    // Close input connection on focus loss.
    if (_hasFocus && widget.focusNode.consumeKeyboardToken()) {
      _openInputConnection();
    } else if (!_hasFocus) {
      _closeInputConnectionIfNeeded();
      widget.controller.clearComposing();
    }
  }

  /// Field focus + keyboard request.
  bool get _hasFocus => widget.focusNode.hasFocus;

  void requestKeyboard() {
    if (_hasFocus) {
      _openInputConnection();
    } else {
      widget.focusNode.requestFocus();
    }
  }

  void _handleFocusChanged() {
    // Open or close input connection depending on focus.
    _openOrCloseInputConnectionIfNeeded();
  }

  /// Misc.
  TextDirection get _textDirection => Directionality.of(context);

  void _didChangeTextEditingValue() {
    setState(() {});
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