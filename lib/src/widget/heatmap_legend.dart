import 'package:flutter/widgets.dart';

import '../model/heatmap_style.dart';

/// A compact legend showing each bucket's colour, flanked by "less" and
/// "more" labels. Shares a [HeatmapStyle] with the main heatmap so the two
/// stay visually consistent.
class HeatmapLegend extends StatelessWidget {
  /// Style whose [HeatmapStyle.emptyColor] and [HeatmapStyle.buckets] drive
  /// the swatches.
  final HeatmapStyle style;

  /// Leading label ("Less" by default).
  final String lessLabel;

  /// Trailing label ("More" by default).
  final String moreLabel;

  /// Text style for the leading/trailing labels. Falls back to a neutral
  /// grey when null.
  final TextStyle? labelStyle;

  /// Creates a legend. Pass localised strings for non-English locales.
  const HeatmapLegend({
    super.key,
    required this.style,
    this.lessLabel = 'Less',
    this.moreLabel = 'More',
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final swatches = <Color>[
      style.emptyColor,
      ...style.buckets.map((b) => b.color),
    ];
    final textStyle = labelStyle ??
        const TextStyle(color: Color(0xFF666666), fontSize: 10);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(lessLabel, style: textStyle),
        const SizedBox(width: 4),
        for (int i = 0; i < swatches.length; i++) ...[
          _Swatch(
            color: swatches[i],
            size: style.cellSize,
            radius: style.cellRadius,
          ),
          if (i < swatches.length - 1) SizedBox(width: style.spacing),
        ],
        const SizedBox(width: 4),
        Text(moreLabel, style: textStyle),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  final double size;
  final double radius;

  const _Swatch({
    required this.color,
    required this.size,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.all(Radius.circular(radius)),
      ),
    );
  }
}
