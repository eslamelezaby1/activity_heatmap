/// The scroll and layout axis of the heatmap.
///
/// * [horizontal] renders columns (weeks) left-to-right with days stacked top
///   to bottom — the classic GitHub contribution-graph layout.
/// * [vertical] transposes the layout: weeks stack top-to-bottom and days run
///   left-to-right. Suited for narrow mobile screens.
enum HeatmapAxis {
  /// Columns are weeks, rows are days of the week. Scrolls horizontally.
  horizontal,

  /// Rows are weeks, columns are days of the week. Scrolls vertically.
  vertical,
}
