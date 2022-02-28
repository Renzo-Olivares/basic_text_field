import 'package:flutter/material.dart';

import 'basic_text_input_client.dart';
import 'delta_text_selection.dart';

class _TextFieldSelectionGestureDetectorBuilder extends TextSelectionGestureDetectorBuilderCustom {
  _TextFieldSelectionGestureDetectorBuilder({
    required _BasicTextFieldState state,
  }) : _state = state,
        super(delegate: state);

  final _BasicTextFieldState _state;

  @override
  void onForcePressStart(ForcePressDetails details) {
    print('on force press start');
    super.onForcePressStart(details);
    if (delegate.selectionEnabled && shouldShowSelectionToolbar) {
      editableText.showToolbar();
    }
  }

  @override
  void onForcePressEnd(ForcePressDetails details) {
    // Not required.
  }

  @override
  void onSingleLongTapMoveUpdate(LongPressMoveUpdateDetails details) {
    print('on single long tap move update');
    if (delegate.selectionEnabled) {
      switch (Theme.of(_state.context).platform) {
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          renderEditable.selectPositionAt(
            from: details.globalPosition,
            cause: SelectionChangedCause.longPress,
          );
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          renderEditable.selectWordsInRange(
            from: details.globalPosition - details.offsetFromOrigin,
            to: details.globalPosition,
            cause: SelectionChangedCause.longPress,
          );
          break;
      }
    }
  }

  @override
  void onSingleTapUp(TapUpDetails details) {
    print('on single tap up');
    editableText.hideToolbar();
    super.onSingleTapUp(details);
    _state._requestKeyboard();
  }

  @override
  void onSingleLongTapStart(LongPressStartDetails details) {
    print('on single long tap start');
    if (delegate.selectionEnabled) {
      switch (Theme.of(_state.context).platform) {
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          renderEditable.selectPositionAt(
            from: details.globalPosition,
            cause: SelectionChangedCause.longPress,
          );
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          renderEditable.selectWord(cause: SelectionChangedCause.longPress);
          Feedback.forLongPress(_state.context);
          break;
      }
    }
  }
}

class BasicTextField extends StatefulWidget {
  const BasicTextField({
    Key? key,
    TextInputType? keyboardType,
    required this.controller,
    required this.style,
    required this.focusNode,
    required this.textAlign,
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

  @override
  State<StatefulWidget> createState() => _BasicTextFieldState();
}

class _BasicTextFieldState extends State<BasicTextField> implements TextSelectionGestureDetectorBuilderDelegateCustom {
  @override
  final GlobalKey<BasicTextInputClientState> basicTextInputClientKey = GlobalKey<BasicTextInputClientState>();

  BasicTextInputClientState? get _basicTextInputClient => basicTextInputClientKey.currentState;

  late _TextFieldSelectionGestureDetectorBuilder _selectionGestureDetectorBuilder;

  @override
  void initState() {
    super.initState();
    _selectionGestureDetectorBuilder = _TextFieldSelectionGestureDetectorBuilder(state: this);
  }

  @override
  bool get forcePressEnabled => true;

  @override
  bool get selectionEnabled => true;

  void _requestKeyboard() {
    _basicTextInputClient?.requestKeyboard();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Container(
      width: 350.0,
      height: 250.0,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueAccent),
        borderRadius: BorderRadius.circular(4),
      ),
      child: BasicTextInputClient(
        keyboardType: widget.keyboardType,
        key: basicTextInputClientKey,
        style: widget.style,
        controller: widget.controller,
        textAlign: widget.textAlign,
        focusNode: widget.focusNode,
        maxLines: widget.maxLines,
      ),
    );

    return FocusTrapArea(
      focusNode: widget.focusNode,
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (BuildContext context, Widget? child) {
          return GestureDetector(
            onTap: () {
              if (!widget.controller.selection.isValid) {
                widget.controller.selection = TextSelection.collapsed(offset: widget.controller.text.length);
              }
              _requestKeyboard();
            },
            child: child,
          );
        },
        child: _selectionGestureDetectorBuilder.buildGestureDetector(
          behavior: HitTestBehavior.translucent,
          child: child,
        ),
      ),
    );
  }
}