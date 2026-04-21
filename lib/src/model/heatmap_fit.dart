/// Controls how the heatmap sizes itself within its parent.
enum HeatmapFit {
  /// Render at the cell size defined in the style and wrap in a scroll view
  /// along the active axis. The natural choice when showing months or years.
  scroll,

  /// Shrink cells to fit the available space without scrolling. Useful when
  /// the caller wants to display a bounded date range in a fixed area.
  shrinkToFit,
}
