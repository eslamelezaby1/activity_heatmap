import 'dart:ui';

import 'package:activity_heatmap/activity_heatmap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  HeatmapGeometry make({
    DateTime? start,
    DateTime? end,
    int firstDayOfWeek = DateTime.sunday,
    HeatmapAxis axis = HeatmapAxis.horizontal,
    TextDirection textDirection = TextDirection.ltr,
    double cellSize = 10,
    double spacing = 2,
    double leadingLabelExtent = 0,
    double topLabelExtent = 0,
  }) {
    return HeatmapGeometry.compute(
      startDate: start ?? DateTime(2026, 1, 1),
      endDate: end ?? DateTime(2026, 12, 31),
      axis: axis,
      firstDayOfWeek: firstDayOfWeek,
      cellSize: cellSize,
      spacing: spacing,
      leadingLabelExtent: leadingLabelExtent,
      topLabelExtent: topLabelExtent,
      textDirection: textDirection,
    );
  }

  group('HeatmapGeometry alignment', () {
    test('Sunday-start: Jan 1 2026 (Thu) lands on row 4', () {
      final g = make();
      // Grid starts on the preceding Sunday.
      expect(g.gridStart, DateTime(2025, 12, 28));
      expect(g.dateAt(0, 4), DateTime(2026, 1, 1));
      // Leading blanks in column 0 (before startDate) return null.
      expect(g.dateAt(0, 0), isNull);
      expect(g.dateAt(0, 3), isNull);
    });

    test('Monday-start: Jan 1 2026 lands on row 3', () {
      final g = make(firstDayOfWeek: DateTime.monday);
      expect(g.gridStart, DateTime(2025, 12, 29));
      expect(g.dateAt(0, 3), DateTime(2026, 1, 1));
      expect(g.dateAt(0, 0), isNull);
    });

    test('columnCount covers full year', () {
      final g = make();
      // 2026 needs 53 columns with Sunday-start (Dec 28 → Jan 2 2027).
      expect(g.columnCount, greaterThanOrEqualTo(53));
      expect(g.columnCount, lessThanOrEqualTo(54));
    });
  });

  group('HeatmapGeometry hit test', () {
    test('center of a cell hits that cell', () {
      final g = make(spacing: 2, cellSize: 10);
      final rect = g.cellRect(3, 2);
      final hit = g.hitTest(rect.center);
      expect(hit, isNotNull);
      expect(hit!.col, 3);
      expect(hit.row, 2);
    });

    test('spacing gap returns null', () {
      final g = make(cellSize: 10, spacing: 2);
      // Cell (0, 0) occupies [0, 10); gap between (0,0) and (1,0) is [10, 12).
      const point = Offset(11, 5); // inside gap
      expect(g.hitTest(point), isNull);
    });

    test('label strip returns null', () {
      final g = make(leadingLabelExtent: 30, topLabelExtent: 20);
      expect(g.hitTest(const Offset(5, 5)), isNull); // inside leading label
    });

    test('RTL horizontal mirrors the x axis', () {
      final g = make(textDirection: TextDirection.rtl);
      final rect = g.cellRect(0, 0);
      // In RTL the rightmost cell in column 0 should pick up col=0.
      final hit = g.hitTest(rect.center);
      expect(hit, isNotNull);
      expect(hit!.col, 0);
    });
  });

  group('HeatmapGeometry culling', () {
    test('null clip returns full range', () {
      final g = make();
      final r = g.visibleColumns(null);
      expect(r.first, 0);
      expect(r.last, g.columnCount - 1);
    });

    test('narrow clip returns subset', () {
      final g = make(cellSize: 10, spacing: 2);
      // Columns 5..10 roughly span x in [60, 132).
      const clip = Rect.fromLTWH(60, 0, 72, 100);
      final r = g.visibleColumns(clip);
      expect(r.first, lessThanOrEqualTo(5));
      expect(r.last, greaterThanOrEqualTo(10));
    });
  });

  group('HeatmapGeometry equality', () {
    test('same inputs produce equal geometries', () {
      final a = make();
      final b = make();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different cellSize breaks equality', () {
      final a = make(cellSize: 10);
      final b = make(cellSize: 12);
      expect(a, isNot(equals(b)));
    });
  });
}
