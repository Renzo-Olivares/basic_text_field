import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show TextEditingDelta;

import 'basic_text_input_client.dart';

typedef AnySelectionChangedCallback = void Function(TextSelection selection);
typedef TextEditingDeltaHistoryUpdateCallback = void Function(List<TextEditingDelta> textEditingDeltas);

/// A basic text field. Defines the appearance of a basic text input client.
class BasicTextField extends StatefulWidget {
  const BasicTextField({
    Key? key,
    required this.controller,
    required this.style,
    required this.focusNode,
    this.updateToggleButtonStateOnSelectionChanged,
    this.updateTextEditingDeltaHistory,
  }) : super(key: key);

  final TextEditingController controller;
  final TextStyle style;
  final FocusNode focusNode;
  final AnySelectionChangedCallback? updateToggleButtonStateOnSelectionChanged;
  final TextEditingDeltaHistoryUpdateCallback? updateTextEditingDeltaHistory;

  @override
  State<BasicTextField> createState() => _BasicTextFieldState();
}

class _BasicTextFieldState extends State<BasicTextField> {
  final GlobalKey<BasicTextInputClientState> textInputClientKey = GlobalKey<BasicTextInputClientState>();
  BasicTextInputClientState? get _textInputClient => textInputClientKey.currentState;
  RenderEditable get _renderEditable => _textInputClient!.renderEditable;

  // For text selection gestures.
  // The viewport offset pixels of the [RenderEditable] at the last drag start.
  double _dragStartViewportOffset = 0.0;
  late DragStartDetails _startDetails;

  // For text selection.
  TextSelectionControls? _textSelectionControls;
  bool _showSelectionHandles = false;

  bool _shouldShowSelectionHandles(SelectionChangedCause? cause) {
    // When the text field is activated by something that doesn't trigger the
    // selection overlay, we shouldn't show the handles either.
    if (cause == SelectionChangedCause.keyboard) {
      return false;
    }

    if (cause == SelectionChangedCause.longPress
        || cause == SelectionChangedCause.scribble) {
      return true;
    }

    if (widget.controller.text.isNotEmpty) {
      return true;
    }

    return false;
  }

  void _handleSelectionChanged(TextSelection selection, SelectionChangedCause? cause, bool selectionRangeChanged) {
    final bool willShowSelectionHandles = _shouldShowSelectionHandles(cause);
    if (willShowSelectionHandles != _showSelectionHandles) {
      setState(() {
        _showSelectionHandles = willShowSelectionHandles;
      });
    }

    if (cause != null && !selectionRangeChanged) {
      widget.updateToggleButtonStateOnSelectionChanged?.call(selection);
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final Offset startOffset = _renderEditable.maxLines == 1
        ? Offset(_renderEditable.offset.pixels - _dragStartViewportOffset, 0.0)
        : Offset(0.0, _renderEditable.offset.pixels - _dragStartViewportOffset);

    _renderEditable.selectPositionAt(
      from: _startDetails.globalPosition - startOffset,
      to: details.globalPosition,
      cause: SelectionChangedCause.drag,
    );
  }

  void _onDragStart(DragStartDetails details) {
    _startDetails = details;
    _dragStartViewportOffset = _renderEditable.offset.pixels;
  }

  @override
  Widget build(BuildContext context) {
    switch (Theme.of(this.context).platform) {
      case TargetPlatform.iOS:
        _textSelectionControls = cupertinoTextSelectionControls;
        break;
      case TargetPlatform.macOS:
        _textSelectionControls = cupertinoDesktopTextSelectionControls;
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        _textSelectionControls = materialTextSelectionControls;
        break;
      case TargetPlatform.linux:
        _textSelectionControls = desktopTextSelectionControls;
        break;
      case TargetPlatform.windows:
        _textSelectionControls = desktopTextSelectionControls;
        break;
    }

    return FocusTrapArea(
      focusNode: widget.focusNode,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (DragStartDetails details) => _onDragStart(details),
        onPanUpdate: (DragUpdateDetails details) => _onDragUpdate(details),
        onTap: () {
          _textInputClient!.requestKeyboard();
        },
        onTapDown: (TapDownDetails details) {
          _renderEditable.handleTapDown(details);
          _renderEditable.selectPosition(cause: SelectionChangedCause.tap);
        },
        onLongPressMoveUpdate: (LongPressMoveUpdateDetails details) {
          switch (Theme.of(this.context).platform) {
            case TargetPlatform.iOS:
            case TargetPlatform.macOS:
              _renderEditable.selectPositionAt(
                from: details.globalPosition,
                cause: SelectionChangedCause.longPress,
              );
              break;
            case TargetPlatform.android:
            case TargetPlatform.fuchsia:
            case TargetPlatform.linux:
            case TargetPlatform.windows:
              _renderEditable.selectWordsInRange(
                from: details.globalPosition - details.offsetFromOrigin,
                to: details.globalPosition,
                cause: SelectionChangedCause.longPress,
              );
              break;
          }
        },
        onLongPressEnd: (LongPressEndDetails details) => _textInputClient!.showToolbar(),
        onHorizontalDragStart: (DragStartDetails details) => _onDragStart(details),
        onHorizontalDragUpdate: (DragUpdateDetails details) => _onDragUpdate(details),
        child: SizedBox(
          height: double.infinity,
          width: MediaQuery.of(context).size.width,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              borderRadius: const BorderRadius.all(Radius.circular(4.0)),
            ),
            child: BasicTextInputClient(
              key: textInputClientKey,
              controller: widget.controller,
              style: widget.style,
              focusNode: widget.focusNode,
              selectionControls: _textSelectionControls,
              onSelectionChanged: _handleSelectionChanged,
              showSelectionHandles: _showSelectionHandles,
              updateTextEditingDeltaHistory: widget.updateTextEditingDeltaHistory,
            ),
          ),
        ),
      ),
    );
  }
}