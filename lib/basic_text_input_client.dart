import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

class BasicTextInputClientState extends State<BasicTextInputClient> with TextSelectionDelegate implements DeltaTextInputClient {
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

  TextSpan _buildTextSpan() {
    return widget.controller.buildTextSpan(
      context: context,
      style: widget.style,
      withComposing: true,
    );
  }

  /// [TextSelectionDelegate] method implementations.
  @override
  void bringIntoView(TextPosition position) {
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
  void userUpdateTextEditingValue(TextEditingValue value, SelectionChangedCause cause) {
    // TODO: implement userUpdateTextEditingValue
  }

  /// For TextSelection.
  final LayerLink _startHandleLayerLink = LayerLink();
  final LayerLink _endHandleLayerLink = LayerLink();

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      child: Scrollable(
        viewportBuilder: (BuildContext context, ViewportOffset position) {
          return _Editable(
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
          );
        },
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