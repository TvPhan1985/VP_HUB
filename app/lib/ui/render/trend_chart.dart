import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/device_session.dart';
import '../../core/model/vph_schema.dart';
import '../../core/model/vph_value.dart';
import '../../l10n/l10n.dart';

String _two(int v) => v.toString().padLeft(2, '0');
String _hm(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';
String _hms(DateTime t) => '${_hm(t)}:${_two(t.second)}';

/// Chu trong o chu thich khi cham bieu do: "25.4 °C" va gio "12:05:33"
String trendTooltip(VphField field, double value, DateTime at) {
  final v = fmtNum(value, dp: field.decimals ?? 1);
  final u = field.unit;
  return '${u == null ? v : '$v $u'}\n${_hms(at)}';
}

/// Bieu do duong cua mot truong co goi y trend (lich su RAM, toi da 1 gio)
class TrendChart extends StatelessWidget {
  final VphField field;
  final List<TrendPoint> points;
  const TrendChart({super.key, required this.field, required this.points});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    if (points.length < 2) {
      return SizedBox(
        height: 60,
        child: Center(child: Text(context.l.trendEmpty, style: theme.textTheme.bodySmall)),
      );
    }
    final t0 = points.first.t;
    final spots = [
      for (final p in points) FlSpot(p.t.difference(t0).inMilliseconds / 1000.0, p.v),
    ];
    var lo = points.first.v, hi = points.first.v;
    for (final p in points) {
      if (p.v < lo) lo = p.v;
      if (p.v > hi) hi = p.v;
    }
    // Chua le de duong khong dinh sat mep, va khong bi chia 0 khi so dung yen
    final pad = (hi - lo) < 0.5 ? 0.5 : (hi - lo) * 0.15;
    final maxX = spots.last.x < 10 ? 10.0 : spots.last.x;
    final dec = field.decimals ?? 1;
    return SizedBox(
      height: 170,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 16, 4),
        child: LineChart(
          duration: Duration.zero,
          LineChartData(
            minX: 0,
            maxX: maxX,
            minY: lo - pad,
            maxY: hi + pad,
            // Cham vao bieu do de xem gia tri (theo dp, kem don vi) va gio cua diem do
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => cs.inverseSurface,
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipItems: (touched) => [
                  for (final t in touched)
                    LineTooltipItem(
                      trendTooltip(field, t.y, t0.add(Duration(milliseconds: (t.x * 1000).round()))),
                      TextStyle(color: cs.onInverseSurface, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                ],
              ),
            ),
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(color: cs.outlineVariant, strokeWidth: 0.5),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  getTitlesWidget: (v, meta) => v == meta.min || v == meta.max
                      ? const SizedBox.shrink()
                      : Text(fmtNum(v, dp: dec), style: theme.textTheme.labelSmall),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  interval: maxX / 3,
                  getTitlesWidget: (v, meta) => v == meta.max
                      ? const SizedBox.shrink()
                      : Text(_hm(t0.add(Duration(seconds: v.round()))), style: theme.textTheme.labelSmall),
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: false,
                barWidth: 2,
                color: cs.primary,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: true, color: cs.primary.withValues(alpha: 0.12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
