import 'package:flutter/foundation.dart';

/// Normalised, read-only view over a `{DateTime: int}` dataset.
///
/// `DateTime` equality depends on the time-of-day component, so a raw map
/// keyed by `DateTime` is fragile for day-granular lookup. This wrapper
/// normalises every key to date-only at construction and exposes O(1)
/// lookup by year/month/day.
@immutable
class HeatmapDataSource {
  final Map<DateTime, int> _data;

  /// Wraps [raw], normalising every key to its date-only component.
  HeatmapDataSource(Map<DateTime, int> raw) : _data = _normalize(raw);

  /// The value recorded for [date], or `null` if no entry exists.
  ///
  /// `null` is distinct from an explicit `0`: callers may interpret the two
  /// differently (e.g. "untracked" vs. "tracked, zero activity").
  int? valueFor(DateTime date) =>
      _data[DateTime(date.year, date.month, date.day)];

  /// The number of distinct dates with recorded values.
  int get length => _data.length;

  static Map<DateTime, int> _normalize(Map<DateTime, int> raw) {
    final out = <DateTime, int>{};
    for (final e in raw.entries) {
      final k = e.key;
      out[DateTime(k.year, k.month, k.day)] = e.value;
    }
    return out;
  }
}
