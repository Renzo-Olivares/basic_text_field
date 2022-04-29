import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

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

    print(replacements!.length);

    List<TextEditingInlineSpanReplacement> updatedReplacements = [];
    List<TextEditingInlineSpanReplacement> toRemove = [];

    for (final TextEditingInlineSpanReplacement replacement
    in replacements!) {
      print('syncing replacements currently at $replacement');
      // Syncing insertions.
      if (delta is TextEditingDeltaInsertion) {
        if (delta.insertionOffset == replacement.range.end
            && delta.insertionOffset == replacement.range.start) {
          print('replacement collapsed');
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
            print('insertion front edge');
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
            print('insertion back edge');
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
            // replacements!.remove(replacement);
            print('remove $replacement');
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
            print('back edge hit at delta deleted range ${delta.deletedRange} and replacement range ${replacement.range}');
            if (delta.deletedRange.start == replacement.range.end) {
              print('interestingggggg');
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
                print('not expanded $replacement');
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
      print('----------------------------------------------------------------------');
      print('iterating through replacements to handle overlapping replacements');
      for (final TextEditingInlineSpanReplacement replacement in replacements!) {
        print('checking $replacement overlaps');
        _addToMappingWithOverlaps(
            replacement.generator,
            TextRange(start: replacement.range.start, end: replacement.range.end),
            rangeSpanMapping,
            value.text,
        );
      }
      print('end of replacement overlaps check');
      print('----------------------------------------------------------------------');
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
    print('add to mapping with overlaps');
    for (final TextRange range in rangeSpanMapping.keys) {
      print('comparing against range $range');
      if (math.max(matchedRange.start, range.start)
          <= math.min(matchedRange.end, range.end)) {
        print('overlap found $matchedRange and $range');
        overlap = true;
        overlapRanges.add(range);
      }
    }

    print('number of overlapping ranges' + overlapRanges.length.toString());
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
        final List<dynamic> tripleA = overlappingTriples[i];
        for (int j = i + 1; j < overlappingTriples.length; j++) {
          final List<dynamic> tripleB = overlappingTriples[j];
          if (math.max(tripleA[0] as int, tripleB[0] as int)
              <= math.min(tripleB[1] as int, tripleB[1] as int)
              && tripleA[2] == tripleB[2]) {
            final List<dynamic> mergedRange = [
              math.min(tripleA[0] as int, tripleB[0] as int),
              math.max(tripleA[1] as int, tripleB[1] as int),
              tripleA[2],
            ];
            toRemoveRangesThatHaveBeenMerged.addAll([tripleA, tripleB]);
            toAddRangesThatHaveBeenMerged.add(mergedRange);
          }
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
        final TextRange uniqueRange = TextRange(start: endPoints[i], end: otherEndPoints[i]);
        for (final TextStyle style in styles) {
          if (mergedStyles == null) {
            mergedStyles = style;
          } else {
            mergedStyles = mergedStyles.merge(style);
          }
        }
        print('$uniqueRange and $mergedStyles');
        rangeSpanMapping[uniqueRange] = TextSpan(text: uniqueRange.textInside(text), style: mergedStyles);
      }
    }

    // if (overlap) {
    //   print('handling overlap');
    //   InlineSpan? generatedReplacement =
    //   generator(matchedRange.textInside(text), matchedRange);
    //   InlineSpan? previousGeneratedReplacement = rangeSpanMapping[matchedRange];
    //
    //   if (previousGeneratedReplacement is TextSpan &&
    //       generatedReplacement is TextSpan) {
    //     TextSpan? generatedReplacementTextSpan =
    //     generatedReplacement;
    //     TextSpan? previousGeneratedReplacementTextSpan =
    //     previousGeneratedReplacement;
    //     TextStyle? genRepStyle = generatedReplacementTextSpan.style;
    //     TextStyle? prevRepStyle = previousGeneratedReplacementTextSpan.style;
    //     String? text = generatedReplacementTextSpan.text;
    //
    //     if (text != null && genRepStyle != null && prevRepStyle != null) {
    //       final TextStyle mergedReplacementStyle =
    //       genRepStyle.merge(prevRepStyle);
    //       rangeSpanMapping[matchedRange] =
    //           TextSpan(text: text, style: mergedReplacementStyle);
    //     }
    //   }
    // }

    if (!overlap) {
      print('no overlaps matchedRange $matchedRange, and current text $text and text length ${text.length}');
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

    print(rangeSpanMapping);
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
    print('removing replacements at range starting ---------------------------------');
    final List<TextEditingInlineSpanReplacement> toRemove = [];
    final List<TextEditingInlineSpanReplacement> toAdd = [];

    for (TextEditingInlineSpanReplacement replacement in replacements!) {
      InlineSpan replacementSpan = replacement.generator('', const TextRange.collapsed(0));
      TextStyle? replacementStyle = replacementSpan.style;

      if ((math.max(replacement.range.start, removalRange.start)
          <= math.min(replacement.range.end, removalRange.end))
          && replacementStyle != null) {
        if (replacementStyle == attribute!) {
          toRemove.add(replacement);

          final TextRange rangeSplitStart = TextRange(
              start: math.min(replacement.range.start, removalRange.start),
              end: math.max(replacement.range.start, removalRange.start),
          );
          final TextRange rangeSplitEnd = TextRange(
              start: math.min(replacement.range.end, removalRange.end),
              end: math.max(replacement.range.end, removalRange.end),
          );

          if (!rangeSplitStart.isCollapsed) {
            print('Adding replacement at rangeSplitStart $rangeSplitStart when removal range $removalRange overlaps with ${replacement.range}');
            toAdd.add(replacement.copy(range: rangeSplitStart, expand: !removalRange.isCollapsed));
          }

          if (!rangeSplitEnd.isCollapsed) {
            print('Adding replacement at rangeSplitEnd $rangeSplitEnd when removal range $removalRange overlaps with ${replacement.range}');
            toAdd.add(replacement.copy(range: rangeSplitEnd));
          }
        }
      }
    }

    for (TextEditingInlineSpanReplacement replacementToAdd in toAdd) {
      print('replacement being added $replacementToAdd');
      replacements!.add(replacementToAdd);
    }

    for (TextEditingInlineSpanReplacement replacementToRemove in toRemove) {
      print('replacement being removed $replacementToRemove');
      replacements!.remove(replacementToRemove);
    }

    print('removing replacements at range finished ---------------------------------');
  }
}