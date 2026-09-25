import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
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
      color: AppTheme.primaryGreen,
      onRefresh: () => ref.refresh(dashboardProvider.future),
      child: dashboard.when(
        data: (snapshot) => _DashboardContent(snapshot: snapshot),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
        error: (error, stackTrace) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SectionCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Dashboard gagal dimuat: $error'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isHealthy =
        snapshot.recommendation.status != 'CRITICAL' &&
        snapshot.detection.type != 'disease';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        // Modern Status Banner
        SectionCard(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF064E3B), // Deep Emerald
              Color(0xFF059669), // Emerald
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderColor: const Color(0xFF047857),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.grass_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text(
                      'Kondisi Padi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.24),
                      ),
                    ),
                    child: const Text(
                      'ONLINE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: scheme.tertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      snapshot.recommendation.status.split(' ').first,
                      style: TextStyle(
                        color: scheme.tertiary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                snapshot.recommendation.cause,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                snapshot.recommendation.message,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        Row(
          children: [
            const Expanded(
              child: Text(
                'Sensor Realtime',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              padding: EdgeInsets.zero,
              tooltip: 'Refresh',
              onPressed: () => ref.invalidate(dashboardProvider),
              icon: const Icon(
                Icons.refresh_rounded,
                color: AppTheme.primaryGreen,
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _SensorGrid(sensor: snapshot.sensor, isHealthy: isHealthy),

        const SizedBox(height: 18),

        // Section Title: Controls & AI
        const Text(
          'Kontrol AI',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        _FanControl(fan: snapshot.fan),
        const SizedBox(height: 12),
        _LatestDetection(detection: snapshot.detection),
      ],
    );
  }
}

class _SensorGrid extends StatelessWidget {
  const _SensorGrid({required this.sensor, required this.isHealthy});

  final SensorReading sensor;
  final bool isHealthy;

  @override
  Widget build(BuildContext context) {
    final items = [
      _SensorItem(
        icon: Icons.thermostat_rounded,
        label: 'Suhu',
        value: '${sensor.temperature.toStringAsFixed(1)}°C',
        status: 'NORMAL',
        accentColor: AppTheme.primaryGreen,
      ),
      _SensorItem(
        icon: Icons.water_drop_rounded,
        label: 'Kelembapan',
        value: '${sensor.humidity.toStringAsFixed(0)}%',
        status: 'WASPADA',
        accentColor: const Color(0xFFD97706), // Amber
      ),
      _SensorItem(
        icon: Icons.wb_sunny_rounded,
        label: 'Cahaya',
        value: '${sensor.light.toStringAsFixed(0)} Lux',
        status: 'OPTIMAL',
        accentColor: const Color(0xFF0D9488), // Teal
      ),
      _SensorItem(
        icon: Icons.grass_rounded,
        label: 'Nitrogen',
        value: '${sensor.nitrogen.toStringAsFixed(0)} mg/kg',
        status: 'CUKUP',
        accentColor: AppTheme.primaryGreen,
      ),
      _SensorItem(
        icon: Icons.spa_rounded,
        label: 'Fosfor',
        value: '${sensor.phosphorus.toStringAsFixed(0)} mg/kg',
        status: 'CUKUP',
        accentColor: AppTheme.primaryGreen,
      ),
      _SensorItem(
        icon: Icons.eco_rounded,
        label: 'Kalium',
        value: '${sensor.potassium.toStringAsFixed(0)} mg/kg',
        status: 'CUKUP',
        accentColor: AppTheme.primaryGreen,
      ),
      _SensorItem(
        icon: Icons.waves_rounded,
        label: 'Air',
        value: '${sensor.ultrasonic.toStringAsFixed(0)} cm',
        status: 'STABIL',
        accentColor: const Color(0xFF0284C7), // Sky Blue
      ),
      _SensorItem(
        icon: Icons.health_and_safety_rounded,
        label: 'Kesehatan',
        value: isHealthy ? 'Sehat' : 'Tidak Sehat',
        status: isHealthy ? 'SEHAT' : 'SAKIT',
        accentColor: isHealthy
            ? AppTheme.primaryGreen
            : const Color(0xFFEF4444),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 620 ? 4 : 2;
        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: constraints.maxWidth > 620
                ? 1.55
                : constraints.maxWidth > 360
                ? 1.42
                : 1.28,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return SectionCard(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: item.accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          item.icon,
                          color: item.accentColor,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: StatusChip(
                          label: item.status,
                          color: item.accentColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item.value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
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
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFCA5A5), width: 1),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bug_report_rounded,
                  color: Color(0xFFDC2626),
                  size: 28,
                ),
                SizedBox(height: 2),
                Text(
                  'AI',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Deteksi Terbaru',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    StatusChip(
                      label: '${(detection.confidence * 100).round()}%',
                      color: AppTheme.primaryGreen,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  detection.className,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${detection.type.toUpperCase()} • ${detection.cameraId}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Terdeteksi ${DateFormat.Hm().format(detection.detectedAt)} WIB',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
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

    final isFanOn = fanState.status == 'ON';

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isFanOn
                            ? AppTheme.primaryGreen.withValues(alpha: 0.12)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.air_rounded,
                        color: isFanOn
                            ? AppTheme.primaryGreen
                            : const Color(0xFF64748B),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kipas Ventilasi',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Status: ${fanState.status}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isFanOn
                                  ? AppTheme.primaryGreen
                                  : const Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(
                label: fanState.mode,
                color: fanState.mode == 'AUTO'
                    ? AppTheme.primaryGreen
                    : const Color(0xFF0D9488),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'AUTO',
                  icon: Icon(Icons.auto_mode_rounded, size: 18),
                  label: Text('Otomatis'),
                ),
                ButtonSegment(
                  value: 'MANUAL',
                  icon: Icon(Icons.touch_app_rounded, size: 18),
                  label: Text('Manual'),
                ),
              ],
              selected: {fanState.mode},
              onSelectionChanged: (value) {
                ref.read(fanControllerProvider.notifier).setMode(value.first);
              },
            ),
          ),
          if (fanState.mode == 'MANUAL') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Saklar Daya Kipas',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                  Switch(
                    value: isFanOn,
                    activeThumbColor: AppTheme.primaryGreen,
                    onChanged: (value) {
                      ref
                          .read(fanControllerProvider.notifier)
                          .setStatus(value ? 'ON' : 'OFF');
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SensorItem {
  const _SensorItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.status,
    required this.accentColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final String status;
  final Color accentColor;
}
