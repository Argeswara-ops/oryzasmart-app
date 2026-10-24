import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/nursery_models.dart';
import '../../shared/widgets/section_card.dart';
import '../../shared/widgets/status_chip.dart';
import '../dashboard/dashboard_controller.dart';
import '../oryza_vision/data/repositories/vision_history_repository.dart';
import '../oryza_vision/domain/entities/vision_models.dart';
import '../oryza_vision/presentation/controllers/vision_history_controller.dart';
import '../oryza_vision/presentation/screens/vision_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _tab = 'sensor';
  String _metric = 'temperature';
  String _period = '7d';

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(sensorHistoryProvider(_period));
    final scans = ref.watch(visionHistoryProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _TopTabs(
          value: _tab,
          onChanged: (value) => setState(() => _tab = value),
        ),
        const SizedBox(height: 12),
        if (_tab == 'sensor')
          history.when(
            data: (items) => _SensorHistory(
              items: items,
              metric: _metric,
              period: _period,
              onMetricChanged: (value) => setState(() => _metric = value),
              onPeriodChanged: (value) => setState(() => _period = value),
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              ),
            ),
            error: (error, stackTrace) => Text('Error: $error'),
          )
        else
          scans.when(
            data: (state) => _VisionHistory(items: state.records),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              ),
            ),
            error: (error, stackTrace) => Text('$error'),
          ),
      ],
    );
  }
}

class _SensorHistory extends StatelessWidget {
  const _SensorHistory({
    required this.items,
    required this.metric,
    required this.period,
    required this.onMetricChanged,
    required this.onPeriodChanged,
  });

  final List<SensorReading> items;
  final String metric;
  final String period;
  final ValueChanged<String> onMetricChanged;
  final ValueChanged<String> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final spec = _MetricSpec.fromKey(metric);
    final values = [for (final item in items) spec.valueOf(item)];
    final stats = _Stats.from(values);

    return Column(
      children: [
        _PeriodControl(value: period, onChanged: onPeriodChanged),
        const SizedBox(height: 10),
        _MetricControl(value: metric, onChanged: onMetricChanged),
        const SizedBox(height: 12),
        _StatsGrid(stats: stats, unit: spec.unit),
        const SizedBox(height: 12),
        _ChartCard(
          title: 'Grafik ${spec.label}',
          legends: [_ChartLegend(label: spec.unit, color: spec.color)],
          minY: stats.minY,
          maxY: stats.maxY,
          yInterval: stats.yInterval,
          lines: [_ChartLine(values: values, color: spec.color, fill: true)],
        ),
        const SizedBox(height: 12),
        _NpkChart(items: items),
      ],
    );
  }
}

class _NpkChart extends StatelessWidget {
  const _NpkChart({required this.items});

  final List<SensorReading> items;

  @override
  Widget build(BuildContext context) {
    final nitrogen = [for (final item in items) item.nitrogen];
    final phosphorus = [for (final item in items) item.phosphorus];
    final potassium = [for (final item in items) item.potassium];
    final allValues = [...nitrogen, ...phosphorus, ...potassium];
    final stats = _Stats.from(allValues);

    return _ChartCard(
      title: 'Grafik NPK',
      legends: const [
        _ChartLegend(label: 'N', color: AppTheme.primaryGreen),
        _ChartLegend(label: 'P', color: AppTheme.infoBlue),
        _ChartLegend(label: 'K', color: AppTheme.warning),
      ],
      minY: stats.minY,
      maxY: stats.maxY,
      yInterval: stats.yInterval,
      lines: [
        _ChartLine(values: nitrogen, color: AppTheme.primaryGreen),
        _ChartLine(values: phosphorus, color: AppTheme.infoBlue),
        _ChartLine(values: potassium, color: AppTheme.warning),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.legends,
    required this.minY,
    required this.maxY,
    required this.yInterval,
    required this.lines,
  });

  final String title;
  final List<Widget> legends;
  final double minY;
  final double maxY;
  final double yInterval;
  final List<_ChartLine> lines;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textStrong,
                  ),
                ),
              ),
              Wrap(spacing: 8, children: legends),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: yInterval,
                      getTitlesWidget: (value, meta) {
                        final text = _formatAxisValue(value, yInterval);
                        return SizedBox(
                          width: 38,
                          child: Text(
                            text,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  for (final line in lines)
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < line.values.length; i++)
                          FlSpot(i.toDouble(), line.values[i]),
                      ],
                      isCurved: true,
                      color: line.color,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: line.fill,
                        color: line.color.withValues(alpha: 0.1),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartLine {
  const _ChartLine({
    required this.values,
    required this.color,
    this.fill = false,
  });

  final List<double> values;
  final Color color;
  final bool fill;
}

class _VisionHistory extends StatelessWidget {
  const _VisionHistory({required this.items});

  final List<VisionScanRecord> items;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Riwayat Scan Manual',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppTheme.textStrong,
            ),
          ),
          const SizedBox(height: 12),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _VisionHistoryTile(item: item),
            ),
        ],
      ),
    );
  }
}

class _VisionHistoryTile extends StatelessWidget {
  const _VisionHistoryTile({required this.item});

  final VisionScanRecord item;

  @override
  Widget build(BuildContext context) {
    final color = item.task.name == 'pest'
        ? AppTheme.warning
        : AppTheme.primaryGreen;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VisionHistoryDetailScreen(record: item),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                item.task.name == 'pest'
                    ? Icons.bug_report_rounded
                    : Icons.eco_rounded,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textStrong,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${DateFormat('dd MMM yyyy HH:mm').format(item.scannedAt)} • Scan ${item.task.title}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusChip(
              label: '${(item.confidence * 100).round()}%',
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats, required this.unit});

  final _Stats stats;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Current', stats.current),
      ('Average', stats.average),
      ('Minimum', stats.min),
      ('Maximum', stats.max),
    ];

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.6,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return SectionCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.$1,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${item.$2.toStringAsFixed(1)} $unit',
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.textStrong,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TopTabs extends StatelessWidget {
  const _TopTabs({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<String>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: 'sensor', label: Text('Sensor')),
          ButtonSegment(value: 'vision', label: Text('Vision')),
        ],
        selected: {value},
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}

class _PeriodControl extends StatelessWidget {
  const _PeriodControl({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<String>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: 'today', label: Text('Hari ini')),
          ButtonSegment(value: '7d', label: Text('7 hari')),
          ButtonSegment(value: '30d', label: Text('30 hari')),
        ],
        selected: {value},
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}

class _MetricControl extends StatelessWidget {
  const _MetricControl({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<String>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: 'temperature', label: Text('Suhu')),
          ButtonSegment(value: 'humidity', label: Text('Humid')),
          ButtonSegment(value: 'light', label: Text('Cahaya')),
          ButtonSegment(value: 'water', label: Text('Air')),
        ],
        selected: {value},
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MetricSpec {
  const _MetricSpec({
    required this.label,
    required this.unit,
    required this.color,
    required this.valueOf,
  });

  final String label;
  final String unit;
  final Color color;
  final double Function(SensorReading reading) valueOf;

  static _MetricSpec fromKey(String key) {
    return switch (key) {
      'humidity' => _MetricSpec(
        label: 'Kelembapan',
        unit: '%',
        color: AppTheme.warning,
        valueOf: (reading) => reading.humidity,
      ),
      'light' => _MetricSpec(
        label: 'Cahaya',
        unit: 'lux',
        color: AppTheme.teal,
        valueOf: (reading) => reading.light,
      ),
      'water' => _MetricSpec(
        label: 'Level air',
        unit: 'cm',
        color: AppTheme.infoBlue,
        valueOf: (reading) => reading.ultrasonic,
      ),
      _ => _MetricSpec(
        label: 'Suhu',
        unit: 'C',
        color: AppTheme.primaryGreen,
        valueOf: (reading) => reading.temperature,
      ),
    };
  }
}

class _Stats {
  const _Stats({
    required this.current,
    required this.average,
    required this.min,
    required this.max,
  });

  final double current;
  final double average;
  final double min;
  final double max;

  _AxisScale get _axisScale => _AxisScale.from(min: min, max: max);
  double get minY => _axisScale.minY;
  double get maxY => _axisScale.maxY;
  double get yInterval => _axisScale.interval;

  static _Stats from(List<double> values) {
    if (values.isEmpty) {
      return const _Stats(current: 0, average: 0, min: 0, max: 10);
    }

    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final sum = values.fold<double>(0, (total, value) => total + value);

    return _Stats(
      current: values.last,
      average: sum / values.length,
      min: min,
      max: max,
    );
  }
}

class _AxisScale {
  const _AxisScale({
    required this.minY,
    required this.maxY,
    required this.interval,
  });

  final double minY;
  final double maxY;
  final double interval;

  factory _AxisScale.from({required double min, required double max}) {
    final rawRange = (max - min).abs();
    final padding = rawRange == 0
        ? math.max(max.abs() * 0.08, 1)
        : rawRange * 0.16;
    final paddedMin = math.max(0, min - padding);
    final paddedMax = max + padding;
    final step = _niceStep((paddedMax - paddedMin) / 4);
    final axisMin = (paddedMin / step).floor() * step;
    final axisMax = (paddedMax / step).ceil() * step;

    return _AxisScale(
      minY: axisMin.toDouble(),
      maxY: axisMax <= axisMin ? axisMin + step : axisMax.toDouble(),
      interval: step,
    );
  }
}

double _niceStep(double rawStep) {
  if (rawStep <= 0 || rawStep.isNaN || rawStep.isInfinite) return 1;

  final exponent = math.pow(10, (math.log(rawStep) / math.ln10).floor());
  final fraction = rawStep / exponent;
  final niceFraction = switch (fraction) {
    <= 1 => 1,
    <= 2 => 2,
    <= 5 => 5,
    _ => 10,
  };

  return (niceFraction * exponent).toDouble();
}

String _formatAxisValue(double value, double interval) {
  final needsDecimal = interval < 1;
  return needsDecimal ? value.toStringAsFixed(1) : value.round().toString();
}
