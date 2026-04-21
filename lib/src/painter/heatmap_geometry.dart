import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../model/heatmap_axis.dart';

/// Pure geometry for the heatmap grid.
///
/// Encapsulates the forward map `(col, row) → DateTime / Rect` and the
/// inverse hit-test `Offset → (col, row)`. All coordinates are expressed in
/// the painter's local space. The class is immutable and cheap to compare.
///
/// This is exported so advanced callers can build their own overlays
/// (tooltips, selection rings) on top of the same coordinate system the
/// widget uses internally.
@immutable
class HeatmapGeometry {
  /// The first date in the displayed range (date-only, inclusive).
  final DateTime startDate;

  /// The last date in the displayed range (date-only, inclusive).
  final DateTime endDate;

  /// The date at grid coordinate `(col: 0, row: 0)`. Always falls on
  /// [firstDayOfWeek]; may precede [startDate].
  final DateTime gridStart;

  /// 1 = Monday … 7 = Sunday (matching `DateTime.monday` constants).
  final int firstDayOfWeek;

  /// Total number of week-columns needed to cover `[startDate, endDate]`.
  final int columnCount;

  /// Whether the grid is laid out horizontally or vertically.
  final HeatmapAxis axis;

  /// Edge length of each cell, in logical pixels.
  final double cellSize;

  /// Gap between adjacent cells.
  final double spacing;

  /// Pixels reserved for the leading (weekday) label strip.
  final double leadingLabelExtent;

  /// Pixels reserved for the top (month) label strip.
  final double topLabelExtent;

  /// Text direction; controls whether the horizontal axis is mirrored.
  final TextDirection textDirection;

  const HeatmapGeometry._({
    required this.startDate,
    required this.endDate,
    required this.gridStart,
    required this.firstDayOfWeek,
    required this.columnCount,
    required this.axis,
    required this.cellSize,
    required this.spacing,
    required this.leadingLabelExtent,
    required this.topLabelExtent,
    required this.textDirection,
  });

  /// Computes geometry for the given inputs. Cheap — plain arithmetic.
  factory HeatmapGeometry.compute({
    required DateTime startDate,
    required DateTime endDate,
    required HeatmapAxis axis,
    required int firstDayOfWeek,
    required double cellSize,
    required double spacing,
    required double leadingLabelExtent,
    required double topLabelExtent,
    required TextDirection textDirection,
  }) {
    assert(firstDayOfWeek >= 1 && firstDayOfWeek <= 7,
        'firstDayOfWeek must be in 1..7 (DateTime.monday..sunday)');
    assert(!endDate.isBefore(startDate),
        'endDate must not precede startDate');
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    final e = DateTime(endDate.year, endDate.month, endDate.day);
    final offset = (s.weekday - firstDayOfWeek) % 7; // Dart: positive result
    final gridStart = s.subtract(Duration(days: offset));
    final totalDays = e.difference(gridStart).inDays;
    final columnCount = (totalDays ~/ 7) + 1;
    return HeatmapGeometry._(
      startDate: s,
      endDate: e,
      gridStart: gridStart,
      firstDayOfWeek: firstDayOfWeek,
      columnCount: columnCount,
      axis: axis,
      cellSize: cellSize,
      spacing: spacing,
      leadingLabelExtent: leadingLabelExtent,
      topLabelExtent: topLabelExtent,
      textDirection: textDirection,
    );
  }

  double get _step => cellSize + spacing;

  /// Total width of the painted canvas, including label strips.
  double get canvasWidth {
    if (axis == HeatmapAxis.horizontal) {
      return leadingLabelExtent + columnCount * _step;
    }
    return leadingLabelExtent + 7 * _step;
  }

  /// Total height of the painted canvas, including label strips.
  double get canvasHeight {
    if (axis == HeatmapAxis.horizontal) {
      return topLabelExtent + 7 * _step;
    }
    return topLabelExtent + columnCount * _step;
  }

  /// The date at grid coordinate `(col, row)`, or `null` if the coordinate
  /// is outside the grid or the resulting date is outside
  /// `[startDate, endDate]`. This means leading/trailing blank cells caused
  /// by weekday alignment return `null` — callers should skip them rather
  /// than paint them.
  DateTime? dateAt(int col, int row) {
    if (col < 0 || col >= columnCount || row < 0 || row >= 7) return null;
    final d = gridStart.add(Duration(days: col * 7 + row));
    if (d.isBefore(startDate) || d.isAfter(endDate)) return null;
    return d;
  }

  /// The rectangle occupied by the cell at `(col, row)` in painter-local
  /// space. Applies RTL mirroring when [textDirection] is
  /// [TextDirection.rtl].
  Rect cellRect(int col, int row) {
    double gx;
    double gy;
    if (axis == HeatmapAxis.horizontal) {
      gx = leadingLabelExtent + col * _step;
      gy = topLabelExtent + row * _step;
    } else {
      gx = leadingLabelExtent + row * _step;
      gy = topLabelExtent + col * _step;
    }
    if (textDirection == TextDirection.rtl) {
      gx = canvasWidth - gx - cellSize;
    }
    return Rect.fromLTWH(gx, gy, cellSize, cellSize);
  }

  /// Inverse of [cellRect]: given a local [point], returns the `(col, row)`
  /// of the cell under it, or `null` if the point lies in a spacing gap,
  /// in a label strip, or outside the grid.
  ({int col, int row})? hitTest(Offset point) {
    double px = point.dx;
    final double py = point.dy - topLabelExtent;
    if (textDirection == TextDirection.rtl) {
      px = canvasWidth - px;
    }
    px -= leadingLabelExtent;
    if (px < 0 || py < 0) return null;

    final int col;
    final int row;
    final double gapPrimary;
    final double gapSecondary;
    if (axis == HeatmapAxis.horizontal) {
      col = (px / _step).floor();
      row = (py / _step).floor();
      gapPrimary = px - col * _step;
      gapSecondary = py - row * _step;
    } else {
      col = (py / _step).floor();
      row = (px / _step).floor();
      gapPrimary = py - col * _step;
      gapSecondary = px - row * _step;
    }
    // Reject clicks in the spacing gap between cells.
    if (gapPrimary > cellSize || gapSecondary > cellSize) return null;
    if (col < 0 || col >= columnCount || row < 0 || row >= 7) return null;
    return (col: col, row: row);
  }

  /// The inclusive column range that intersects [clip], for viewport
  /// culling. Returns the full range when [clip] is null. If nothing is
  /// visible, returns a range with `last < first`.
  ({int first, int last}) visibleColumns(Rect? clip) {
    if (clip == null) return (first: 0, last: columnCount - 1);
    double lo;
    double hi;
    if (axis == HeatmapAxis.horizontal) {
      double left;
      double right;
      if (textDirection == TextDirection.rtl) {
        left = canvasWidth - clip.right;
        right = canvasWidth - clip.left;
      } else {
        left = clip.left;
        right = clip.right;
      }
      lo = left - leadingLabelExtent;
      hi = right - leadingLabelExtent;
    } else {
      lo = clip.top - topLabelExtent;
      hi = clip.bottom - topLabelExtent;
    }
    final first = math.max(0, (lo / _step).floor());
    final last = math.min(columnCount - 1, (hi / _step).ceil());
    if (last < first) return (first: 0, last: -1);
    return (first: first, last: last);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeatmapGeometry &&
          other.startDate == startDate &&
          other.endDate == endDate &&
          other.firstDayOfWeek == firstDayOfWeek &&
          other.axis == axis &&
          other.cellSize == cellSize &&
          other.spacing == spacing &&
          other.leadingLabelExtent == leadingLabelExtent &&
          other.topLabelExtent == topLabelExtent &&
          other.textDirection == textDirection;

  @override
  int get hashCode => Object.hash(
        startDate,
        endDate,
        firstDayOfWeek,
        axis,
        cellSize,
        spacing,
        leadingLabelExtent,
        topLabelExtent,
        textDirection,
      );
}
