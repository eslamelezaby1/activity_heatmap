# activity_heatmap

A highly customizable activity heatmap widget for Flutter — GitHub-style contribution graphs painted with a single `CustomPainter` so they stay smooth across multi-year ranges.

## Features

- One cell per day across any `[startDate, endDate]` range.
- Horizontal (GitHub-style) and vertical layouts.
- Two sizing modes: scroll along the active axis, or shrink cells to fit a bounded box.
- Configurable week start, cell size, corner radius, spacing, and empty-cell colour.
- Bucket-based palette — any number of thresholds, any colours.
- Tap callback returning the cell's date and recorded value (or `null` when there is no data).
- Localisable weekday and month labels; right-to-left aware (mirrors under `TextDirection.rtl`).
- Matching `HeatmapLegend` widget that shares style with the heatmap.
- Rendered with a single `CustomPainter` — no per-cell widgets, so multi-year ranges remain performant.

## Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  activity_heatmap: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## Quick start

```dart
import 'package:activity_heatmap/activity_heatmap.dart';
import 'package:flutter/material.dart';

class ContributionsView extends StatelessWidget {
  const ContributionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final oneYearAgo = today.subtract(const Duration(days: 365));

    return ActivityHeatmap(
      startDate: oneYearAgo,
      endDate: today,
      data: {
        DateTime(today.year, today.month, today.day): 3,
        // ...your {DateTime: int} values
      },
      onCellTap: (date, value) {
        debugPrint('$date -> ${value ?? 0}');
      },
    );
  }
}
```

## Custom palette

Provide your own `HeatmapBucket` thresholds and an empty colour via `HeatmapStyle`:

```dart
ActivityHeatmap(
  startDate: start,
  endDate: end,
  data: data,
  style: const HeatmapStyle(
    cellSize: 14,
    cellRadius: 3,
    spacing: 3,
    emptyColor: Color(0xFFF1F3F5),
    buckets: [
      HeatmapBucket(minValue: 1,  color: Color(0xFFFFE0B2)),
      HeatmapBucket(minValue: 5,  color: Color(0xFFFFB74D)),
      HeatmapBucket(minValue: 10, color: Color(0xFFFB8C00)),
      HeatmapBucket(minValue: 20, color: Color(0xFFE65100)),
    ],
  ),
)
```

Resolution is highest-first: a cell picks the bucket with the largest `minValue` that does not exceed its value. Cells below every threshold fall back to `emptyColor`.

## Layout axes

```dart
// Stack weeks top-to-bottom for narrow mobile screens.
ActivityHeatmap(
  startDate: start,
  endDate: end,
  data: data,
  axis: HeatmapAxis.vertical,
  firstDayOfWeek: DateTime.monday,
)
```

## Shrink to fit

`HeatmapFit.shrinkToFit` scales cells to the available width/height instead of scrolling — useful for fixed tiles.

```dart
ActivityHeatmap(
  startDate: today.subtract(const Duration(days: 89)),
  endDate: today,
  data: data,
  fit: HeatmapFit.shrinkToFit,
  firstDayOfWeek: DateTime.monday,
)
```

## Localisation and RTL

Pass localised short labels and the widget will honour the ambient `Directionality`:

```dart
Directionality(
  textDirection: TextDirection.rtl,
  child: ActivityHeatmap(
    startDate: start,
    endDate: end,
    data: data,
    style: const HeatmapStyle(
      weekdayLabels: ['إث', 'ثل', 'أر', 'خم', 'جم', 'سب', 'أح'],
      monthLabels: [
        'ينا', 'فبر', 'مار', 'أبر', 'ماي', 'يون',
        'يول', 'أغس', 'سبت', 'أكت', 'نوف', 'ديس',
      ],
    ),
  ),
)
```

## Legend

`HeatmapLegend` renders a compact "Less … More" strip using the same `HeatmapStyle`, so swatches stay in lockstep with the heatmap.

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    ActivityHeatmap(startDate: start, endDate: end, data: data),
    const SizedBox(height: 8),
    const HeatmapLegend(style: HeatmapStyle()),
  ],
)
```

Pass `lessLabel` and `moreLabel` to localise.

## API overview

| Symbol                   | Purpose                                                               |
| ------------------------ | --------------------------------------------------------------------- |
| `ActivityHeatmap`        | The main widget.                                                      |
| `HeatmapStyle`           | Immutable visual configuration (cell size, palette, labels, …).       |
| `HeatmapBucket`          | A `{minValue, color}` pair used to colour cells.                      |
| `HeatmapAxis`            | `horizontal` (default) or `vertical` layout.                          |
| `HeatmapFit`             | `scroll` (default) or `shrinkToFit`.                                  |
| `HeatmapLegend`          | Compact legend sharing a `HeatmapStyle`.                              |
| `HeatmapCellTapCallback` | `void Function(DateTime date, int? value)`. `value` is `null` when no data exists for the date (distinct from `0`). |

## Example app

See [`example/`](example/) for a demo that covers every layout, palette, RTL, and shrink-to-fit.

```bash
cd example
flutter run
```

## Author

Eslam Elezaby · [GitHub](https://github.com/eslamelezaby1) · [LinkedIn](https://www.linkedin.com/in/eslamelezaby98/) · [X](https://x.com/eslamelezaby98)

## License

[MIT](LICENSE)
