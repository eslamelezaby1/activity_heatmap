## 0.1.0 - 2026-04-21

Initial release.

- `ActivityHeatmap` widget rendering one cell per day across a date range, painted with a single `CustomPainter` for multi-year performance.
- Horizontal (GitHub-style) and vertical layouts via `HeatmapAxis`.
- Scroll (`HeatmapFit.scroll`) and shrink-to-fit (`HeatmapFit.shrinkToFit`) sizing modes.
- Configurable week start (`firstDayOfWeek`), cell size, spacing, corner radius, empty colour, and bucket palette.
- `HeatmapStyle` with `copyWith`, value equality, and a GitHub-inspired default palette.
- `HeatmapBucket` threshold-to-colour mapping; cells resolve to the highest matching bucket.
- `HeatmapLegend` widget that shares `HeatmapStyle` with the main heatmap.
- Cell-tap callback (`HeatmapCellTapCallback`) returning the tapped date and value (or `null` for "no data").
- Localisable weekday and month labels.
- Right-to-left support (axis mirrors under `TextDirection.rtl`).
