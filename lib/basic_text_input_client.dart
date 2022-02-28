import 'dart:ui' as ui hide TextStyle;

import 'package:basic_text_input_client_sample/replacement_text_editing_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class BasicTextInputClient extends StatefulWidget {
  BasicTextInputClient({
    Key? key,
    TextInputType? keyboardType,
    required this.controller,
    required this.style,
    required this.focusNode,
    required this.textAlign,
    this.textDirection,
    this.textInputAction,
    this.maxLines = 1,
  })  : keyboardType = keyboardType ?? _inferKeyboardType(maxLines: maxLines),
        super(key: key);

  final TextEditingController controller;

  final TextStyle style;

  final FocusNode focusNode;

  final TextAlign textAlign;

  final TextDirection? textDirection;

  final TextInputAction? textInputAction;

  final TextInputType keyboardType;

  final int? maxLines;

  // Infer the keyboard type of an `EditableText` if it's not specified.
  static TextInputType _inferKeyboardType({
    required int? maxLines,
  }) {
    if (maxLines == null) {
      return TextInputType.multiline;
    }
    return maxLines == 1 ? TextInputType.text : TextInputType.multiline;
  }

  @override
  BasicTextInputClientState createState() => BasicTextInputClientState();
}

class BasicTextInputClientState extends State<BasicTextInputClient>
    with TextSelectionDelegate
    implements DeltaTextInputClient {
  final GlobalKey _editableKey = GlobalKey();

  /// TODO: Better documentation.
  ///
  /// For text selection overlay.
  final LayerLink _startHandleLayerLink = LayerLink();
  final LayerLink _endHandleLayerLink = LayerLink();

  /// The renderer for this widget's descendant.
  ///
  /// This property is typically used to notify the renderer of input gestures
  /// when [RenderEditable.ignorePointer] is true.
  RenderEditable get renderEditable => _editableKey.currentContext!.findRenderObject()! as RenderEditable;

  /// TODO: Better documentation.
  ///
  /// For text field focus.
  FocusAttachment? _focusAttachment;
  bool get _hasFocus => widget.focusNode.hasFocus;

  TextEditingValue get _value => widget.controller.value;
  set _value(TextEditingValue value) {
    widget.controller.value = value;
  }

  bool get _isMultiline => widget.maxLines != 1;

  /// TODO: Better documentation.
  ///
  /// For text input client connection.
  TextInputConnection? _textInputConnection;
  TextEditingValue? _lastKnownRemoteTextEditingValue;
  bool get _hasInputConnection => _textInputConnection?.attached ?? false;

  @override
  void initState() {
    super.initState();
    _focusAttachment = widget.focusNode.attach(context);
    widget.focusNode.addListener(_handleFocusChanged);
    widget.controller.addListener(_didChangeTextEditingValue);
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

  /// Express interest in interacting with the keyboard.
  ///
  /// If this control is already attached to the keyboard, this function will
  /// request that the keyboard become visible. Otherwise, this function will
  /// ask the focus system that it become focused. If successful in acquiring
  /// focus, the control will then attach to the keyboard and request that the
  /// keyboard become visible.
  void requestKeyboard() {
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
          inputType: widget.keyboardType,
          enableDeltaModel: true,
          inputAction: widget.textInputAction ?? (widget.keyboardType == TextInputType.multiline
                  ? TextInputAction.newline
                  : TextInputAction.done
              ),
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
    final TextDirection result = widget.textDirection ?? Directionality.of(context);
    assert(result != null, '$runtimeType created without a textDirection and with no ambient Directionality.');
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
        if (!_isMultiline) {
          _finalizeEditing(action, shouldUnfocus: true);
        }
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

    if (widget.controller is ReplacementTextEditingController) {
      for (final TextEditingDelta delta in textEditingDeltas) {
        (widget.controller as ReplacementTextEditingController).syncReplacementRanges(delta);
      }
    }
  }

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {
    // TODO: implement updateFloatingCursor
  }

  @override
  void bringIntoView(ui.TextPosition position) {
    // TODO: implement bringIntoView
  }

  @override
  void copySelection(SelectionChangedCause cause) {
    // TODO: implement copySelection
  }

  @override
  void cutSelection(SelectionChangedCause cause) {
    // TODO: implement cutSelection
  }

  @override
  void hideToolbar([bool hideHandles = true]) {
    // TODO: implement hideToolbar
  }

  @override
  Future<void> pasteText(SelectionChangedCause cause) {
    // TODO: implement pasteText
    throw UnimplementedError();
  }

  @override
  void selectAll(SelectionChangedCause cause) {
    // TODO: implement selectAll
  }

  @override
  // TODO: implement textEditingValue
  TextEditingValue get textEditingValue => _value;

  @override
  void userUpdateTextEditingValue(
      TextEditingValue value, SelectionChangedCause cause) {
    // TODO: implement userUpdateTextEditingValue
  }

  TextSpan buildTextSpan() {
    return widget.controller.buildTextSpan(
      context: context,
      style: widget.style,
      withComposing: _hasFocus,
    );
  }

  @override
  Widget build(BuildContext context) {
    _focusAttachment!.reparent();

    return Focus(
      focusNode: widget.focusNode,
      child: Scrollable(
        viewportBuilder: (BuildContext context, ViewportOffset position) {
          return _Editable(
            key: _editableKey,
            inlineSpan: buildTextSpan(),
            value: _value,
            startHandleLayerLink: _startHandleLayerLink,
            endHandleLayerLink: _endHandleLayerLink,
            showCursor: ValueNotifier<bool>(true),
            forceLine: true,
            readOnly: false,
            textWidthBasis: TextWidthBasis.parent,
            hasFocus: _hasFocus,
            maxLines: widget.maxLines,
            expands: false,
            textScaleFactor: MediaQuery.textScaleFactorOf(context),
            textAlign: TextAlign.start,
            textDirection: _textDirection,
            obscuringCharacter: '•',
            obscureText: false,
            autocorrect: true,
            selectionColor: Colors.blue.withOpacity(0.40),
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            enableSuggestions: true,
            offset: position,
            cursorColor: Colors.blue,
            cursorRadius: const Radius.circular(2.0),
            cursorWidth: 2.0,
            cursorOffset: Offset.zero, //check
            paintCursorAboveText: false,
            textSelectionDelegate: this,
            devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
            clipBehavior: Clip.hardEdge,
          );
        },
      ),
    );
  }

  @override
  void insertTextPlaceholder(ui.Size size) {
    // TODO: implement insertTextPlaceholder
  }

  @override
  void removeTextPlaceholder() {
    // TODO: implement removeTextPlaceholder
  }

  @override
  void showToolbar() {
    // TODO: implement showToolbar
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
    required this.autocorrect,
    required this.smartDashesType,
    required this.smartQuotesType,
    required this.enableSuggestions,
    required this.offset,
    this.onCaretChanged,
    this.rendererIgnoresPointer = false,
    required this.cursorWidth,
    this.cursorHeight,
    this.cursorRadius,
    required this.cursorOffset,
    required this.paintCursorAboveText,
    this.selectionHeightStyle = ui.BoxHeightStyle.tight,
    this.selectionWidthStyle = ui.BoxWidthStyle.tight,
    this.enableInteractiveSelection = true,
    required this.textSelectionDelegate,
    required this.devicePixelRatio,
    this.promptRectRange,
    this.promptRectColor,
    required this.clipBehavior,
  })  : assert(textDirection != null),
        assert(rendererIgnoresPointer != null),
        super(key: key, children: _extractChildren(inlineSpan));

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
  final bool autocorrect;
  final SmartDashesType smartDashesType;
  final SmartQuotesType smartQuotesType;
  final bool enableSuggestions;
  final ViewportOffset offset;
  final CaretChangedHandler? onCaretChanged;
  final bool rendererIgnoresPointer;
  final double cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final Offset cursorOffset;
  final bool paintCursorAboveText;
  final ui.BoxHeightStyle selectionHeightStyle;
  final ui.BoxWidthStyle selectionWidthStyle;
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
      selectionHeightStyle: selectionHeightStyle,
      selectionWidthStyle: selectionWidthStyle,
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
      ..selectionHeightStyle = selectionHeightStyle
      ..selectionWidthStyle = selectionWidthStyle
      ..enableInteractiveSelection = enableInteractiveSelection
      ..textSelectionDelegate = textSelectionDelegate
      ..devicePixelRatio = devicePixelRatio
      ..paintCursorAboveText = paintCursorAboveText
      ..promptRectColor = promptRectColor
      ..clipBehavior = clipBehavior
      ..setPromptRectRange(promptRectRange);
  }
}
