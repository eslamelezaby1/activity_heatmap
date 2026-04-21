import 'dart:math';

import 'package:activity_heatmap/activity_heatmap.dart';
import 'package:flutter/material.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Activity Heatmap Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF216E39),
        useMaterial3: true,
      ),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  late final DateTime _today;
  late final DateTime _oneYearAgo;
  late final Map<DateTime, int> _data;

  String? _tapReadout;

  @override
  void initState() {
    super.initState();
    _today = _dateOnly(DateTime.now());
    _oneYearAgo = _today.subtract(const Duration(days: 365));
    _data = _generateSyntheticData(_oneYearAgo, _today);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity Heatmap')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: 'Horizontal · GitHub palette',
            subtitle: 'Scrolls horizontally. Tap any cell.',
            child: ActivityHeatmap(
              startDate: _oneYearAgo,
              endDate: _today,
              data: _data,
              onCellTap: _onTap,
            ),
          ),
          if (_tapReadout != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_tapReadout!,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          const SizedBox(height: 8),
          const HeatmapLegend(style: HeatmapStyle()),
          const SizedBox(height: 32),
          _Section(
            title: 'Monday-start · custom palette',
            subtitle: 'firstDayOfWeek = monday, custom buckets.',
            child: ActivityHeatmap(
              startDate: _oneYearAgo,
              endDate: _today,
              data: _data,
              firstDayOfWeek: DateTime.monday,
              style: const HeatmapStyle(
                cellSize: 14,
                cellRadius: 3,
                spacing: 3,
                emptyColor: Color(0xFFF1F3F5),
                buckets: [
                  HeatmapBucket(minValue: 1, color: Color(0xFFFFE0B2)),
                  HeatmapBucket(minValue: 5, color: Color(0xFFFFB74D)),
                  HeatmapBucket(minValue: 10, color: Color(0xFFFB8C00)),
                  HeatmapBucket(minValue: 20, color: Color(0xFFE65100)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          _Section(
            title: 'Vertical · mobile-friendly',
            subtitle: 'Weeks stack top-to-bottom.',
            child: SizedBox(
              height: 300,
              child: ActivityHeatmap(
                startDate: _oneYearAgo,
                endDate: _today,
                data: _data,
                axis: HeatmapAxis.vertical,
                firstDayOfWeek: DateTime.monday,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _Section(
            title: 'RTL (Arabic)',
            subtitle: 'Horizontal axis mirrors under TextDirection.rtl.',
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: ActivityHeatmap(
                startDate: _oneYearAgo,
                endDate: _today,
                data: _data,
                style: const HeatmapStyle(
                  weekdayLabels: ['إث', 'ثل', 'أر', 'خم', 'جم', 'سب', 'أح'],
                  monthLabels: [
                    'ينا', 'فبر', 'مار', 'أبر', 'ماي', 'يون',
                    'يول', 'أغس', 'سبت', 'أكت', 'نوف', 'ديس',
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _Section(
            title: 'Shrink to fit · last 90 days',
            subtitle: 'No scroll — cells scale to the available width.',
            child: ActivityHeatmap(
              startDate: _today.subtract(const Duration(days: 89)),
              endDate: _today,
              data: _data,
              fit: HeatmapFit.shrinkToFit,
              firstDayOfWeek: DateTime.monday,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _onTap(DateTime date, int? value) {
    setState(() {
      final label = '${date.year}-${_pad(date.month)}-${_pad(date.day)}';
      _tapReadout = value == null
          ? '$label · no data'
          : '$label · $value contributions';
    });
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _Section({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 2),
        Text(subtitle, style: theme.textTheme.bodySmall),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String _pad(int n) => n.toString().padLeft(2, '0');

Map<DateTime, int> _generateSyntheticData(DateTime start, DateTime end) {
  final rng = Random(42);
  final out = <DateTime, int>{};
  for (DateTime d = start;
      !d.isAfter(end);
      d = d.add(const Duration(days: 1))) {
    // Skew toward weekdays; occasional spikes.
    final base = (d.weekday <= 5) ? rng.nextInt(8) : rng.nextInt(3);
    final spike = rng.nextDouble() < 0.05 ? rng.nextInt(20) : 0;
    final v = base + spike;
    if (v > 0) out[d] = v;
  }
  return out;
}
