import 'package:flutter/widgets.dart';

import '../data/heatmap_data_source.dart';
import '../model/heatmap_axis.dart';
import '../model/heatmap_fit.dart';
import '../model/heatmap_style.dart';
import '../painter/heatmap_geometry.dart';
import '../painter/heatmap_painter.dart';

/// Signature for the callback fired when a heatmap cell is tapped.
///
/// [value] is the raw recorded value, or `null` when no data exists for the
/// tapped date (distinct from an explicit `0`).
typedef HeatmapCellTapCallback = void Function(DateTime date, int? value);

/// A calendar-style activity heatmap widget.
///
/// Displays one cell per day across `[startDate, endDate]`, coloured
/// according to [style]. Rendered with a single [CustomPainter] for
/// performance on multi-year ranges.
///
/// Basic usage:
/// ```dart
/// ActivityHeatmap(
///   startDate: DateTime(2026, 1, 1),
///   endDate: DateTime(2026, 12, 31),
///   data: {DateTime(2026, 3, 14): 5},
///   onCellTap: (date, value) => print('$date: ${value ?? 0}'),
/// )
/// ```
class ActivityHeatmap extends StatefulWidget {
  /// First date to display (inclusive). Time component is ignored.
  final DateTime startDate;

  /// Last date to display (inclusive). Time component is ignored.
  final DateTime endDate;

  /// Raw `{DateTime: int}` values. Keys are normalised to date-only at
  /// construction; time-of-day differences do not cause duplicate entries.
  final Map<DateTime, int> data;

  /// Layout and scroll axis. Defaults to [HeatmapAxis.horizontal].
  final HeatmapAxis axis;

  /// Whether to scroll the grid or shrink cells to fit the available space.
  final HeatmapFit fit;

  /// The weekday that occupies the first row/column. Values follow the
  /// `DateTime.monday` … `DateTime.sunday` constants (1..7).
  final int firstDayOfWeek;

  /// Visual configuration.
  final HeatmapStyle style;

  /// Invoked when the user taps a cell. The callback receives the cell's
  /// date and its recorded value (or `null`). Taps on spacing gaps and
  /// label strips are ignored.
  final HeatmapCellTapCallback? onCellTap;

  /// Creates an activity heatmap.
  const ActivityHeatmap({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.data,
    this.axis = HeatmapAxis.horizontal,
    this.fit = HeatmapFit.scroll,
    this.firstDayOfWeek = DateTime.sunday,
    this.style = const HeatmapStyle(),
    this.onCellTap,
  });

  @override
  State<ActivityHeatmap> createState() => _ActivityHeatmapState();
}

class _ActivityHeatmapState extends State<ActivityHeatmap> {
  late HeatmapDataSource _dataSource;
  int _dataVersion = 0;

  @override
  void initState() {
    super.initState();
    _dataSource = HeatmapDataSource(widget.data);
  }

  @override
  void didUpdateWidget(ActivityHeatmap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.data, widget.data)) {
      _dataSource = HeatmapDataSource(widget.data);
      _dataVersion++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);

    return LayoutBuilder(builder: (ctx, constraints) {
      final leadingLabelExtent = widget.style.showWeekdayLabels
          ? widget.style.weekdayLabelWidth
          : 0.0;
      final topLabelExtent = widget.style.showMonthLabels
          ? widget.style.monthLabelHeight
          : 0.0;

      double cellSize = widget.style.cellSize;
      if (widget.fit == HeatmapFit.shrinkToFit) {
        cellSize = _computeFitCellSize(
          constraints: constraints,
          leadingLabelExtent: leadingLabelExtent,
          topLabelExtent: topLabelExtent,
        );
      }

      final geometry = HeatmapGeometry.compute(
        startDate: widget.startDate,
        endDate: widget.endDate,
        axis: widget.axis,
        firstDayOfWeek: widget.firstDayOfWeek,
        cellSize: cellSize,
        spacing: widget.style.spacing,
        leadingLabelExtent: leadingLabelExtent,
        topLabelExtent: topLabelExtent,
        textDirection: textDirection,
      );

      final effectiveStyle = cellSize == widget.style.cellSize
          ? widget.style
          : widget.style.copyWith(cellSize: cellSize);

      final paint = CustomPaint(
        size: Size(geometry.canvasWidth, geometry.canvasHeight),
        painter: HeatmapPainter(
          geometry: geometry,
          data: _dataSource,
          style: effectiveStyle,
          dataVersion: _dataVersion,
        ),
      );

      final tappable = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) => _handleTap(details.localPosition, geometry),
        child: paint,
      );

      if (widget.fit == HeatmapFit.shrinkToFit) return tappable;

      return SingleChildScrollView(
        scrollDirection: widget.axis == HeatmapAxis.horizontal
            ? Axis.horizontal
            : Axis.vertical,
        child: tappable,
      );
    });
  }

  void _handleTap(Offset localPosition, HeatmapGeometry geometry) {
    final cb = widget.onCellTap;
    if (cb == null) return;
    final hit = geometry.hitTest(localPosition);
    if (hit == null) return;
    final date = geometry.dateAt(hit.col, hit.row);
    if (date == null) return;
    cb(date, _dataSource.valueFor(date));
  }

  double _computeFitCellSize({
    required BoxConstraints constraints,
    required double leadingLabelExtent,
    required double topLabelExtent,
  }) {
    final spacing = widget.style.spacing;
    // columnCount depends only on the date range and week-start, not on
    // cell size — so we can compute it before resolving cell size.
    final s = DateTime(
      widget.startDate.year,
      widget.startDate.month,
      widget.startDate.day,
    );
    final e = DateTime(
      widget.endDate.year,
      widget.endDate.month,
      widget.endDate.day,
    );
    final offset = (s.weekday - widget.firstDayOfWeek) % 7;
    final gridStart = s.subtract(Duration(days: offset));
    final columnCount = (e.difference(gridStart).inDays ~/ 7) + 1;

    final double available;
    final int cellsAlongAxis;
    if (widget.axis == HeatmapAxis.horizontal) {
      available = constraints.maxWidth - leadingLabelExtent;
      cellsAlongAxis = columnCount;
    } else {
      available = constraints.maxHeight - topLabelExtent;
      cellsAlongAxis = columnCount;
    }
    if (!available.isFinite || cellsAlongAxis <= 0) {
      return widget.style.cellSize;
    }
    final size = (available / cellsAlongAxis) - spacing;
    return size.clamp(1.0, widget.style.cellSize);
  }
}
