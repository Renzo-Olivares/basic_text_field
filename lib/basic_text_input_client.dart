import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

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
  }) : super(key: key);

  final TextEditingController controller;
  final TextStyle style;
  final FocusNode focusNode;
  final TextSelectionControls? selectionControls;
  final bool showSelectionHandles;
  final SelectionChangedCallback onSelectionChanged;

  @override
  State<BasicTextInputClient> createState() => BasicTextInputClientState();
}

class BasicTextInputClientState extends State<BasicTextInputClient> with TextSelectionDelegate implements DeltaTextInputClient {
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
    // TODO: implement connectionClosed
  }

  @override
  // TODO: implement currentAutofillScope
  // Will not implement.
  AutofillScope? get currentAutofillScope => throw UnimplementedError();

  @override
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
  bool showToolbar() {
    // On the web use provided native dom elements to provide clipboard functionality.
    if (kIsWeb) {
      return false;
    }

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

    userUpdateTextEditingValue(value, cause);
  }

  /// Keyboard text editing actions.
  // TODO(justinmc): Handling of the default text editing shortcuts with deltas
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
    ExtendSelectionByCharacterIntent: _UpdateTextSelectionAction<ExtendSelectionByCharacterIntent>(this, false, _characterBoundary,),
    UpdateSelectionIntent: _updateSelectionAction,
  };
  late final Action<UpdateSelectionIntent> _updateSelectionAction = CallbackAction<UpdateSelectionIntent>(onInvoke: _updateSelection);

  void _updateSelection(UpdateSelectionIntent intent) {
    _userUpdateTextEditingValueWithDelta(
      TextEditingDeltaNonTextUpdate(
        oldText: _value.text,
        selection: intent.newSelection,
        composing: _value.composing,
      ),
      SelectionChangedCause.keyboard,
    );
  }

  _TextBoundary _characterBoundary(DirectionalTextEditingIntent intent) {
    final _TextBoundary atomicTextBoundary = _CharacterBoundary(_value);
    return _CollapsedSelectionBoundary(atomicTextBoundary, intent.forward);
  }

  void _delete() {
    if (_value.text.isEmpty) {
      return;
    }

    late final TextRange deletedRange;
    if (_selection.isCollapsed) {
      if (_selection.baseOffset == 0) {
        return;
      }
      final int deletedLength = _value.text.substring(0, _selection.baseOffset).characters.last.length;
      deletedRange = TextRange(
        start: _selection.baseOffset - deletedLength,
        end: _selection.baseOffset,
      );
    } else {
      deletedRange = _selection;
    }

    _userUpdateTextEditingValueWithDelta(
      TextEditingDeltaDeletion(
        oldText: _value.text,
        selection: TextSelection.collapsed(offset: deletedRange.start),
        composing: TextRange.collapsed(deletedRange.start),
        deletedRange: deletedRange,
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
    if (_lastKnownRemoteTextEditingValue == _value) {
      return;
    }

    if (_textInputConnection != null) {
      _textInputConnection!.setEditingState(_value);
      _lastKnownRemoteTextEditingValue = _value;
    }
  }

  /// [TextSelectionDelegate] method implementations.
  @override
  void bringIntoView(TextPosition position) {
    // TODO: implement bringIntoView
  }

  @override
  void copySelection(SelectionChangedCause cause) {
    final TextSelection copyRange = textEditingValue.selection;
    if (!copyRange.isValid || copyRange.isCollapsed) {
      return;
    }
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

    if (cutRange.isCollapsed) {
      return;
    }
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
    if (cause == SelectionChangedCause.toolbar) {
      hideToolbar();
    }
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
    if (!pasteRange.isValid) {
      return;
    }

    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null) {
      return;
    }

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

    if (cause == SelectionChangedCause.toolbar) {
      hideToolbar();
    }
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
    if (value == _value) {
      return;
    }

    final bool selectionChanged = _value.selection != value.selection;

    if (cause == SelectionChangedCause.drag || cause == SelectionChangedCause.longPress) {
      // Here the change is coming from gestures which call on RenderEditable to change the selection.
      // TODO: Should we create a delta and apply it here instead of just setting the value?
    }

    _value = value;

    if (selectionChanged) {
      _handleSelectionChanged(_value.selection, cause);
    }
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
    if (!widget.controller.isSelectionWithinTextBounds(selection))
      return;

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

  @override
  Widget build(BuildContext context) {
    return Actions(
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
                backgroundCursorColor: Colors.grey[100], // TODO: document.
                showCursor: ValueNotifier<bool>(true),
                forceLine: true, // Whether text field will take full line regardless of width.
                readOnly: false, // editable text-field.
                hasFocus: _hasFocus,
                maxLines: null, // multi-line text-field.
                minLines: null,
                expands: false, // expands to height of parent.
                strutStyle: null, // TODO: document.
                selectionColor: Colors.blue.withOpacity(0.40),
                textScaleFactor: MediaQuery.textScaleFactorOf(context), // TODO: document.
                textAlign: TextAlign.left, // TODO: make variable.
                textDirection: _textDirection,
                locale: Localizations.maybeLocaleOf(context), // TODO: document.
                textHeightBehavior: DefaultTextHeightBehavior.of(context), // TODO: make variable.
                textWidthBasis: TextWidthBasis.parent, // TODO: document.
                obscuringCharacter: '•',
                obscureText: false, // This is a non-private text field that does not require obfuscation.
                offset: position,
                onCaretChanged: null, // TODO: implement.
                rendererIgnoresPointer: true, // TODO: document.
                cursorWidth: 2.0,
                cursorHeight: null,
                cursorRadius: const Radius.circular(2.0),
                cursorOffset: Offset.zero,
                paintCursorAboveText: false, // TODO: document.
                enableInteractiveSelection: true, // make true to enable selection on mobile.
                textSelectionDelegate: this,
                devicePixelRatio: MediaQuery.of(context).devicePixelRatio, // TODO: document.
                promptRectRange: null, // TODO: document.
                promptRectColor: null, // TODO: document.
                clipBehavior: Clip.hardEdge, // TODO: document.
              ),
            );
          },
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
class _UpdateTextSelectionAction<T extends DirectionalCaretMovementIntent> extends ContextAction<T> {
  _UpdateTextSelectionAction(
      this.state,
      this.ignoreNonCollapsedSelection,
      this.getTextBoundariesForIntent,
      );

  final BasicTextInputClientState state;
  final bool ignoreNonCollapsedSelection;
  final _TextBoundary Function(T intent) getTextBoundariesForIntent;

  static const int NEWLINE_CODE_UNIT = 10;

  // Returns true iff the given position is at a wordwrap boundary in the
  // upstream position.
  bool _isAtWordwrapUpstream(TextPosition position) {
    final TextPosition end = TextPosition(
      offset: state.renderEditable.getLineAtOffset(position).end,
      affinity: TextAffinity.upstream,
    );
    return end == position && end.offset != state.textEditingValue.text.length
        && state.textEditingValue.text.codeUnitAt(position.offset) != NEWLINE_CODE_UNIT;
  }

  // Returns true iff the given position at a wordwrap boundary in the
  // downstream position.
  bool _isAtWordwrapDownstream(TextPosition position) {
    final TextPosition start = TextPosition(
      offset: state.renderEditable.getLineAtOffset(position).start,
    );
    return start == position && start.offset != 0
        && state.textEditingValue.text.codeUnitAt(position.offset - 1) != NEWLINE_CODE_UNIT;
  }

  @override
  Object? invoke(T intent, [BuildContext? context]) {
    final TextSelection selection = state._value.selection;
    assert(selection.isValid);

    final bool collapseSelection = intent.collapseSelection; //|| !state.widget.selectionEnabled;
    // Collapse to the logical start/end.
    TextSelection _collapse(TextSelection selection) {
      assert(selection.isValid);
      assert(!selection.isCollapsed);
      return selection.copyWith(
        baseOffset: intent.forward ? selection.end : selection.start,
        extentOffset: intent.forward ? selection.end : selection.start,
      );
    }

    if (!selection.isCollapsed && !ignoreNonCollapsedSelection && collapseSelection) {
      return Actions.invoke(
        context!,
        UpdateSelectionIntent(state._value, _collapse(selection), SelectionChangedCause.keyboard),
      );
    }

    final _TextBoundary textBoundary = getTextBoundariesForIntent(intent);
    final TextSelection textBoundarySelection = textBoundary.textEditingValue.selection;
    if (!textBoundarySelection.isValid) {
      return null;
    }
    if (!textBoundarySelection.isCollapsed && !ignoreNonCollapsedSelection && collapseSelection) {
      return Actions.invoke(
        context!,
        UpdateSelectionIntent(state._value, _collapse(textBoundarySelection), SelectionChangedCause.keyboard),
      );
    }

    TextPosition extent = textBoundarySelection.extent;

    // If continuesAtWrap is true extent and is at the relevant wordwrap, then
    // move it just to the other side of the wordwrap.
    if (intent.continuesAtWrap) {
      if (intent.forward && _isAtWordwrapUpstream(extent)) {
        extent = TextPosition(
          offset: extent.offset,
        );
      } else if (!intent.forward && _isAtWordwrapDownstream(extent)) {
        extent = TextPosition(
          offset: extent.offset,
          affinity: TextAffinity.upstream,
        );
      }
    }

    final TextPosition newExtent = intent.forward
        ? textBoundary.getTrailingTextBoundaryAt(extent)
        : textBoundary.getLeadingTextBoundaryAt(extent);

    final TextSelection newSelection = collapseSelection
        ? TextSelection.fromPosition(newExtent)
        : textBoundarySelection.extendTo(newExtent);

    // If collapseAtReversal is true and would have an effect, collapse it.
    if (!selection.isCollapsed && intent.collapseAtReversal
        && (selection.baseOffset < selection.extentOffset !=
            newSelection.baseOffset < newSelection.extentOffset)) {
      return Actions.invoke(
        context!,
        UpdateSelectionIntent(
          state._value,
          TextSelection.fromPosition(selection.base),
          SelectionChangedCause.keyboard,
        ),
      );
    }

    return Actions.invoke(
      context!,
      UpdateSelectionIntent(textBoundary.textEditingValue, newSelection, SelectionChangedCause.keyboard),
    );
  }

  @override
  bool get isActionEnabled => state._value.selection.isValid;
}

/// An interface for retriving the logical text boundary (left-closed-right-open)
/// at a given location in a document.
///
/// Depending on the implementation of the [_TextBoundary], the input
/// [TextPosition] can either point to a code unit, or a position between 2 code
/// units (which can be visually represented by the caret if the selection were
/// to collapse to that position).
///
/// For example, [_LineBreak] interprets the input [TextPosition] as a caret
/// location, since in Flutter the caret is generally painted between the
/// character the [TextPosition] points to and its previous character, and
/// [_LineBreak] cares about the affinity of the input [TextPosition]. Most
/// other text boundaries however, interpret the input [TextPosition] as the
/// location of a code unit in the document, since it's easier to reason about
/// the text boundary given a code unit in the text.
///
/// To convert a "code-unit-based" [_TextBoundary] to "caret-location-based",
/// use the [_CollapsedSelectionBoundary] combinator.
abstract class _TextBoundary {
  const _TextBoundary();

  TextEditingValue get textEditingValue;

  /// Returns the leading text boundary at the given location, inclusive.
  TextPosition getLeadingTextBoundaryAt(TextPosition position);

  /// Returns the trailing text boundary at the given location, exclusive.
  TextPosition getTrailingTextBoundaryAt(TextPosition position);

  TextRange getTextBoundaryAt(TextPosition position) {
    return TextRange(
      start: getLeadingTextBoundaryAt(position).offset,
      end: getTrailingTextBoundaryAt(position).offset,
    );
  }
}

// Most apps delete the entire grapheme when the backspace key is pressed.
// Also always put the new caret location to character boundaries to avoid
// sending malformed UTF-16 code units to the paragraph builder.
class _CharacterBoundary extends _TextBoundary {
  const _CharacterBoundary(this.textEditingValue);

  @override
  final TextEditingValue textEditingValue;

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) {
    final int endOffset = math.min(position.offset + 1, textEditingValue.text.length);
    return TextPosition(
      offset: CharacterRange.at(textEditingValue.text, position.offset, endOffset).stringBeforeLength,
    );
  }

  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) {
    final int endOffset = math.min(position.offset + 1, textEditingValue.text.length);
    final CharacterRange range = CharacterRange.at(textEditingValue.text, position.offset, endOffset);
    return TextPosition(
      offset: textEditingValue.text.length - range.stringAfterLength,
    );
  }

  @override
  TextRange getTextBoundaryAt(TextPosition position) {
    final int endOffset = math.min(position.offset + 1, textEditingValue.text.length);
    final CharacterRange range = CharacterRange.at(textEditingValue.text, position.offset, endOffset);
    return TextRange(
      start: range.stringBeforeLength,
      end: textEditingValue.text.length - range.stringAfterLength,
    );
  }
}

// Force the innerTextBoundary to interpret the input [TextPosition]s as caret
// locations instead of code unit positions.
//
// The innerTextBoundary must be a [_TextBoundary] that interprets the input
// [TextPosition]s as code unit positions.
class _CollapsedSelectionBoundary extends _TextBoundary {
  _CollapsedSelectionBoundary(this.innerTextBoundary, this.isForward);

  final _TextBoundary innerTextBoundary;
  final bool isForward;

  @override
  TextEditingValue get textEditingValue => innerTextBoundary.textEditingValue;

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) {
    return isForward
        ? innerTextBoundary.getLeadingTextBoundaryAt(position)
        : position.offset <= 0 ? const TextPosition(offset: 0) : innerTextBoundary.getLeadingTextBoundaryAt(TextPosition(offset: position.offset - 1));
  }

  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) {
    return isForward
        ? innerTextBoundary.getTrailingTextBoundaryAt(position)
        : position.offset <= 0 ? const TextPosition(offset: 0) : innerTextBoundary.getTrailingTextBoundaryAt(TextPosition(offset: position.offset - 1));
  }
}