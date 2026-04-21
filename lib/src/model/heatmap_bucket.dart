import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// A single threshold-to-colour mapping used to paint cells.
///
/// Buckets are resolved highest-first: a cell's colour is the bucket with the
/// largest [minValue] that does not exceed the cell's value. Cells below the
/// smallest [minValue] fall back to the style's empty colour.
@immutable
class HeatmapBucket {
  /// The minimum value (inclusive) required for a cell to take on [color].
  final int minValue;

  /// The colour applied to cells whose value meets [minValue].
  final Color color;

  /// Creates a bucket. [minValue] should be non-negative.
  const HeatmapBucket({required this.minValue, required this.color});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeatmapBucket &&
          other.minValue == minValue &&
          other.color == color;

  @override
  int get hashCode => Object.hash(minValue, color);

  @override
  String toString() => 'HeatmapBucket(minValue: $minValue, color: $color)';
}
