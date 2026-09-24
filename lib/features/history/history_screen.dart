import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../shared/widgets/section_card.dart';
import '../dashboard/dashboard_controller.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(sensorHistoryProvider);
    final detections = ref.watch(detectionsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: [
        Text(
          'History',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        history.when(
          data: (items) => SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sensor History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      minY: 20,
                      maxY: 90,
                      gridData: const FlGridData(show: true),
                      titlesData: const FlTitlesData(
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (var i = 0; i < items.length; i++)
                              FlSpot(i.toDouble(), items[i].temperature),
                          ],
                          color: Theme.of(context).colorScheme.primary,
                          barWidth: 3,
                        ),
                        LineChartBarData(
                          spots: [
                            for (var i = 0; i < items.length; i++)
                              FlSpot(i.toDouble(), items[i].humidity),
                          ],
                          color: Theme.of(context).colorScheme.tertiary,
                          barWidth: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Hijau: suhu, kuning: kelembapan'),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Text('$error'),
        ),
        const SizedBox(height: 12),
        detections.when(
          data: (items) => SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vision History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                for (final item in items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.className),
                    subtitle: Text(
                      '${DateFormat('dd MMM yyyy HH:mm').format(item.detectedAt)} - ${item.type}',
                    ),
                    trailing: Text('${(item.confidence * 100).round()}%'),
                  ),
              ],
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => Text('$error'),
        ),
      ],
    );
  }
}
