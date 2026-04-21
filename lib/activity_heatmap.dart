/// A customizable activity heatmap widget rendered with a single
/// [CustomPainter] for performance across multi-year date ranges.
library activity_heatmap;

export 'src/data/heatmap_data_source.dart';
export 'src/model/heatmap_axis.dart';
export 'src/model/heatmap_bucket.dart';
export 'src/model/heatmap_fit.dart';
export 'src/model/heatmap_style.dart';
export 'src/painter/heatmap_geometry.dart';
export 'src/widget/activity_heatmap.dart'
    show ActivityHeatmap, HeatmapCellTapCallback;
export 'src/widget/heatmap_legend.dart';
