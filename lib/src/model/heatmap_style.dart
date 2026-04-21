import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'heatmap_bucket.dart';

/// Visual configuration for [ActivityHeatmap] and [HeatmapLegend].
///
/// All fields have sensible defaults approximating GitHub's contribution
/// graph. Provide your own [buckets] and [emptyColor] to theme the heatmap.
/// The class is immutable and cheap to compare — `shouldRepaint` uses value
/// equality to skip unnecessary repaints.
@immutable
class HeatmapStyle {
  /// Edge length of each cell, in logical pixels.
  final double cellSize;

  /// Corner radius of each cell.
  final double cellRadius;

  /// Gap between adjacent cells on both axes.
  final double spacing;

  /// Colour used for cells with no recorded value and for cells whose value
  /// falls below every bucket's [HeatmapBucket.minValue].
  final Color emptyColor;

  /// Threshold-to-colour mappings. Order does not matter: resolution picks
  /// the bucket with the largest [HeatmapBucket.minValue] not exceeding the
  /// cell's value.
  final List<HeatmapBucket> buckets;

  /// Text style for month labels. Falls back to a neutral grey when null.
  final TextStyle? monthLabelStyle;

  /// Text style for weekday labels. Falls back to a neutral grey when null.
  final TextStyle? weekdayLabelStyle;

  /// Labels for the seven days of the week in Mon–Sun order (index 0 = Mon).
  ///
  /// Provide localised strings if you need non-English labels. Pass empty
  /// strings for days you want to hide.
  final List<String> weekdayLabels;

  /// Labels for the twelve months in Jan–Dec order (index 0 = Jan).
  final List<String> monthLabels;

  /// Whether to paint the month-label strip above (or beside, in vertical
  /// mode) the grid.
  final bool showMonthLabels;

  /// Whether to paint the weekday-label strip beside (or above, in vertical
  /// mode) the grid.
  final bool showWeekdayLabels;

  /// Pixel extent reserved for month labels along the leading edge.
  final double monthLabelHeight;

  /// Pixel extent reserved for weekday labels along the leading edge.
  final double weekdayLabelWidth;

  /// Creates an immutable style. All fields have defaults; override only what
  /// you need.
  const HeatmapStyle({
    this.cellSize = 12,
    this.cellRadius = 2,
    this.spacing = 2,
    this.emptyColor = const Color(0xFFEBEDF0),
    this.buckets = defaultBuckets,
    this.monthLabelStyle,
    this.weekdayLabelStyle,
    this.weekdayLabels = defaultWeekdayLabels,
    this.monthLabels = defaultMonthLabels,
    this.showMonthLabels = true,
    this.showWeekdayLabels = true,
    this.monthLabelHeight = 16,
    this.weekdayLabelWidth = 28,
  });

  /// GitHub-inspired four-step green palette.
  static const List<HeatmapBucket> defaultBuckets = [
    HeatmapBucket(minValue: 1, color: Color(0xFF9BE9A8)),
    HeatmapBucket(minValue: 5, color: Color(0xFF40C463)),
    HeatmapBucket(minValue: 10, color: Color(0xFF30A14E)),
    HeatmapBucket(minValue: 20, color: Color(0xFF216E39)),
  ];

  /// Default English weekday labels, Mon–Sun.
  static const List<String> defaultWeekdayLabels = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  /// Default English short month labels, Jan–Dec.
  static const List<String> defaultMonthLabels = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Resolves the colour for [value]. A `null` [value] means "no data" and
  /// maps to [emptyColor]. Buckets may be in any order.
  Color colorFor(int? value) {
    if (value == null) return emptyColor;
    Color result = emptyColor;
    int best = -1;
    for (final b in buckets) {
      if (value >= b.minValue && b.minValue > best) {
        result = b.color;
        best = b.minValue;
      }
    }
    return result;
  }

  /// Returns a copy with the given fields replaced.
  HeatmapStyle copyWith({
    double? cellSize,
    double? cellRadius,
    double? spacing,
    Color? emptyColor,
    List<HeatmapBucket>? buckets,
    TextStyle? monthLabelStyle,
    TextStyle? weekdayLabelStyle,
    List<String>? weekdayLabels,
    List<String>? monthLabels,
    bool? showMonthLabels,
    bool? showWeekdayLabels,
    double? monthLabelHeight,
    double? weekdayLabelWidth,
  }) {
    return HeatmapStyle(
      cellSize: cellSize ?? this.cellSize,
      cellRadius: cellRadius ?? this.cellRadius,
      spacing: spacing ?? this.spacing,
      emptyColor: emptyColor ?? this.emptyColor,
      buckets: buckets ?? this.buckets,
      monthLabelStyle: monthLabelStyle ?? this.monthLabelStyle,
      weekdayLabelStyle: weekdayLabelStyle ?? this.weekdayLabelStyle,
      weekdayLabels: weekdayLabels ?? this.weekdayLabels,
      monthLabels: monthLabels ?? this.monthLabels,
      showMonthLabels: showMonthLabels ?? this.showMonthLabels,
      showWeekdayLabels: showWeekdayLabels ?? this.showWeekdayLabels,
      monthLabelHeight: monthLabelHeight ?? this.monthLabelHeight,
      weekdayLabelWidth: weekdayLabelWidth ?? this.weekdayLabelWidth,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeatmapStyle &&
          other.cellSize == cellSize &&
          other.cellRadius == cellRadius &&
          other.spacing == spacing &&
          other.emptyColor == emptyColor &&
          listEquals(other.buckets, buckets) &&
          other.monthLabelStyle == monthLabelStyle &&
          other.weekdayLabelStyle == weekdayLabelStyle &&
          listEquals(other.weekdayLabels, weekdayLabels) &&
          listEquals(other.monthLabels, monthLabels) &&
          other.showMonthLabels == showMonthLabels &&
          other.showWeekdayLabels == showWeekdayLabels &&
          other.monthLabelHeight == monthLabelHeight &&
          other.weekdayLabelWidth == weekdayLabelWidth;

  @override
  int get hashCode => Object.hash(
        cellSize,
        cellRadius,
        spacing,
        emptyColor,
        Object.hashAll(buckets),
        monthLabelStyle,
        weekdayLabelStyle,
        Object.hashAll(weekdayLabels),
        Object.hashAll(monthLabels),
        showMonthLabels,
        showWeekdayLabels,
        monthLabelHeight,
        weekdayLabelWidth,
      );
}
