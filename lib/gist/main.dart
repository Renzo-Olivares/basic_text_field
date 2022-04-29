import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

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
                  children: const [
                    Icon(Icons.format_bold),
                    Icon(Icons.format_italic),
                    Icon(Icons.format_underline),
                  ],
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

  void _handleSelectionChanged(TextSelection selection, SelectionChangedCause? cause) {
    final bool willShowSelectionHandles = _shouldShowSelectionHandles(cause);
    if (willShowSelectionHandles != _showSelectionHandles) {
      setState(() {
        _showSelectionHandles = willShowSelectionHandles;
      });
    }

    if (cause != null) {
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

/// Signature for the callback that reports when the user changes the selection
/// (including the cursor location).
typedef SelectionChangedCallback = void Function(TextSelection selection, SelectionChangedCause? cause);

/// A basic text input client. An implementation of [DeltaTextInputClient] meant to
/// send/receive information from the framework to the platform's text input plugin
/// and vice-versa.
class BasicTextInputClient extends StatefulWidget {
  const BasicTextInputClient({
    Key? key,
    required this.controller,
    required this.style,
    required this.focusNode,
    this.selectionControls,
    required this.onSelectionChanged,
    required this.showSelectionHandles,
    this.updateTextEditingDeltaHistory,
  }) : super(key: key);

  final TextEditingController controller;
  final TextStyle style;
  final FocusNode focusNode;
  final TextSelectionControls? selectionControls;
  final bool showSelectionHandles;
  final SelectionChangedCallback onSelectionChanged;
  final TextEditingDeltaHistoryUpdateCallback? updateTextEditingDeltaHistory;

  @override
  State<BasicTextInputClient> createState() => BasicTextInputClientState();
}

class BasicTextInputClientState extends State<BasicTextInputClient>
    with TextSelectionDelegate implements DeltaTextInputClient {
  final GlobalKey _textKey = GlobalKey();
  final ClipboardStatusNotifier? _clipboardStatus = kIsWeb ? null : ClipboardStatusNotifier();

  @override
  void initState() {
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
    if (_hasInputConnection) {
      _textInputConnection!.connectionClosedReceived();
      _textInputConnection = null;
      _lastKnownRemoteTextEditingValue = null;
      widget.focusNode.unfocus();
      widget.controller.clearComposing();
    }
  }

  @override
  // Will not implement.
  AutofillScope? get currentAutofillScope => throw UnimplementedError();

  @override
  TextEditingValue? get currentTextEditingValue => _value;

  @override
  void insertTextPlaceholder(Size size) {
    // Will not implement. This method is used for Scribble support.
  }

  @override
  void performAction(TextInputAction action) {
    // Will not implement.
  }

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {
    // Will not implement.
  }

  @override
  void removeTextPlaceholder() {
    // Will not implement. This method is used for Scribble support.
  }

  @override
  void showAutocorrectionPromptRect(int start, int end) {
    // Will not implement.
  }

  @override
  bool showToolbar() {
    // On the web use provided native dom elements to provide clipboard functionality.
    if (kIsWeb) return false;

    if (_selectionOverlay == null || _selectionOverlay!.toolbarIsVisible) {
      return false;
    }

    _selectionOverlay!.showToolbar();

    return true;
  }

  @override
  void updateEditingValue(TextEditingValue value) { /* Not using */}

  @override
  void updateEditingValueWithDeltas(List<TextEditingDelta> textEditingDeltas) {
    TextEditingValue value = _value;

    for (final TextEditingDelta delta in textEditingDeltas) {
      value = delta.apply(value);
    }

    _lastKnownRemoteTextEditingValue = value;

    if (value == _value) {
      // This is possible, for example, when the numeric keyboard is input,
      // the engine will notify twice for the same value.
      // Track at https://github.com/flutter/flutter/issues/65811
      return;
    }

    final bool selectionChanged = _value.selection != value.selection;
    widget.updateTextEditingDeltaHistory?.call(textEditingDeltas);

    _value = value;

    if (widget.controller is ReplacementTextEditingController) {
      for (final TextEditingDelta delta in textEditingDeltas) {
        (widget.controller as ReplacementTextEditingController).syncReplacementRanges(delta);
      }
    }

    if (selectionChanged) widget.onSelectionChanged(value.selection, SelectionChangedCause.keyboard);
  }

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {
    // Will not implement.
  }

  /// Open/close [DeltaTextInputClient]
  TextInputConnection? _textInputConnection;
  bool get _hasInputConnection => _textInputConnection?.attached ?? false;

  TextEditingValue get _value => widget.controller.value;
  set _value(TextEditingValue value) {
    widget.controller.value = value;
  }

  // Keep track of the last known text editing value from the engine so we do not
  // send an update message if we don't have to.
  TextEditingValue? _lastKnownRemoteTextEditingValue;

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

      _lastKnownRemoteTextEditingValue = localValue;
    } else {
      _textInputConnection!.show();
    }
  }

  void _closeInputConnectionIfNeeded() {
    // Close input connection if one is active.
    if (_hasInputConnection) {
      _textInputConnection!.close();
      _textInputConnection = null;
      _lastKnownRemoteTextEditingValue = null;
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
    if (_hasFocus) {
      if (!_value.selection.isValid) {
        // Place cursor at the end if the selection is invalid when we receive focus.
        _handleSelectionChanged(TextSelection.collapsed(offset: _value.text.length), null);
      }
    }
  }

  /// Misc.
  TextDirection get _textDirection => Directionality.of(context);

  TextSpan _buildTextSpan() {
    return widget.controller.buildTextSpan(
      context: context,
      style: widget.style,
      withComposing: true,
    );
  }

  void _userUpdateTextEditingValueWithDelta(TextEditingDelta textEditingDelta, SelectionChangedCause cause) {
    TextEditingValue value = _value;

    value = textEditingDelta.apply(value);

    if (widget.controller is ReplacementTextEditingController) {
      (widget.controller as ReplacementTextEditingController).syncReplacementRanges(textEditingDelta);
    }

    if (value != _value) {
      widget.updateTextEditingDeltaHistory?.call([textEditingDelta]);
    }

    userUpdateTextEditingValue(value, cause);
  }

  /// Keyboard text editing actions.
  // The Handling of the default text editing shortcuts with deltas
  // needs to be in the framework somehow.  This should go through some kind of
  // generic "replace" method like in EditableText.
  // EditableText converts intents like DeleteCharacterIntent to a generic
  // ReplaceTextIntent. I wonder if that could be done at a higher level, so
  // that users could listen to that instead of DeleteCharacterIntent?
  TextSelection get _selection => _value.selection;
  late final Map<Type, Action<Intent>> _actions = <Type, Action<Intent>>{
    DeleteCharacterIntent: CallbackAction<DeleteCharacterIntent>(
      onInvoke: (DeleteCharacterIntent intent) => _delete(),
    ),
    ExtendSelectionByCharacterIntent: CallbackAction<ExtendSelectionByCharacterIntent>(
      onInvoke: (ExtendSelectionByCharacterIntent intent) => _extendSelection(intent.forward),
    ),
  };

  void _delete() {
    if (_value.text.isEmpty) return;

    late final TextRange deletedRange;
    late final TextRange newComposing;
    final int deletedLength = _value.text.substring(0, _selection.baseOffset).characters.last.length;

    if (_selection.isCollapsed) {
      if (_selection.baseOffset == 0) return;
      deletedRange = TextRange(
        start: _selection.baseOffset - deletedLength,
        end: _selection.baseOffset,
      );
    } else {
      deletedRange = _selection;
    }

    final bool isComposing = _selection.isCollapsed && _value.isComposingRangeValid;

    if (isComposing) {
      newComposing = TextRange.collapsed(deletedRange.start);
    } else {
      newComposing = TextRange.empty;
    }

    _userUpdateTextEditingValueWithDelta(
      TextEditingDeltaDeletion(
        oldText: _value.text,
        selection: TextSelection.collapsed(offset: deletedRange.start),
        composing: newComposing,
        deletedRange: deletedRange,
      ),
      SelectionChangedCause.keyboard,
    );
  }

  void _extendSelection(bool forward) {
    late final TextSelection selection;
    if (!_selection.isCollapsed) {
      final int firstOffset = _selection.isNormalized ? _selection.start : _selection.end;
      final int lastOffset = _selection.isNormalized ? _selection.end : _selection.start;
      selection = TextSelection.collapsed(offset: forward ? lastOffset : firstOffset);
    } else {
      if (forward && _selection.baseOffset == _value.text.length) return;
      if (!forward && _selection.baseOffset == 0) return;
      final int adjustment = forward
          ? _value.text.substring(_selection.baseOffset).characters.first.length
          : -_value.text.substring(0, _selection.baseOffset).characters.last.length;
      selection = TextSelection.collapsed(
        offset: _selection.baseOffset + adjustment,
      );
    }

    _userUpdateTextEditingValueWithDelta(
      TextEditingDeltaNonTextUpdate(
        oldText: _value.text,
        selection: selection,
        composing: _value.composing,
      ),
      SelectionChangedCause.keyboard,
    );
  }


  /// For updates to text editing value.
  void _didChangeTextEditingValue() {
    _updateRemoteTextEditingValueIfNeeded();
    _updateOrDisposeOfSelectionOverlayIfNeeded();
    setState(() {});
  }

  void _toggleToolbar() {
    assert(_selectionOverlay != null);
    if (_selectionOverlay!.toolbarIsVisible) {
      hideToolbar(false);
    } else {
      showToolbar();
    }
  }

  // When the framework's text editing value changes we should update the text editing
  // value contained within the selection overlay or we might observe unexpected behavior.
  void _updateOrDisposeOfSelectionOverlayIfNeeded() {
    if (_selectionOverlay != null) {
      if (_hasFocus) {
        _selectionOverlay!.update(_value);
      } else {
        _selectionOverlay!.dispose();
        _selectionOverlay = null;
      }
    }
  }

  // Only update the platform's text input plugin's text editing value when it has changed
  // to avoid sending duplicate update messages to the engine.
  void _updateRemoteTextEditingValueIfNeeded() {
    if (_lastKnownRemoteTextEditingValue == _value) return;

    if (_textInputConnection != null) {
      _textInputConnection!.setEditingState(_value);
      _lastKnownRemoteTextEditingValue = _value;
    }
  }

  /// [TextSelectionDelegate] method implementations.
  @override
  void bringIntoView(TextPosition position) {
    // Not implemented.
  }

  @override
  void copySelection(SelectionChangedCause cause) {
    final TextSelection copyRange = textEditingValue.selection;
    if (!copyRange.isValid || copyRange.isCollapsed) return;
    final String text = textEditingValue.text;
    Clipboard.setData(ClipboardData(text: copyRange.textInside(text)));

    // If copy was done by the text selection toolbar we should hide the toolbar and set the selection
    // to the end of the copied text.
    if (cause == SelectionChangedCause.toolbar) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          break;
        case TargetPlatform.macOS:
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          _userUpdateTextEditingValueWithDelta(
            TextEditingDeltaNonTextUpdate(
              oldText: textEditingValue.text,
              selection: TextSelection.collapsed(offset: textEditingValue.selection.end),
              composing: TextRange.empty,
            ),
            cause,
          );
          break;
      }
      hideToolbar();
    }
    _clipboardStatus?.update();
  }

  @override
  void cutSelection(SelectionChangedCause cause) {
    final TextSelection cutRange = textEditingValue.selection;
    final String text = textEditingValue.text;

    if (cutRange.isCollapsed) return;
    Clipboard.setData(ClipboardData(text: cutRange.textInside(text)));
    final int lastSelectionIndex = math.min(cutRange.baseOffset, cutRange.extentOffset);
    _userUpdateTextEditingValueWithDelta(
      TextEditingDeltaReplacement(
        oldText: textEditingValue.text,
        replacementText: '',
        replacedRange: cutRange,
        selection: TextSelection.collapsed(offset: lastSelectionIndex),
        composing: TextRange.empty,
      ),
      cause,
    );
    if (cause == SelectionChangedCause.toolbar) hideToolbar();
    _clipboardStatus?.update();
  }

  @override
  void hideToolbar([bool hideHandles = true]) {
    if (hideHandles) {
      // Hide the handles and the toolbar.
      _selectionOverlay?.hide();
    } else if (_selectionOverlay?.toolbarIsVisible ?? false) {
      // Hide only the toolbar but not the handles.
      _selectionOverlay?.hideToolbar();
    }
  }

  @override
  Future<void> pasteText(SelectionChangedCause cause) async {
    final TextSelection pasteRange = textEditingValue.selection;
    if (!pasteRange.isValid) return;

    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null) return;

    // After the paste, the cursor should be collapsed and located after the
    // pasted content.
    final int lastSelectionIndex = math.max(pasteRange.baseOffset, pasteRange.extentOffset);

    _userUpdateTextEditingValueWithDelta(
      TextEditingDeltaReplacement(
        oldText: textEditingValue.text,
        replacementText: data.text!,
        replacedRange: pasteRange,
        selection: TextSelection.collapsed(offset: lastSelectionIndex),
        composing: TextRange.empty,
      ),
      cause,
    );

    if (cause == SelectionChangedCause.toolbar) hideToolbar();
  }

  @override
  void selectAll(SelectionChangedCause cause) {
    final TextSelection newSelection = _value.selection.copyWith(baseOffset: 0, extentOffset: _value.text.length);
    _userUpdateTextEditingValueWithDelta(
      TextEditingDeltaNonTextUpdate(
          oldText: textEditingValue.text,
          selection: newSelection,
          composing: TextRange.empty
      ),
      cause,
    );
  }

  @override
  TextEditingValue get textEditingValue => _value;

  @override
  void userUpdateTextEditingValue(TextEditingValue value, SelectionChangedCause cause) {
    if (value == _value) return;

    final bool selectionChanged = _value.selection != value.selection;

    if (cause == SelectionChangedCause.drag || cause == SelectionChangedCause.longPress || cause == SelectionChangedCause.tap) {
      // Here the change is coming from gestures which call on RenderEditable to change the selection.
      // Create a TextEditingDeltaNonTextUpdate so we can keep track of the delta history. RenderEditable
      // does not report a delta on selection change.
      final bool textChanged = _value.text != value.text;
      if (selectionChanged && !textChanged) {
        final TextEditingDeltaNonTextUpdate selectionUpdate = TextEditingDeltaNonTextUpdate(
          oldText: value.text,
          selection: value.selection,
          composing: value.composing,
        );
        widget.updateTextEditingDeltaHistory?.call([selectionUpdate]);
      }
    }

    _value = value;

    if (selectionChanged) _handleSelectionChanged(_value.selection, cause);
  }

  /// For TextSelection.
  final LayerLink _startHandleLayerLink = LayerLink();
  final LayerLink _endHandleLayerLink = LayerLink();
  final LayerLink _toolbarLayerLink = LayerLink();

  TextSelectionOverlay? _selectionOverlay;
  RenderEditable get renderEditable => _textKey.currentContext!.findRenderObject()! as RenderEditable;

  void _handleSelectionChanged(TextSelection selection, SelectionChangedCause? cause) {
    // We return early if the selection is not valid. This can happen when the
    // text of [EditableText] is updated at the same time as the selection is
    // changed by a gesture event.
    if (!widget.controller.isSelectionWithinTextBounds(selection)) return;

    widget.controller.selection = selection;

    // This will show the keyboard for all selection changes on the
    // EditableText except for those triggered by a keyboard input.
    // Typically BasicTextInputClient shouldn't take user keyboard input if
    // it's not focused already.
    switch (cause) {
      case null:
      case SelectionChangedCause.doubleTap:
      case SelectionChangedCause.drag:
      case SelectionChangedCause.forcePress:
      case SelectionChangedCause.longPress:
      case SelectionChangedCause.scribble:
      case SelectionChangedCause.tap:
      case SelectionChangedCause.toolbar:
        requestKeyboard();
        break;
      case SelectionChangedCause.keyboard:
        if (_hasFocus) {
          requestKeyboard();
        }
        break;
    }
    if (widget.selectionControls == null) {
      _selectionOverlay?.dispose();
      _selectionOverlay = null;
    } else {
      if (_selectionOverlay == null) {
        _selectionOverlay = TextSelectionOverlay(
          clipboardStatus: _clipboardStatus,
          context: context,
          value: _value,
          debugRequiredFor: widget,
          toolbarLayerLink: _toolbarLayerLink,
          startHandleLayerLink: _startHandleLayerLink,
          endHandleLayerLink: _endHandleLayerLink,
          renderObject: renderEditable,
          selectionControls: widget.selectionControls,
          selectionDelegate: this,
          dragStartBehavior: DragStartBehavior.start,
          onSelectionHandleTapped: () {
            _toggleToolbar();
          },
        );
      } else {
        _selectionOverlay!.update(_value);
      }
      _selectionOverlay!.handlesVisible = widget.showSelectionHandles;
      _selectionOverlay!.showHandles();
    }

    try {
      widget.onSelectionChanged.call(selection, cause);
    } catch (exception, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: exception,
        stack: stack,
        library: 'widgets',
        context: ErrorDescription('while calling onSelectionChanged for $cause'),
      ));
    }
  }

  static final Map<ShortcutActivator, Intent> _defaultWebShortcuts = <ShortcutActivator, Intent>{
    // Activation
    const SingleActivator(LogicalKeyboardKey.space): DoNothingAndStopPropagationIntent(),

    // Scrolling
    const SingleActivator(LogicalKeyboardKey.arrowUp): DoNothingAndStopPropagationIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowDown): DoNothingAndStopPropagationIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowLeft): DoNothingAndStopPropagationIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowRight): DoNothingAndStopPropagationIntent(),
  };

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: kIsWeb ? _defaultWebShortcuts : <ShortcutActivator, Intent>{},
      child: Actions(
        actions: _actions,
        child: Focus(
          focusNode: widget.focusNode,
          child: Scrollable(
            viewportBuilder: (BuildContext context, ViewportOffset position) {
              return CompositedTransformTarget(
                link: _toolbarLayerLink,
                child: _Editable(
                  key: _textKey,
                  startHandleLayerLink: _startHandleLayerLink,
                  endHandleLayerLink: _endHandleLayerLink,
                  inlineSpan: _buildTextSpan(),
                  value: _value, // We pass value.selection to RenderEditable.
                  cursorColor: Colors.blue,
                  backgroundCursorColor: Colors.grey[100],
                  showCursor: ValueNotifier<bool>(true),
                  forceLine: true, // Whether text field will take full line regardless of width.
                  readOnly: false, // editable text-field.
                  hasFocus: _hasFocus,
                  maxLines: null, // multi-line text-field.
                  minLines: null,
                  expands: false, // expands to height of parent.
                  strutStyle: null,
                  selectionColor: Colors.blue.withOpacity(0.40),
                  textScaleFactor: MediaQuery.textScaleFactorOf(context),
                  textAlign: TextAlign.left,
                  textDirection: _textDirection,
                  locale: Localizations.maybeLocaleOf(context),
                  textHeightBehavior: DefaultTextHeightBehavior.of(context),
                  textWidthBasis: TextWidthBasis.parent,
                  obscuringCharacter: '•',
                  obscureText: false, // This is a non-private text field that does not require obfuscation.
                  offset: position,
                  onCaretChanged: null,
                  rendererIgnoresPointer: true,
                  cursorWidth: 2.0,
                  cursorHeight: null,
                  cursorRadius: const Radius.circular(2.0),
                  cursorOffset: Offset.zero,
                  paintCursorAboveText: false,
                  enableInteractiveSelection: true, // make true to enable selection on mobile.
                  textSelectionDelegate: this,
                  devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
                  promptRectRange: null,
                  promptRectColor: null,
                  clipBehavior: Clip.hardEdge,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Editable extends MultiChildRenderObjectWidget {
  _Editable({
    Key? key,
    required this.inlineSpan,
    required this.value,
    required this.startHandleLayerLink,
    required this.endHandleLayerLink,
    this.cursorColor,
    this.backgroundCursorColor,
    required this.showCursor,
    required this.forceLine,
    required this.readOnly,
    this.textHeightBehavior,
    required this.textWidthBasis,
    required this.hasFocus,
    required this.maxLines,
    this.minLines,
    required this.expands,
    this.strutStyle,
    this.selectionColor,
    required this.textScaleFactor,
    required this.textAlign,
    required this.textDirection,
    this.locale,
    required this.obscuringCharacter,
    required this.obscureText,
    required this.offset,
    this.onCaretChanged,
    this.rendererIgnoresPointer = false,
    required this.cursorWidth,
    this.cursorHeight,
    this.cursorRadius,
    required this.cursorOffset,
    required this.paintCursorAboveText,
    this.enableInteractiveSelection = true,
    required this.textSelectionDelegate,
    required this.devicePixelRatio,
    this.promptRectRange,
    this.promptRectColor,
    required this.clipBehavior,
  }) : super(key: key, children: _extractChildren(inlineSpan));

  // Traverses the InlineSpan tree and depth-first collects the list of
  // child widgets that are created in WidgetSpans.
  static List<Widget> _extractChildren(InlineSpan span) {
    final List<Widget> result = <Widget>[];
    span.visitChildren((InlineSpan span) {
      if (span is WidgetSpan) {
        result.add(span.child);
      }
      return true;
    });
    return result;
  }

  final InlineSpan inlineSpan;
  final TextEditingValue value;
  final Color? cursorColor;
  final LayerLink startHandleLayerLink;
  final LayerLink endHandleLayerLink;
  final Color? backgroundCursorColor;
  final ValueNotifier<bool> showCursor;
  final bool forceLine;
  final bool readOnly;
  final bool hasFocus;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final StrutStyle? strutStyle;
  final Color? selectionColor;
  final double textScaleFactor;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final Locale? locale;
  final String obscuringCharacter;
  final bool obscureText;
  final TextHeightBehavior? textHeightBehavior;
  final TextWidthBasis textWidthBasis;
  final ViewportOffset offset;
  final CaretChangedHandler? onCaretChanged;
  final bool rendererIgnoresPointer;
  final double cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final Offset cursorOffset;
  final bool paintCursorAboveText;
  final bool enableInteractiveSelection;
  final TextSelectionDelegate textSelectionDelegate;
  final double devicePixelRatio;
  final TextRange? promptRectRange;
  final Color? promptRectColor;
  final Clip clipBehavior;

  @override
  RenderEditable createRenderObject(BuildContext context) {
    return RenderEditable(
      text: inlineSpan,
      cursorColor: cursorColor,
      startHandleLayerLink: startHandleLayerLink,
      endHandleLayerLink: endHandleLayerLink,
      backgroundCursorColor: backgroundCursorColor,
      showCursor: showCursor,
      forceLine: forceLine,
      readOnly: readOnly,
      hasFocus: hasFocus,
      maxLines: maxLines,
      minLines: minLines,
      expands: expands,
      strutStyle: strutStyle,
      selectionColor: selectionColor,
      textScaleFactor: textScaleFactor,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale ?? Localizations.maybeLocaleOf(context),
      selection: value.selection,
      offset: offset,
      onCaretChanged: onCaretChanged,
      ignorePointer: rendererIgnoresPointer,
      obscuringCharacter: obscuringCharacter,
      obscureText: obscureText,
      textHeightBehavior: textHeightBehavior,
      textWidthBasis: textWidthBasis,
      cursorWidth: cursorWidth,
      cursorHeight: cursorHeight,
      cursorRadius: cursorRadius,
      cursorOffset: cursorOffset,
      paintCursorAboveText: paintCursorAboveText,
      enableInteractiveSelection: enableInteractiveSelection,
      textSelectionDelegate: textSelectionDelegate,
      devicePixelRatio: devicePixelRatio,
      promptRectRange: promptRectRange,
      promptRectColor: promptRectColor,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderEditable renderObject) {
    renderObject
      ..text = inlineSpan
      ..cursorColor = cursorColor
      ..startHandleLayerLink = startHandleLayerLink
      ..endHandleLayerLink = endHandleLayerLink
      ..showCursor = showCursor
      ..forceLine = forceLine
      ..readOnly = readOnly
      ..hasFocus = hasFocus
      ..maxLines = maxLines
      ..minLines = minLines
      ..expands = expands
      ..strutStyle = strutStyle
      ..selectionColor = selectionColor
      ..textScaleFactor = textScaleFactor
      ..textAlign = textAlign
      ..textDirection = textDirection
      ..locale = locale ?? Localizations.maybeLocaleOf(context)
      ..selection = value.selection
      ..offset = offset
      ..onCaretChanged = onCaretChanged
      ..ignorePointer = rendererIgnoresPointer
      ..textHeightBehavior = textHeightBehavior
      ..textWidthBasis = textWidthBasis
      ..obscuringCharacter = obscuringCharacter
      ..obscureText = obscureText
      ..cursorWidth = cursorWidth
      ..cursorHeight = cursorHeight
      ..cursorRadius = cursorRadius
      ..cursorOffset = cursorOffset
      ..enableInteractiveSelection = enableInteractiveSelection
      ..textSelectionDelegate = textSelectionDelegate
      ..devicePixelRatio = devicePixelRatio
      ..paintCursorAboveText = paintCursorAboveText
      ..promptRectColor = promptRectColor
      ..clipBehavior = clipBehavior
      ..setPromptRectRange(promptRectRange);
  }
}

/// Signature for the generator function that produces an [InlineSpan] for replacement
/// in a [TextEditingInlineSpanReplacement].
///
/// This function takes a String which is the matched substring to be replaced and a [TextRange]
/// representing the range in the full string the matched substring originated from.
///
/// This used in [ReplacementTextEditingController] to generate [InlineSpan]s when
/// a match is found for replacement.
typedef InlineSpanGenerator = InlineSpan Function(String, TextRange);

/// Represents one "replacement" to check for, consisting of a [TextRange] to
/// match and a generator [InlineSpanGenerator] function that creates an
/// [InlineSpan] from a matched string.
///
/// The generator function is called for every match of the range found.
///
/// Typically, the generator should return a custom [TextSpan] with unique styling.
///
/// {@tool snippet}
/// In this simple example, the text in the range of 0 to 5 is styled in blue.
///
/// ```dart
/// TextEditingInlineSpanReplacement(
///   TextRange(start: 0, end: 5),
///   (String value, TextRange range) {
///     return TextSpan(text: value, style: TextStyle(color: Colors.blue));
///   },
/// )
/// ```
///
/// See also:
///
/// * [ReplacementTextEditingController], which uses this class to create
/// rich text fields.
/// {@end-tool}
class TextEditingInlineSpanReplacement {
  /// Constructs a replacement that replaces matches of the [TextRange] with the
  /// output of the [generator].
  TextEditingInlineSpanReplacement(this.range, this.generator, this.expand);

  /// The [TextRange] to replace.
  ///
  /// Matched ranges are replaced with the output of the [generator] callback.
  TextRange range;

  /// Function that returns an [InlineSpan] instance for each match of
  /// [TextRange].
  InlineSpanGenerator generator;

  bool expand;

  /// Creates a new replacement with all properties copied except for range, which
  /// is updated to the specified value.
  TextEditingInlineSpanReplacement copy({TextRange? range, bool? expand}) {
    return TextEditingInlineSpanReplacement(range ?? this.range, generator, expand ?? this.expand);
  }

  @override
  String toString() {
    return 'TextEditingInlineSpanReplacement { range: $range, generator: $generator }';
  }
}

/// A [TextEditingController] that contains a list of [TextEditingInlineSpanReplacement]s that
/// insert custom [InlineSpan]s in place of matched [TextRange]s.
///
/// This controller must be passed [TextEditingInlineSpanReplacement], each of which contains
/// a [TextRange] to match with and a generator function to generate an [InlineSpan] to replace
/// the matched [TextRange]s with based on the matched string.
///
/// See [TextEditingInlineSpanReplacement] for example replacements to provide this class with.
class ReplacementTextEditingController extends TextEditingController {
  /// Constructs a controller with optional text that handles the provided list of replacements.
  ReplacementTextEditingController({
    String? text,
    List<TextEditingInlineSpanReplacement>? replacements,
    this.composingRegionReplaceable = true,
  }) : replacements = replacements ?? [],
        super(text: text);

  /// Creates a controller for an editable text field from an initial [TextEditingValue].
  ///
  /// This constructor treats a null [value] argument as if it were [TextEditingValue.empty].
  ReplacementTextEditingController.fromValue(TextEditingValue? value,
      {List<TextEditingInlineSpanReplacement>? replacements,
        this.composingRegionReplaceable = true})
      : super.fromValue(value);

  /// The [TextEditingInlineSpanReplacement]s that are evaluated on the editing value.
  ///
  /// Each replacement is evaluated in order from first to last. If multiple replacement
  /// [TextRange]s match against the same range of text,
  List<TextEditingInlineSpanReplacement>? replacements;

  /// If composing regions should be matched against for replacements.
  ///
  /// When false, composing regions are invalidated from being matched against.
  ///
  /// When true, composing regions are attempted to be applied after ranges are
  /// matched and replacements made. This means that composing region may sometimes
  /// fail to display if the text in the composing region matches against of the
  /// replacement ranges.
  final bool composingRegionReplaceable;

  void applyReplacement(TextEditingInlineSpanReplacement replacement) {
    if (replacements == null) {
      replacements = [];
      replacements!.add(replacement);
    } else {
      replacements!.add(replacement);
    }
  }

  /// Update replacement ranges based on [TextEditingDelta]'s coming from a
  /// [DeltaTextInputClient]'s.
  ///
  /// On a insertion, the replacements that ranges fall inclusively
  /// within the range of the insertion, should be updated to take into account
  /// the insertion that happened within the replacement range. i.e. we expand
  /// the range.
  ///
  /// On a insertion, the replacements that ranges fall after the
  /// range of the insertion, should be updated to take into account the insertion
  /// that occurred and the offset it created as a result.
  ///
  /// On a insertion, the replacements that ranges fall before
  /// the range of the insertion, should be skipped and not updated as their values
  /// are not offset by the insertion.
  ///
  /// On a insertion, if a replacement range front edge is touched by
  /// the insertion, the range should be updated with the insertion offset. i.e.
  /// the replacement range is pushed forward.
  ///
  /// On a insertion, if a replacement range back edge is touched by
  /// the insertion offset, nothing should be done. i.e. do not expand the range.
  ///
  /// On a deletion, the replacements that ranges fall inclusively
  /// within the range of the deletion, should be updated to take into account
  /// the deletion that happened within the replacement range. i.e. we contract the range.
  ///
  /// On a deletion, the replacement ranges that fall after the
  /// ranges of deletion, should be updated to take into account the deletion
  /// that occurred and the offset it created as a result.
  ///
  /// On a deletion, the replacement ranges that fall before the
  /// ranges of deletion, should be skipped and not updated as their values are
  /// not offset by the deletion.
  ///
  /// On a replacement, the replacements that ranges fall inclusively
  /// within the range of the replaced range, should be updated to take into account
  /// that the replaced range should be un-styled. i.e. we split the replacement ranges
  /// into two.
  ///
  /// On a replacement, the replacement ranges that fall after the
  /// ranges of the replacement, should be updated to take into account the replacement
  /// that occurred and the offset it created as a result.
  ///
  /// On a replacement, the replacement ranges that fall before the
  /// ranges of replacement, should be skipped and not updated as their values are
  /// not offset by the replacement.
  void syncReplacementRanges(TextEditingDelta delta) {
    if (replacements == null) return;

    if (text.isEmpty) replacements!.clear();

    List<TextEditingInlineSpanReplacement> updatedReplacements = [];
    List<TextEditingInlineSpanReplacement> toRemove = [];

    for (final TextEditingInlineSpanReplacement replacement
    in replacements!) {
      // Syncing insertions.
      if (delta is TextEditingDeltaInsertion) {
        if (delta.insertionOffset == replacement.range.end
            && delta.insertionOffset == replacement.range.start) {
          if (replacement.expand) {
            updatedReplacements.add(
              replacement.copy(
                range: TextRange(
                  start: replacement.range.start,
                  end: replacement.range.end + delta.textInserted.length,
                ),
              ),
            );
          }
        } else if (delta.insertionOffset > replacement.range.start
            && delta.insertionOffset < replacement.range.end) {
          // Update replacement where insertion offset is inclusively within replacement range.
          updatedReplacements.add(
            replacement.copy(
              range: TextRange(
                start: replacement.range.start,
                end: replacement.range.end + delta.textInserted.length,
              ),
            ),
          );
        } else if (delta.insertionOffset > replacement.range.end) {
          // Update replacements that happen before insertion offset.
          updatedReplacements.add(replacement);
        } else if (delta.insertionOffset < replacement.range.start) {
          // Update replacements that happen after the insertion offset.
          updatedReplacements.add(
            replacement.copy(
              range: TextRange(
                start: replacement.range.start + delta.textInserted.length,
                end: replacement.range.end + delta.textInserted.length,
              ),
            ),
          );
        } else if (delta.insertionOffset == replacement.range.start
            || delta.insertionOffset == replacement.range.end) {
          if (delta.insertionOffset == replacement.range.start) {
            // Updating replacement where insertion offset touches front edge of replacement range.
            updatedReplacements.add(
              replacement.copy(
                range: TextRange(
                  start: replacement.range.start + delta.textInserted.length,
                  end: replacement.range.end + delta.textInserted.length,
                ),
              ),
            );
          } else if (delta.insertionOffset == replacement.range.end) {
            // Updating replacement where insertion offset touches back edge of replacement range.
            if (replacement.expand) {
              updatedReplacements.add(
                replacement.copy(
                  range: TextRange(
                    start: replacement.range.start,
                    end: replacement.range.end + delta.textInserted.length,
                  ),
                ),
              );
            } else {
              updatedReplacements.add(replacement);
            }
          }
        }
      } else if (delta is TextEditingDeltaDeletion) {
        // Syncing deletions.
        if (delta.deletedRange.start >= replacement.range.start
            && delta.deletedRange.end <= replacement.range.end) {
          // Update replacement ranges directly inclusively associated with deleted range.
          if (replacement.range.start !=
              replacement.range.end - delta.textDeleted.length) {
            updatedReplacements.add(
              replacement.copy(
                range: TextRange(
                  start: replacement.range.start,
                  end: replacement.range.end - delta.textDeleted.length,
                ),
              ),
            );
          } else {
            // Removing replacement.
            toRemove.add(replacement);
          }
        } else if (delta.deletedRange.start > replacement.range.end
            && delta.deletedRange.end > replacement.range.end) {
          // Replacements that occurred before deletion range do not need updating.
          updatedReplacements.add(replacement);
        } else if (delta.deletedRange.end < replacement.range.start) {
          // Updating replacements that occurred after the deleted range.
          updatedReplacements.add(
            replacement.copy(
              range: TextRange(
                start: replacement.range.start - delta.textDeleted.length,
                end: replacement.range.end - delta.textDeleted.length,
              ),
            ),
          );
        } else if (delta.deletedRange.start == replacement.range.start
            || delta.deletedRange.start == replacement.range.end
            || delta.deletedRange.end == replacement.range.start
            || delta.deletedRange.end == replacement.range.end) {
          if (delta.deletedRange.start == replacement.range.end
              || delta.deletedRange.end == replacement.range.end) {
            // Updating replacement where the deleted range touches back edge of replacement range
            if (delta.deletedRange.start == replacement.range.end) {
              updatedReplacements.add(replacement);
            }

            if (delta.deletedRange.end == replacement.range.end) {
              if (replacement.expand) {
                final int end = replacement.range.end -
                    delta.textDeleted.length;
                if (replacement.range.start == end) {
                  toRemove.add(replacement);
                } else {
                  updatedReplacements.add(
                    replacement.copy(
                      range: TextRange(
                        start: replacement.range.start,
                        end: end,
                      ),
                    ),
                  );
                }
              } else {
                if (replacement.range.start == replacement.range.end) {
                  toRemove.add(replacement);
                } else {
                  updatedReplacements.add(replacement);
                }
              }
            }
          } else if (delta.deletedRange.start == replacement.range.start
              || delta.deletedRange.end == replacement.range.start) {
            // Updating replacement where the deleted range touches front edge of replacement range.
            updatedReplacements.add(
              replacement.copy(
                range: TextRange(
                  start: replacement.range.start - delta.textDeleted.length,
                  end: replacement.range.end - delta.textDeleted.length,
                ),
              ),
            );
          }
        }
      } else if (delta is TextEditingDeltaReplacement) {
        final bool replacementShortenedText = delta.replacementText.length < delta.textReplaced.length;
        final bool replacementLengthenedText = delta.replacementText.length > delta.textReplaced.length;
        final bool replacementEqualLength = delta.replacementText.length == delta.textReplaced.length;
        final int changedOffset = replacementShortenedText ? delta.textReplaced.length - delta.replacementText.length : delta.replacementText.length - delta.textReplaced.length;

        // Syncing replacements.
        if (delta.replacedRange.start >= replacement.range.start
            && delta.replacedRange.end <= replacement.range.end) {
          // Update replacement ranges directly inclusively associated with replaced range.
          final int replacementEndOffset = replacement.range.end;
          final int replacementStartOffset = replacement.range.start;

          if (replacementLengthenedText) {
            updatedReplacements.add(
              replacement.copy(
                range: TextRange(
                  start: replacementStartOffset,
                  end: delta.replacedRange.start,
                ),
              ),
            );

            updatedReplacements.add(
              replacement.copy(
                range: TextRange(
                  start: delta.replacedRange.end + changedOffset,
                  end: replacementEndOffset + changedOffset,
                ),
              ),
            );
          }

          if (replacementShortenedText) {
            updatedReplacements.add(
              replacement.copy(
                range: TextRange(
                  start: replacementStartOffset,
                  end: delta.replacedRange.start,
                ),
              ),
            );

            updatedReplacements.add(
              replacement.copy(
                range: TextRange(
                  start: delta.replacedRange.end - changedOffset,
                  end: replacementEndOffset - changedOffset,
                ),
              ),
            );
          }

          if (replacementEqualLength) {
            updatedReplacements.add(
              replacement.copy(
                range: TextRange(
                  start: replacementStartOffset,
                  end: delta.replacedRange.start,
                ),
              ),
            );

            updatedReplacements.add(
              replacement.copy(
                range: TextRange(
                  start: delta.replacedRange.end,
                  end: replacementEndOffset,
                ),
              ),
            );
          }
        } else if (delta.replacedRange.start > replacement.range.end
            && delta.replacedRange.end > replacement.range.end) {
          // Replacements that occurred before replaced range do not need updating.
          updatedReplacements.add(replacement);
        } else if (delta.replacedRange.end < replacement.range.start) {
          // Updating replacements that occurred after the replaced range.
          if (replacementLengthenedText) {
            updatedReplacements.add(
              replacement.copy(
                range: TextRange(
                  start: replacement.range.start + changedOffset,
                  end: replacement.range.end + changedOffset,
                ),
              ),
            );
          }

          if (replacementShortenedText) {
            updatedReplacements.add(
              replacement.copy(
                range: TextRange(
                  start: replacement.range.start - changedOffset,
                  end: replacement.range.end - changedOffset,
                ),
              ),
            );
          }

          if (replacementEqualLength) {
            updatedReplacements.add(replacement);
          }
        } else if (delta.replacedRange.start == replacement.range.start
            || delta.replacedRange.start == replacement.range.end
            || delta.replacedRange.end == replacement.range.start
            || delta.replacedRange.end == replacement.range.end) {
          if (delta.replacedRange.start == replacement.range.end
              || delta.replacedRange.end == replacement.range.end) {
            // Updating replacement where the replaced range touches back edge of replacement range.
            updatedReplacements.add(replacement);
          } else if (delta.replacedRange.start == replacement.range.start
              || delta.replacedRange.end == replacement.range.start) {
            // Updating replacement where the replaced range touches front edge of replacement range.
            if (replacementLengthenedText) {
              updatedReplacements.add(
                replacement.copy(
                  range: TextRange(
                    start: replacement.range.start + changedOffset,
                    end: replacement.range.end + changedOffset,
                  ),
                ),
              );
            }

            if (replacementShortenedText) {
              updatedReplacements.add(
                replacement.copy(
                  range: TextRange(
                    start: replacement.range.start - changedOffset,
                    end: replacement.range.end - changedOffset,
                  ),
                ),
              );
            }

            if (replacementEqualLength) {
              updatedReplacements.add(replacement);
            }
          }
        }
      } else if (delta is TextEditingDeltaNonTextUpdate) {
        // Sync non text updates.
        // Nothing to do here.
      }
    }

    if (updatedReplacements.isNotEmpty) {
      replacements!.clear();
      replacements!.addAll(updatedReplacements);
    }

    if (updatedReplacements.isEmpty) {
      for (final TextEditingInlineSpanReplacement replacementToRemove in toRemove) {
        replacements!.remove(replacementToRemove);
      }
    }
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    assert(!value.composing.isValid
        || !withComposing
        || value.isComposingRangeValid);

    // Keep a mapping of TextRanges to the InlineSpan to replace it with.
    final Map<TextRange, InlineSpan> rangeSpanMapping = <TextRange, InlineSpan>{};

    // If the composing range is out of range for the current text, ignore it to
    // preserve the tree integrity, otherwise in release mode a RangeError will
    // be thrown and this EditableText will be built with a broken subtree.
    //
    // Add composing region as a replacement to a TextSpan with underline.
    if (!composingRegionReplaceable
        && value.isComposingRangeValid
        && withComposing) {
      _addToMappingWithOverlaps((String value, TextRange range) {
        final TextStyle composingStyle = style != null
            ? style.merge(const TextStyle(decoration: TextDecoration.underline))
            : const TextStyle(decoration: TextDecoration.underline);
        return TextSpan(
          style: composingStyle,
          text: value,
        );
      }, value.composing, rangeSpanMapping, value.text);
    }

    // Iterate through TextEditingInlineSpanReplacements, handling overlapping
    // replacements and mapping them towards a generated InlineSpan.
    if (replacements != null) {
      for (final TextEditingInlineSpanReplacement replacement in replacements!) {
        _addToMappingWithOverlaps(
          replacement.generator,
          TextRange(start: replacement.range.start, end: replacement.range.end),
          rangeSpanMapping,
          value.text,
        );
      }
    }

    // If the composing range is out of range for the current text, ignore it to
    // preserve the tree integrity, otherwise in release mode a RangeError will
    // be thrown and this EditableText will be built with a broken subtree.
    //
    // Add composing region as a replacement to a TextSpan with underline.
    if (composingRegionReplaceable
        && value.isComposingRangeValid
        && withComposing) {
      _addToMappingWithOverlaps((String value, TextRange range) {
        final TextStyle composingStyle = style != null
            ? style.merge(const TextStyle(decoration: TextDecoration.underline))
            : const TextStyle(decoration: TextDecoration.underline);
        return TextSpan(
          style: composingStyle,
          text: value,
        );
      }, value.composing, rangeSpanMapping, value.text);
    }

    // Sort the matches by start index. Since no overlapping exists, this is safe.
    final List<TextRange> sortedRanges = rangeSpanMapping.keys.toList();
    sortedRanges.sort((TextRange a, TextRange b) => a.start.compareTo(b.start));

    // Create TextSpans for non-replaced text ranges and insert the replacements spans
    // for any ranges that are marked to be replaced.
    final List<InlineSpan> spans = <InlineSpan>[];
    int previousEndIndex = 0;
    for (final TextRange range in sortedRanges) {
      if (range.start > previousEndIndex) {
        spans.add(TextSpan(text: value.text.substring(previousEndIndex, range.start)));
      }
      spans.add(rangeSpanMapping[range]!);
      previousEndIndex = range.end;
    }
    // Add any trailing text as a regular TextSpan.
    if (previousEndIndex < value.text.length) {
      spans.add(TextSpan(
          text: value.text.substring(previousEndIndex, value.text.length)));
    }
    return TextSpan(
      style: style,
      children: spans,
    );
  }

  static void _addToMappingWithOverlaps(
      InlineSpanGenerator generator,
      TextRange matchedRange,
      Map<TextRange, InlineSpan> rangeSpanMapping,
      String text) {
    // In some cases we should allow for overlap.
    // For example in the case of two TextSpans matching the same range for replacement,
    // we should try to merge the styles into one TextStyle and build a new TextSpan.
    bool overlap = false;
    List<TextRange> overlapRanges = <TextRange>[];
    for (final TextRange range in rangeSpanMapping.keys) {
      if (math.max(matchedRange.start, range.start)
          <= math.min(matchedRange.end, range.end)) {
        overlap = true;
        overlapRanges.add(range);
      }
    }

    final List<List<dynamic>> overlappingTriples = <List<dynamic>>[];

    if (overlap) {
      overlappingTriples.add([matchedRange.start, matchedRange.end, generator(matchedRange.textInside(text), matchedRange).style]);

      for (final TextRange overlappingRange in overlapRanges) {
        overlappingTriples.add([overlappingRange.start, overlappingRange.end, rangeSpanMapping[overlappingRange]!.style]);
        rangeSpanMapping.remove(overlappingRange);
      }

      final List<dynamic> toRemoveRangesThatHaveBeenMerged = [];
      final List<dynamic> toAddRangesThatHaveBeenMerged = [];
      for (int i = 0; i < overlappingTriples.length; i++) {
        List<dynamic> tripleA = overlappingTriples[i];
        if (toRemoveRangesThatHaveBeenMerged.contains(tripleA)) continue;
        for (int j = i + 1; j < overlappingTriples.length; j++) {
          final List<dynamic> tripleB = overlappingTriples[j];
          if (math.max(tripleA[0] as int, tripleB[0] as int)
              <= math.min(tripleB[1] as int, tripleB[1] as int)
              && tripleA[2] == tripleB[2]) {
            toRemoveRangesThatHaveBeenMerged.addAll([tripleA, tripleB]);
            tripleA = [
              math.min(tripleA[0] as int, tripleB[0] as int),
              math.max(tripleA[1] as int, tripleB[1] as int),
              tripleA[2],
            ];
          }
        }

        if (i != overlappingTriples.length - 1
            && !toAddRangesThatHaveBeenMerged.contains(tripleA)
            && !toRemoveRangesThatHaveBeenMerged.contains(tripleA)) {
          toAddRangesThatHaveBeenMerged.add(tripleA);
        }
      }

      for (final List<dynamic> tripleToRemove in toRemoveRangesThatHaveBeenMerged) {
        overlappingTriples.remove(tripleToRemove);
      }

      for (final List<dynamic> tripleToAdd in toAddRangesThatHaveBeenMerged) {
        overlappingTriples.add(tripleToAdd);
      }

      List<int> endPoints = <int>[];
      for (List<dynamic> triple in overlappingTriples) {
        Set<int> ends = <int>{};
        ends.add(triple[0]);
        ends.add(triple[1]);
        endPoints.addAll(ends.toList());
      }
      endPoints.sort();
      Map<int, Set<TextStyle>> start = <int, Set<TextStyle>>{};
      Map<int, Set<TextStyle>> end = <int, Set<TextStyle>>{};

      for (final int e in endPoints) {
        start[e] = <TextStyle>{};
        end[e] = <TextStyle>{};
      }

      for (List<dynamic> triple in overlappingTriples) {
        start[triple[0]]!.add(triple[2]);
        end[triple[1]]!.add(triple[2]);
      }

      Set<TextStyle> styles = <TextStyle>{};
      List<int> otherEndPoints = endPoints.getRange(1, endPoints.length).toList();
      for (int i = 0; i < endPoints.length - 1; i++) {
        styles = styles.difference(end[endPoints[i]]!);
        styles.addAll(start[endPoints[i]]!);
        TextStyle? mergedStyles;
        final TextRange uniqueRange = TextRange(
            start: endPoints[i],
            end: otherEndPoints[i]
        );
        for (final TextStyle style in styles) {
          if (mergedStyles == null) {
            mergedStyles = style;
          } else {
            mergedStyles = mergedStyles.merge(style);
          }
        }
        rangeSpanMapping[uniqueRange] = TextSpan(
            text: uniqueRange.textInside(text),
            style: mergedStyles
        );
      }
    }

    if (!overlap) {
      rangeSpanMapping[matchedRange] =
          generator(matchedRange.textInside(text), matchedRange);
    }

    // Clean up collapsed ranges that we don't need to style.
    final List<TextRange> toRemove = <TextRange>[];

    for (final TextRange range in rangeSpanMapping.keys) {
      if (range.isCollapsed) toRemove.add(range);
    }

    for (final TextRange range in toRemove) {
      rangeSpanMapping.remove(range);
    }
  }

  void disableExpand(TextStyle style) {
    final List<TextEditingInlineSpanReplacement> toRemove = [];
    final List<TextEditingInlineSpanReplacement> toAdd = [];

    for (final TextEditingInlineSpanReplacement replacement in replacements!) {
      if (replacement.range.end == selection.start) {
        TextStyle? replacementStyle =
            (replacement.generator('', const TextRange.collapsed(0)) as TextSpan).style;
        if (replacementStyle! == style) {
          toRemove.add(replacement);
          toAdd.add(replacement.copy(expand: false));
        }
      }
    }

    for (final TextEditingInlineSpanReplacement replacementToRemove in toRemove) {
      replacements!.remove(replacementToRemove);
    }

    for (final TextEditingInlineSpanReplacement replacementWithExpandDisabled in toAdd) {
      replacements!.add(replacementWithExpandDisabled);
    }
  }

  List<TextStyle> getReplacementsAtSelection(TextSelection selection) {
    // [left replacement]|[right replacement], only left replacement should be
    // reported.
    //
    // Selection of a range of replacements should only enable the replacements
    // common to the selection. If there are no common replacements then none
    // should be enabled.
    final List<TextStyle> stylesAtSelection = <TextStyle>[];

    for (final TextEditingInlineSpanReplacement replacement in replacements!) {
      if (selection.isCollapsed) {
        if (math.max(replacement.range.start, selection.start)
            <= math.min(replacement.range.end, selection.end)) {
          if (selection.end != replacement.range.start) {
            if (selection.start == replacement.range.end) {
              if (replacement.expand) {
                stylesAtSelection.add(replacement
                    .generator('', replacement.range)
                    .style!);
              }
            } else {
              stylesAtSelection.add(replacement
                  .generator('', replacement.range)
                  .style!);
            }
          }
        }
      } else {
        if (math.max(replacement.range.start, selection.start)
            <= math.min(replacement.range.end, selection.end)) {
          if (replacement.range.start <= selection.start &&
              replacement.range.end >= selection.end) {
            stylesAtSelection.add(replacement
                .generator('', replacement.range)
                .style!);
          }
        }
      }
    }

    return stylesAtSelection;
  }

  void removeReplacementsAtRange(TextRange removalRange, TextStyle? attribute) {
    final List<TextEditingInlineSpanReplacement> toRemove = [];
    final List<TextEditingInlineSpanReplacement> toAdd = [];

    for (TextEditingInlineSpanReplacement replacement in replacements!) {
      InlineSpan replacementSpan = replacement.generator('', const TextRange.collapsed(0));
      TextStyle? replacementStyle = replacementSpan.style;

      if ((math.max(replacement.range.start, removalRange.start)
          <= math.min(replacement.range.end, removalRange.end))
          && replacementStyle != null) {
        if (replacementStyle == attribute!) {
          // if removal range encompasses entire replacement, then remove
          // replacement without splitting ranges.
          final bool removalRangeCoversReplacement = removalRange.start <= replacement.range.start
              && removalRange.end >= replacement.range.end;

          toRemove.add(replacement);

          final TextRange rangeSplitStart = TextRange(
            start: math.min(replacement.range.start, removalRange.start),
            end: math.max(replacement.range.start, removalRange.start),
          );
          final TextRange rangeSplitEnd = TextRange(
            start: math.min(replacement.range.end, removalRange.end),
            end: math.max(replacement.range.end, removalRange.end),
          );

          final bool removalRangeIsRangeSplitStart = removalRange == rangeSplitStart;
          final bool removalRangeIsRangeSplitEnd = removalRange == rangeSplitEnd;

          if (!rangeSplitStart.isCollapsed
              && !removalRangeCoversReplacement
              && !removalRangeIsRangeSplitStart) {
            toAdd.add(replacement.copy(range: rangeSplitStart, expand: !removalRange.isCollapsed));
          }

          if (!rangeSplitEnd.isCollapsed
              && !removalRangeCoversReplacement
              && !removalRangeIsRangeSplitEnd) {
            toAdd.add(replacement.copy(range: rangeSplitEnd));
          }
        }
      }
    }

    for (TextEditingInlineSpanReplacement replacementToAdd in toAdd) {
      replacements!.add(replacementToAdd);
    }

    for (TextEditingInlineSpanReplacement replacementToRemove in toRemove) {
      replacements!.remove(replacementToRemove);
    }
  }
}