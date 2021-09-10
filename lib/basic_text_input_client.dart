import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class BasicTextInputClient extends StatefulWidget {
  const BasicTextInputClient({
    Key? key,
    TextInputType? keyboardType,
    required this.controller,
    required this.style,
    required this.focusNode,
    required this.textAlign,
    required this.updateTextOverlay,
    this.textDirection,
    this.textInputAction,
    this.maxLines = 1,
  })  : keyboardType = keyboardType ??
            (maxLines == 1 ? TextInputType.text : TextInputType.multiline),
        super(key: key);

  final TextEditingController controller;

  final TextStyle style;

  final FocusNode focusNode;

  final TextAlign textAlign;

  final TextDirection? textDirection;

  final TextInputAction? textInputAction;

  final TextInputType? keyboardType;

  final int? maxLines;

  final void Function() updateTextOverlay;

  @override
  _BasicTextInputClientState createState() => _BasicTextInputClientState();
}

class _BasicTextInputClientState extends State<BasicTextInputClient>
    implements TextInputClient {
  final GlobalKey _textKey = GlobalKey();
  TextEditingValue get _value => widget.controller.value;
  set _value(TextEditingValue value) {
    widget.controller.value = value;
  }

  TextSelection get _selection => widget.controller.selection;
  set _selection(TextSelection selection) {
    widget.controller.selection = selection;
  }

  FocusAttachment? _focusAttachment;
  bool get _hasFocus => widget.focusNode.hasFocus;
  bool get _isMultiline => widget.maxLines != 1;

  TextInputConnection? _textInputConnection;
  TextEditingValue? _lastKnownRemoteTextEditingValue;
  bool get _hasInputConnection => _textInputConnection?.attached ?? false;

  RenderParagraph get _renderParagraph =>
      _textKey.currentContext?.findRenderObject() as RenderParagraph;
  Rect _caretRect = Rect.zero;

  @override
  void initState() {
    super.initState();
    _focusAttachment = widget.focusNode.attach(context);
    widget.focusNode.addListener(_handleFocusChanged);
    widget.controller.addListener(_didChangeTextEditingValue);
    _updateTextOverlay();
  }

  @override
  void didUpdateWidget(covariant BasicTextInputClient oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      _focusAttachment?.detach();
      _focusAttachment = widget.focusNode.attach(context);
      widget.focusNode.addListener(_handleFocusChanged);
    }

    if (_hasFocus) {
      _openInputConnection();
    }

    _updateTextOverlay();
  }

  void _updateTextOverlay() {
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      setState(() {
        _updateCaret();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    _focusAttachment!.reparent();

    return FocusTrapArea(
      focusNode: widget.focusNode,
      child: GestureDetector(
        onTap: _requestKeyboard,
        onTapUp: _tapUp,
        child: Container(
          width: 400,
          height: 400,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blueAccent),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              Text.rich(
                widget.controller
                    .buildTextSpan(context: context, withComposing: true),
                key: _textKey,
                style: widget.style,
                textDirection: widget.textDirection,
                textAlign: widget.textAlign,
                maxLines: widget.maxLines,
              ),
              CustomPaint(
                painter: _CustomTextOverlayPainter(
                  color: Colors.blueAccent,
                  rects: <Rect>[_caretRect],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_didChangeTextEditingValue);
    _closeInputConnectionIfNeeded();
    assert(!_hasInputConnection);
    _focusAttachment!.detach();
    widget.focusNode.removeListener(_handleFocusChanged);
    super.dispose();
  }

  void _tapUp(TapUpDetails upDetails) {
    // Update selection on tap.
    _selection = TextSelection.collapsed(
      offset:
          _renderParagraph.getPositionForOffset(upDetails.localPosition).offset,
    );
  }

  void _updateCaret() {
    if (_selection.extentOffset < 0) {
      return;
    }

    final Offset caretOffset =
        _renderParagraph.getOffsetForCaret(_selection.extent, Rect.zero);
    final double? caretHeight =
        _renderParagraph.getFullHeightForCaret(_selection.extent);

    if (caretOffset.dx == 0 && caretOffset.dy == 0) {
      _caretRect = Rect.zero;
    }

    if (caretHeight != null) {
      _caretRect =
          Rect.fromLTWH(caretOffset.dx - 1, caretOffset.dy, 2, caretHeight);
    }
  }

  /// Express interest in interacting with the keyboard.
  ///
  /// If this control is already attached to the keyboard, this function will
  /// request that the keyboard become visible. Otherwise, this function will
  /// ask the focus system that it become focused. If successful in acquiring
  /// focus, the control will then attach to the keyboard and request that the
  /// keyboard become visible.
  void _requestKeyboard() {
    if (_hasFocus) {
      _openInputConnection();
    } else {
      widget.focusNode
          .requestFocus(); // This eventually calls _openInputConnection also, see _handleFocusChanged.
    }
  }

  void _updateRemoteEditingValueIfNeeded() {
    if (!_hasInputConnection) return;
    final TextEditingValue localValue = _value;
    if (localValue == _lastKnownRemoteTextEditingValue) return;
    _textInputConnection!.setEditingState(localValue);
    _lastKnownRemoteTextEditingValue = localValue;
  }

  void _didChangeTextEditingValue() {
    // Handler for when the text editing value has been updated.
    //
    // We will first check if we should update the remote value and then rebuild.
    // After our rebuild we should trigger an update to the text overlay.
    //
    // We update this after the text has been fully laid out and not before because
    // we will not have the most up to date renderParagraph before that time. We
    // need the most up to date renderParagraph to properly calculate the caret
    // position.
    _updateRemoteEditingValueIfNeeded();
    setState(() {/* We use widget.controller.value in build(). */});
    widget.updateTextOverlay();
  }

  void _closeInputConnectionIfNeeded() {
    // Only close the connection if we currently have one.
    if (_hasInputConnection) {
      _textInputConnection!.close();
      _textInputConnection = null;
      _lastKnownRemoteTextEditingValue = null;
    }
  }

  void _openOrCloseInputConnectionIfNeeded() {
    if (_hasFocus && widget.focusNode.consumeKeyboardToken()) {
      _openInputConnection();
    } else if (!_hasFocus) {
      _closeInputConnectionIfNeeded();
      widget.controller.clearComposing();
    }
  }

  void _handleFocusChanged() {
    _openOrCloseInputConnectionIfNeeded();
  }

  @override
  void connectionClosed() {
    if (_hasInputConnection) {
      _textInputConnection!.connectionClosedReceived();
      _textInputConnection = null;
      _lastKnownRemoteTextEditingValue = null;
      _finalizeEditing(TextInputAction.done, shouldUnfocus: true);
    }
  }

  void _openInputConnection() {
    if (!_hasInputConnection) {
      final TextEditingValue localValue = _value;

      _textInputConnection = TextInput.attach(
        this,
        TextInputConfiguration(
          enableDeltaModel: true,
          inputAction: widget.textInputAction ??
              (widget.keyboardType == TextInputType.multiline
                  ? TextInputAction.newline
                  : TextInputAction.done),
        ),
      );

      _textInputConnection!.show();

      final TextStyle style = widget.style;
      _textInputConnection!
        ..setStyle(
          fontFamily: style.fontFamily,
          fontSize: style.fontSize,
          fontWeight: style.fontWeight,
          textDirection: _textDirection,
          textAlign: widget.textAlign,
        )
        ..setEditingState(localValue);
    } else {
      _textInputConnection!.show();
    }
  }

  TextDirection get _textDirection {
    final TextDirection result =
        widget.textDirection ?? Directionality.of(context);
    assert(result != null,
        '$runtimeType created without a textDirection and with no ambient Directionality.');
    return result;
  }

  @override
  // TODO: implement currentAutofillScope
  AutofillScope? get currentAutofillScope => throw UnimplementedError();

  @override
  TextEditingValue? get currentTextEditingValue => _value;

  @override
  void performAction(TextInputAction action) {
    switch (action) {
      case TextInputAction.newline:
        // If this is a multiline EditableText, do nothing for a "newline"
        // action; The newline is already inserted. Otherwise, finalize
        // editing.
        if (!_isMultiline) _finalizeEditing(action, shouldUnfocus: true);
        break;
      case TextInputAction.done:
      case TextInputAction.go:
      case TextInputAction.next:
      case TextInputAction.previous:
      case TextInputAction.search:
      case TextInputAction.send:
        _finalizeEditing(action, shouldUnfocus: true);
        break;
      case TextInputAction.continueAction:
      case TextInputAction.emergencyCall:
      case TextInputAction.join:
      case TextInputAction.none:
      case TextInputAction.route:
      case TextInputAction.unspecified:
        // Finalize editing, but don't give up focus because this keyboard
        // action does not imply the user is done inputting information.
        _finalizeEditing(action, shouldUnfocus: false);
        break;
    }
  }

  void _finalizeEditing(TextInputAction action, {required bool shouldUnfocus}) {
    // Default behavior if the developer did not provide an
    // onEditingComplete callback: Finalize editing and remove focus, or move
    // it to the next/previous field, depending on the action.
    widget.controller.clearComposing();
    if (shouldUnfocus) {
      switch (action) {
        case TextInputAction.none:
        case TextInputAction.unspecified:
        case TextInputAction.done:
        case TextInputAction.go:
        case TextInputAction.search:
        case TextInputAction.send:
        case TextInputAction.continueAction:
        case TextInputAction.join:
        case TextInputAction.route:
        case TextInputAction.emergencyCall:
        case TextInputAction.newline:
          widget.focusNode.unfocus();
          break;
        case TextInputAction.next:
          widget.focusNode.nextFocus();
          break;
        case TextInputAction.previous:
          widget.focusNode.previousFocus();
          break;
      }
    }
  }

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {
    // TODO: implement performPrivateCommand
  }

  @override
  void showAutocorrectionPromptRect(int start, int end) {
    // TODO: implement showAutocorrectionPromptRect
  }

  @override
  void updateEditingValue(TextEditingValue value) {
    // TODO: implement updateEditingValue
  }

  @override
  void updateEditingValueWithDeltas(List<TextEditingDelta> textEditingDeltas) {
    TextEditingValue value = _value;

    for (final TextEditingDelta delta in textEditingDeltas) {
      print('Delta class type: ' + delta.runtimeType.toString());
      print('Delta type: ' + delta.deltaType.toString());
      print('Delta old text: ' + delta.oldText);
      print('Delta new text: ' + delta.deltaText);
      print(
          'Delta beginning of new range: ' + delta.deltaRange.start.toString());
      print('Delta end of new range: ' + delta.deltaRange.end.toString());
      print('Delta beginning of new selection: ' +
          delta.selection.start.toString());
      print('Delta end of new selection: ' + delta.selection.end.toString());
      print('Delta beginning of new composing: ' +
          delta.composing.start.toString());
      print('Delta end of new composing: ' + delta.composing.end.toString());
      value = delta.apply(value);
    }

    _lastKnownRemoteTextEditingValue = value;

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
}

class _CustomTextOverlayPainter extends CustomPainter {
  const _CustomTextOverlayPainter({required this.rects, required this.color});

  final List<Rect> rects;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    paint.style = PaintingStyle.fill;

    for (final Rect rect in rects) {
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
