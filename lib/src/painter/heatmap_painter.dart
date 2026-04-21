import 'package:flutter/rendering.dart';

import '../data/heatmap_data_source.dart';
import '../model/heatmap_axis.dart';
import '../model/heatmap_style.dart';
import 'heatmap_geometry.dart';

/// Single [CustomPainter] that draws the entire heatmap — cells, weekday
/// labels, and month labels.
///
/// Performance notes:
/// * A single [Paint] is reused across all cells; only `.color` is mutated.
/// * Cells outside the current clip bounds are skipped via
///   [HeatmapGeometry.visibleColumns], so painting cost is proportional to
///   visible area rather than total data range.
/// * [shouldRepaint] compares by value (`HeatmapStyle`, `HeatmapGeometry`)
///   and by data identity plus an external version counter, so stale
///   frames do not repaint.
class HeatmapPainter extends CustomPainter {
  /// Geometry describing the grid and coordinate transforms.
  final HeatmapGeometry geometry;

  /// Data source; accessed via [HeatmapDataSource.valueFor] per cell.
  final HeatmapDataSource data;

  /// Style controlling colours and label rendering.
  final HeatmapStyle style;

  /// Monotonically increasing counter the caller bumps when the underlying
  /// data changes. Combined with style/geometry equality to drive repaints.
  final int dataVersion;

  final Paint _cellPaint = Paint()..style = PaintingStyle.fill;

  /// Creates a painter for the current frame.
  HeatmapPainter({
    required this.geometry,
    required this.data,
    required this.style,
    required this.dataVersion,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintCells(canvas);
    if (style.showWeekdayLabels && geometry.leadingLabelExtent > 0) {
      _paintWeekdayLabels(canvas);
    }
    if (style.showMonthLabels && geometry.topLabelExtent > 0) {
      _paintMonthLabels(canvas);
    }
  }

  void _paintCells(Canvas canvas) {
    final clip = canvas.getLocalClipBounds();
    final range = geometry.visibleColumns(clip);
    final radius = Radius.circular(style.cellRadius);
    for (int c = range.first; c <= range.last; c++) {
      for (int r = 0; r < 7; r++) {
        final date = geometry.dateAt(c, r);
        if (date == null) continue;
        _cellPaint.color = style.colorFor(data.valueFor(date));
        canvas.drawRRect(
          RRect.fromRectAndRadius(geometry.cellRect(c, r), radius),
          _cellPaint,
        );
      }
    }
  }

  void _paintWeekdayLabels(Canvas canvas) {
    final textStyle = style.weekdayLabelStyle ??
        const TextStyle(color: Color(0xFF666666), fontSize: 10);
    for (int r = 0; r < 7; r++) {
      // The weekday for row r = firstDayOfWeek + r (mod 7).
      // Our label array is indexed 0=Mon..6=Sun.
      final weekday = ((geometry.firstDayOfWeek - 1 + r) % 7) + 1;
      final idx = weekday - 1;
      if (idx < 0 || idx >= style.weekdayLabels.length) continue;
      final label = style.weekdayLabels[idx];
      if (label.isEmpty) continue;
      final tp = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: geometry.textDirection,
      )..layout();
      final cellRect = geometry.cellRect(0, r);
      final Offset origin;
      if (geometry.axis == HeatmapAxis.horizontal) {
        final y = cellRect.center.dy - tp.height / 2;
        if (geometry.textDirection == TextDirection.rtl) {
          origin = Offset(
            geometry.canvasWidth - geometry.leadingLabelExtent + 4,
            y,
          );
        } else {
          origin = Offset(geometry.leadingLabelExtent - tp.width - 4, y);
        }
      } else {
        origin = Offset(
          cellRect.center.dx - tp.width / 2,
          geometry.topLabelExtent - tp.height - 2,
        );
      }
      tp.paint(canvas, origin);
    }
  }

  void _paintMonthLabels(Canvas canvas) {
    final textStyle = style.monthLabelStyle ??
        const TextStyle(color: Color(0xFF666666), fontSize: 10);
    int? prevMonth;
    for (int c = 0; c < geometry.columnCount; c++) {
      DateTime? repr;
      for (int r = 0; r < 7; r++) {
        repr = geometry.dateAt(c, r);
        if (repr != null) break;
      }
      if (repr == null) continue;
      final month = repr.month;
      if (month == prevMonth) continue;
      prevMonth = month;
      final idx = month - 1;
      if (idx < 0 || idx >= style.monthLabels.length) continue;
      final label = style.monthLabels[idx];
      if (label.isEmpty) continue;
      final tp = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: geometry.textDirection,
      )..layout();
      final cellRect = geometry.cellRect(c, 0);
      final Offset origin;
      if (geometry.axis == HeatmapAxis.horizontal) {
        origin = Offset(cellRect.left, geometry.topLabelExtent - tp.height - 2);
      } else {
        if (geometry.textDirection == TextDirection.rtl) {
          origin = Offset(
            geometry.canvasWidth - geometry.leadingLabelExtent + 4,
            cellRect.top,
          );
        } else {
          origin = Offset(
            geometry.leadingLabelExtent - tp.width - 4,
            cellRect.top,
          );
        }
      }
      tp.paint(canvas, origin);
    }
  }

  @override
  bool shouldRepaint(covariant HeatmapPainter old) =>
      old.dataVersion != dataVersion ||
      !identical(old.data, data) ||
      old.style != style ||
      old.geometry != geometry;
}
