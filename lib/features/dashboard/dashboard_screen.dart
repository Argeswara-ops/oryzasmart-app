import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../shared/models/nursery_models.dart';
import '../../shared/widgets/section_card.dart';
import '../../shared/widgets/status_chip.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(dashboardProvider.future),
      child: dashboard.when(
        data: (snapshot) => _DashboardContent(snapshot: snapshot),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ListView(
          padding: const EdgeInsets.all(20),
          children: [Text('Dashboard gagal dimuat: $error')],
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Smart Rice Nursery',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Monitoring pembibitan padi realtime',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            StatusChip(
              label: 'ONLINE',
              color: scheme.primary,
              icon: Icons.circle,
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kondisi Pembibitan',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              StatusChip(
                label: snapshot.recommendation.status,
                color: scheme.tertiary,
                icon: Icons.warning_amber_rounded,
              ),
              const SizedBox(height: 12),
              Text(snapshot.recommendation.cause),
              const SizedBox(height: 6),
              Text(snapshot.recommendation.message),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SensorGrid(sensor: snapshot.sensor),
        const SizedBox(height: 12),
        _LatestDetection(detection: snapshot.detection),
        const SizedBox(height: 12),
        _FanControl(fan: snapshot.fan),
      ],
    );
  }
}

class _SensorGrid extends StatelessWidget {
  const _SensorGrid({required this.sensor});

  final SensorReading sensor;

  @override
  Widget build(BuildContext context) {
    final items = [
      _SensorItem(
        Icons.thermostat,
        'Suhu',
        '${sensor.temperature.toStringAsFixed(1)} C',
        'NORMAL',
      ),
      _SensorItem(
        Icons.water_drop,
        'Kelembapan',
        '${sensor.humidity.toStringAsFixed(0)} %',
        'WARNING',
      ),
      _SensorItem(
        Icons.wb_sunny,
        'Cahaya / UV',
        sensor.light.toStringAsFixed(0),
        'NORMAL',
      ),
      _SensorItem(
        Icons.grass,
        'Nitrogen',
        '${sensor.nitrogen.toStringAsFixed(0)} mg/kg',
        'N',
      ),
      _SensorItem(
        Icons.spa,
        'Phosphorus',
        '${sensor.phosphorus.toStringAsFixed(0)} mg/kg',
        'P',
      ),
      _SensorItem(
        Icons.eco,
        'Potassium',
        '${sensor.potassium.toStringAsFixed(0)} mg/kg',
        'K',
      ),
      _SensorItem(
        Icons.waves,
        'Ultrasonik',
        '${sensor.ultrasonic.toStringAsFixed(0)} cm',
        'LEVEL',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 620 ? 3 : 2;
        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.45,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(item.icon, color: Theme.of(context).colorScheme.primary),
                  Text(
                    item.label,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Text(
                    item.value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    item.status,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: item.status == 'WARNING'
                          ? Theme.of(context).colorScheme.tertiary
                          : Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _LatestDetection extends StatelessWidget {
  const _LatestDetection({required this.detection});

  final Detection detection;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.bug_report,
              color: Theme.of(context).colorScheme.onErrorContainer,
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Latest Detection',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  detection.className,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${detection.type.toUpperCase()} - Confidence ${(detection.confidence * 100).round()}%',
                ),
                Text(
                  '${detection.cameraId} - ${DateFormat.Hm().format(detection.detectedAt)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FanControl extends ConsumerWidget {
  const _FanControl({required this.fan});

  final FanState fan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fanState = ref
        .watch(fanControllerProvider)
        .maybeWhen(data: (value) => value, orElse: () => fan);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kontrol Kipas',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'AUTO',
                icon: Icon(Icons.auto_mode),
                label: Text('Auto'),
              ),
              ButtonSegment(
                value: 'MANUAL',
                icon: Icon(Icons.touch_app),
                label: Text('Manual'),
              ),
            ],
            selected: {fanState.mode},
            onSelectionChanged: (value) {
              ref.read(fanControllerProvider.notifier).setMode(value.first);
            },
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Fan status'),
            subtitle: Text('Status sekarang: ${fanState.status}'),
            value: fanState.status == 'ON',
            onChanged: fanState.mode == 'MANUAL'
                ? (value) {
                    ref
                        .read(fanControllerProvider.notifier)
                        .setStatus(value ? 'ON' : 'OFF');
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class _SensorItem {
  const _SensorItem(this.icon, this.label, this.value, this.status);

  final IconData icon;
  final String label;
  final String value;
  final String status;
}
