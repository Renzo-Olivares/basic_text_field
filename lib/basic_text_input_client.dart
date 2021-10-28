import 'package:flutter/cupertino.dart';
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

  final ReplacementTextEditingController controller;

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
    implements DeltaTextInputClient {
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

  TextEditingDelta lastTextEditingDelta = TextEditingDeltaNonTextUpdate(
      oldText: '',
      selection: TextSelection.collapsed(offset: -1),
      composing: TextRange.empty);

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

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      children: <Widget>[
        const SizedBox(height: 10),
        DeltaDisplay(delta: lastTextEditingDelta),
        const SizedBox(height: 20),
        Shortcuts(
          shortcuts: <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.backspace): _MyDeleteTextIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              DeleteTextIntent: _MyDeleteTextAction(),
            },
            child: Focus(
              focusNode: widget.focusNode,
              child: GestureDetector(
                onTap: _requestKeyboard,
                onTapUp: _tapUp,
                child: Container(
                  width: 350,
                  height: 150,
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
            ),
          ),
        ),
        /*
        const SizedBox(height: 20),
        TextField(),
        */
      ],
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
    print('justin setEditingState $localValue');
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
    print('justin in app with deltas');
    TextEditingValue value = _value;

    for (final TextEditingDelta delta in textEditingDeltas) {
      lastTextEditingDelta = delta;
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

    for (final TextEditingDelta delta in textEditingDeltas) {
      print(delta.runtimeType.toString());
      widget.controller.syncReplacementRanges(delta);
    }
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

class DeltaDisplay extends StatelessWidget {
  const DeltaDisplay({required this.delta});
  final TextEditingDelta delta;

  @override
  Widget build(BuildContext context) {
    const TextStyle textStyle = TextStyle(fontWeight: FontWeight.bold);
    final TextEditingDelta lastTextEditingDelta = delta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Delta class type: ' + lastTextEditingDelta.runtimeType.toString(),
          style: textStyle,
        ),
        Text(
          'Delta old text: ' + lastTextEditingDelta.oldText,
          style: textStyle,
        ),
        if (lastTextEditingDelta is TextEditingDeltaInsertion)
          Text(
            'Delta inserted text: ' +
                (lastTextEditingDelta as TextEditingDeltaInsertion)
                    .textInserted,
            style: textStyle,
          ),
        if (lastTextEditingDelta is TextEditingDeltaInsertion)
          Text(
            'Delta insertion offset: ' +
                (lastTextEditingDelta as TextEditingDeltaInsertion)
                    .insertionOffset
                    .toString(),
            style: textStyle,
          ),
        if (lastTextEditingDelta is TextEditingDeltaDeletion)
          Text(
            'Delta deleted text: ' +
                (lastTextEditingDelta as TextEditingDeltaDeletion).textDeleted,
            style: textStyle,
          ),
        if (lastTextEditingDelta is TextEditingDeltaDeletion)
          Text(
            'Delta beginning of deleted range: ' +
                (lastTextEditingDelta as TextEditingDeltaDeletion)
                    .deletedRange
                    .start
                    .toString(),
            style: textStyle,
          ),
        if (lastTextEditingDelta is TextEditingDeltaDeletion)
          Text(
            'Delta end of deleted range: ' +
                (lastTextEditingDelta as TextEditingDeltaDeletion)
                    .deletedRange
                    .end
                    .toString(),
            style: textStyle,
          ),
        if (lastTextEditingDelta is TextEditingDeltaReplacement)
          Text(
            'Delta text being replaced: ' +
                (lastTextEditingDelta as TextEditingDeltaReplacement)
                    .textReplaced,
            style: textStyle,
          ),
        if (lastTextEditingDelta is TextEditingDeltaReplacement)
          Text(
              'Delta replacement source text: ' +
                  (lastTextEditingDelta as TextEditingDeltaReplacement)
                      .replacementText,
              style: textStyle),
        if (lastTextEditingDelta is TextEditingDeltaReplacement)
          Text(
            'Delta beginning of replaced range: ' +
                (lastTextEditingDelta as TextEditingDeltaReplacement)
                    .replacedRange
                    .start
                    .toString(),
            style: textStyle,
          ),
        if (lastTextEditingDelta is TextEditingDeltaReplacement)
          Text(
            'Delta end of replaced range: ' +
                (lastTextEditingDelta as TextEditingDeltaReplacement)
                    .replacedRange
                    .end
                    .toString(),
            style: textStyle,
          ),
        Text(
          'Delta beginning of new selection: ' +
              lastTextEditingDelta.selection.start.toString(),
          style: textStyle,
        ),
        Text(
          'Delta end of new selection: ' +
              lastTextEditingDelta.selection.end.toString(),
          style: textStyle,
        ),
        Text(
          'Delta beginning of new composing: ' +
              lastTextEditingDelta.composing.start.toString(),
          style: textStyle,
        ),
        Text(
          'Delta end of new composing: ' +
              lastTextEditingDelta.composing.start.toString(),
          style: textStyle,
        ),
      ],
    );
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
///
/// If returning a [PlaceholderSpan], the [TextRange] must be passed to the
/// [PlaceholderSpan] constructor.
typedef InlineSpanGenerator = InlineSpan Function(String, TextRange);

/// Represents one "replacement" to check for, consisting of a [TextRange] to
/// match and a generator [InlineSpanGenerator] function that creates an
/// [InlineSpan] from a matched string.
///
/// The generator function is called for every match of the range found.
///
/// Typically, the generator should return a custom [TextSpan] with unique styling
/// or a [WidgetSpan] to embed widgets within text fields.
///
/// {@tool snippet}
/// In this example, all strings enclosed in the range from 0 to 5 is matched and
/// the contents of the braces are interpreted as an image url.
///
/// ```dart
/// TextEditingInlineSpanReplacement(
///   TextRange(start: 0, end: 5),
///   (String value, TextRange range) {
///     return WidgetSpan(
///       child: Image.asset(value.substring(1, value.length - 1)),
///       range: range,
///     );
///   },
/// )
/// ```
/// {@end-tool}
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
  TextEditingInlineSpanReplacement(this.range, this.generator);

  /// The [TextRange] to replace.
  ///
  /// Matched ranges are replaced with the output of the [generator] callback.
  TextRange range;

  /// Function that returns an [InlineSpan] instance for each match of
  /// [TextRange].
  ///
  /// When returning a [PlaceholderSpan] such as [WidgetSpan], the [TextRange] argument
  /// must be provided to the [PlaceholderSpan] constructor so that the caret position
  /// can be computed properly.
  InlineSpanGenerator generator;

  /// Creates a new replacement with all properties copied except for range, which
  /// is updated to the specified value.
  TextEditingInlineSpanReplacement copy({required TextRange range}) {
    return TextEditingInlineSpanReplacement(range, this.generator);
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
    this.replacements,
    this.composingRegionReplaceable = true,
  }) : super(text: text);

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
  /// TODO: What happens when replacements match against same range of text?
  ///
  /// TODO: Give an example of replacements matching against the same range of text.
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

  /// Update replacement ranges based on information sent from a supplementary
  /// text model, that syncs asynchronously with the [TextInputClient]'s text model.
  ///
  /// On a single character insertion, the replacements that ranges fall inclusively
  /// within the range of the insertion, should be updated to take into account
  /// the insertion that happened within the replacement range. i.e. we expand
  /// the range.
  ///
  /// On a single character insertion, the replacements that ranges fall after the
  /// range of the insertion, should be updated to take into account the insertion
  /// that occured and the offset it created as a result.
  ///
  /// On a single character insertion, the replacements that ranges fall before
  /// the range of the insertion, should be skipped and not updated as their values
  /// are not offset by the insertion.
  ///
  /// TODO: Behavior when insertion is at the edges of a replacements range.
  ///
  /// On a single character deletion, the replacements that ranges fall inclusively
  /// within the range of the deletion, should be updated to take into account
  /// the deletion that happened within the replacement range. i.e. we contact the range.
  ///
  /// On a single character deletion, the replacement ranges that fall after the
  /// ranges of deletion, should be updated to take into account the deletion
  /// that occured and the offset it created as a result.
  ///
  /// On a single character deletion, the replacement ranges that fall before the
  /// ranges of deletion, should be skipped and not updated as their values are
  /// not offset by the deletion.
  ///
  /// TODO: Behavior when deletion is at edges of a replacements range.
  void syncReplacementRanges(TextEditingDelta delta) {
    if (replacements != null) {
      print('syncing ranges');
      print(replacements!.length.toString());
      if (text.isEmpty) {
        replacements!.clear();
      }
      List<TextEditingInlineSpanReplacement> updatedReplacements = [];

      for (final TextEditingInlineSpanReplacement replacement
          in replacements!) {
        if (delta is TextEditingDeltaInsertion) {
          print('syncing insertion');
          print(delta.textInserted);
          if (delta.insertionOffset > replacement.range.start &&
              delta.insertionOffset < replacement.range.end) {
            // Update range that falls inclusively inside the diff range.
            print('updating inclusive range on insertion');
            updatedReplacements.add(
              replacement.copy(
                range: TextRange(
                  start: replacement.range.start,
                  end: replacement.range.end + 1,
                ),
              ),
            );
          } else if (delta.insertionOffset > replacement.range.end &&
              delta.insertionOffset > replacement.range.end) {
            print('updating replacements that happened before insertion');
            updatedReplacements.add(replacement);
            // print(replacement);
          } else if (delta.insertionOffset < replacement.range.start) {
            // Update ranges that falls after the diff range.
            print('updating replacements that happened after insertion');
            print('not sure about this case');
            updatedReplacements.add(
              replacement.copy(
                range: TextRange(
                  start: replacement.range.start + delta.textInserted.length,
                  end: replacement.range.end + delta.textInserted.length,
                ),
              ),
            );
          } else if (delta.insertionOffset == replacement.range.start || delta.insertionOffset == replacement.range.end) {
            if (delta.insertionOffset == replacement.range.start) {
              // Inserting at the beginning of a replacement.
              updatedReplacements.add(
                replacement.copy(
                  range: TextRange(
                    start: replacement.range.start + delta.textInserted.length,
                    end: replacement.range.end + delta.textInserted.length,
                  ),
                ),
              );
            } else if (delta.insertionOffset == replacement.range.end) {
              // Inserting at end of a replacement.
              updatedReplacements.add(replacement);
            }
          }
        } else if (delta is TextEditingDeltaDeletion) {
          print('syncing deletion');
          if (delta.deletedRange.start >= replacement.range.start &&
              delta.deletedRange.end <= replacement.range.end) {
            // Update replacement ranges directly inclusively associated with deleted range.
            print('updating inclusive ranges of deletion');
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
              print('start = end on deletion so remove attribute');
            }
          } else if (delta.deletedRange.start > replacement.range.end &&
              delta.deletedRange.end > replacement.range.end) {
            // If range happened before deletion, skip updating it.
            print(
                'updating replacement ranges that happened before the deletion.');
            updatedReplacements.add(replacement);
          } else if (delta.deletedRange.end < replacement.range.start) {
            // If deletion happened before range of current attribute, update it.
            print(
                'updating replacement ranges that happened after the deletion.');
            updatedReplacements.add(
              replacement.copy(
                range: TextRange(
                  start: replacement.range.start - delta.textDeleted.length,
                  end: replacement.range.end - delta.textDeleted.length,
                ),
              ),
            );
          } else if (delta.deletedRange.start == replacement.range.start ||
              delta.deletedRange.start == replacement.range.end ||
              delta.deletedRange.end == replacement.range.start ||
              delta.deletedRange.end == replacement.range.end) {
            print('updating ranges that are touching the deletion');

            // If the replacement is a textspan, then merge the attributes and ranges into one.
            // If they are of different type then, simply don't update them.
            if (delta.deletedRange.start == replacement.range.end || delta.deletedRange.end == replacement.range.end) {
              // The deleted range is touching the end of the replacement.
              updatedReplacements.add(replacement);
            } else if (delta.deletedRange.start == replacement.range.start || delta.deletedRange.end == replacement.range.start) {
              // The deleted range is touching the beginning of the replacement.
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
          if (delta.replacedRange.start > replacement.range.start &&
              delta.replacedRange.end < replacement.range.end) {
            // Update range that falls inclusively inside the diff range.
            print('updating inclusive range on replacement');
            updatedReplacements.add(
              replacement.copy(
                range: TextRange(
                  start: replacement.range.start,
                  end: replacement.range.end + 1,
                ),
              ),
            );
          } else if (delta.replacedRange.end > replacement.range.end &&
              delta.replacedRange.start > replacement.range.end) {
            print('updating replacements that happened before replacement');
            updatedReplacements.add(replacement);
            // print(replacement);
          } else if (delta.replacedRange.start < replacement.range.start) {
            // Update ranges that falls after the diff range.
            print('updating replacements that happened after replacement');
            print('not sure about this case');
            updatedReplacements.add(
              replacement.copy(
                range: TextRange(
                  start: replacement.range.start + delta.replacementText.length,
                  end: replacement.range.end + delta.replacementText.length,
                ),
              ),
            );
          }
        } else if (delta is TextEditingDeltaNonTextUpdate) {
          print('sync non text update');
        }
      }

      if (updatedReplacements.isNotEmpty) {
        replacements!.clear();
        replacements!.addAll(updatedReplacements);
      }
    }
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    assert(!value.composing.isValid ||
        !withComposing ||
        value.isComposingRangeValid);

    print('beginning');
    print(replacements!.length);

    // Keep a mapping of TextRanges to the InlineSpan to replace it with.
    final Map<TextRange, InlineSpan> rangeSpanMapping =
        <TextRange, InlineSpan>{};

    // If the composing range is out of range for the current text, ignore it to
    // preserve the tree integrity, otherwise in release mode a RangeError will
    // be thrown and this EditableText will be built with a broken subtree.
    //
    // Add composing region as a replacement to a TextSpan with underline.
    if (!composingRegionReplaceable &&
        value.isComposingRangeValid &&
        withComposing) {
      print('heh');
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
    print('whot');
    // Iterate through TextEditingInlineSpanReplacements, handling overlapping
    // replacements and mapping them towards a generated InlineSpan.
    if (replacements != null) {
      print('replacements not null');
      for (final TextEditingInlineSpanReplacement replacement
          in replacements!) {
        _addToMappingWithOverlaps(
            replacement.generator,
            TextRange(
                start: replacement.range.start, end: replacement.range.end),
            rangeSpanMapping,
            value.text);
      }
    } else {
      print('replacements is null');
    }
    print('lmao');
    // If the composing range is out of range for the current text, ignore it to
    // preserve the tree integrity, otherwise in release mode a RangeError will
    // be thrown and this EditableText will be built with a broken subtree.
    //
    // Add composing region as a replacement to a TextSpan with underline.
    if (composingRegionReplaceable &&
        value.isComposingRangeValid &&
        withComposing) {
      print('guess we in here');
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
    print('uhhhh');
    // Sort the matches by start index. Since no overlapping exists, this is safe.
    final List<TextRange> sortedRanges = rangeSpanMapping.keys.toList();
    sortedRanges.sort((TextRange a, TextRange b) => a.start.compareTo(b.start));
    // Create TextSpans for non-replaced text ranges and insert the replacements spans
    // for any ranges that are marked to be replaced.
    final List<InlineSpan> spans = <InlineSpan>[];
    int previousEndIndex = 0;
    for (final TextRange range in sortedRanges) {
      if (range.start > previousEndIndex) {
        spans.add(TextSpan(
            text: value.text.substring(previousEndIndex, range.start)));
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
    for (final TextRange range in rangeSpanMapping.keys) {
      // Check if we have overlapping replacements.
      if (matchedRange.start >= range.start && matchedRange.start < range.end ||
          matchedRange.end > range.start && matchedRange.end <= range.end ||
          matchedRange.start < range.start && matchedRange.end > range.end) {
        overlap = true;
        break;
      }
    }

    if (overlap) {
      print('there is an overlap');
      InlineSpan? generatedReplacement =
          generator(matchedRange.textInside(text), matchedRange);
      InlineSpan? previousGeneratedReplacement = rangeSpanMapping[matchedRange];

      if (previousGeneratedReplacement is TextSpan &&
          generatedReplacement is TextSpan) {
        TextSpan? generatedReplacementTextSpan =
            (generatedReplacement as TextSpan);
        TextSpan? previousGeneratedReplacementTextSpan =
            (previousGeneratedReplacement as TextSpan);
        TextStyle? genRepStyle = generatedReplacementTextSpan.style;
        TextStyle? prevRepStyle = previousGeneratedReplacementTextSpan.style;
        String? text = generatedReplacementTextSpan.text;

        print('the overlap is of textspans...attempting to merge the styles');

        if (text != null && genRepStyle != null && prevRepStyle != null) {
          final TextStyle mergedReplacementStyle =
              genRepStyle.merge(prevRepStyle);
          rangeSpanMapping[matchedRange] =
              TextSpan(text: text, style: mergedReplacementStyle);
        }
      }
    }

    if (!overlap) {
      rangeSpanMapping[matchedRange] =
          generator(matchedRange.textInside(text), matchedRange);
    }
  }
}

class _MyDeleteTextIntent extends Intent {
  const _MyDeleteTextIntent();
}

class _MyDeleteTextAction extends ContextAction<DeleteTextIntent> {
  @override
  Object? invoke(DeleteTextIntent intent, [BuildContext? context]) {
    print('justin delete!');
    //textEditingActionTarget!.delete(SelectionChangedCause.keyboard);
  }
}
