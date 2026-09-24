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

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.thermostat_auto_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Kondisi Pembibitan Padi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const StatusChip(
                    label: 'SYSTEM ONLINE',
                    color: Colors.white,
                    isPulse: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
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
                      snapshot.recommendation.status,
                      style: TextStyle(
                        color: scheme.tertiary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                snapshot.recommendation.cause,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                snapshot.recommendation.message,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Section Title: Telemetry
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Telemetri Sensor Realtime',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              '7 Telemetri Aktif',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SensorGrid(sensor: snapshot.sensor),

        const SizedBox(height: 18),

        // Section Title: Controls & AI
        const Text(
          'Kontrol & Deteksi AI',
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
  const _SensorGrid({required this.sensor});

  final SensorReading sensor;

  @override
  Widget build(BuildContext context) {
    final items = [
      _SensorItem(
        icon: Icons.thermostat_rounded,
        label: 'Suhu Lingkungan',
        value: '${sensor.temperature.toStringAsFixed(1)}°C',
        status: 'NORMAL',
        accentColor: AppTheme.primaryGreen,
      ),
      _SensorItem(
        icon: Icons.water_drop_rounded,
        label: 'Kelembapan Udara',
        value: '${sensor.humidity.toStringAsFixed(0)}%',
        status: 'PERLU WASPADA',
        accentColor: const Color(0xFFD97706), // Amber
      ),
      _SensorItem(
        icon: Icons.wb_sunny_rounded,
        label: 'Intensitas Cahaya',
        value: '${sensor.light.toStringAsFixed(0)} Lux',
        status: 'OPTIMAL',
        accentColor: const Color(0xFF0D9488), // Teal
      ),
      _SensorItem(
        icon: Icons.grass_rounded,
        label: 'Nitrogen (N)',
        value: '${sensor.nitrogen.toStringAsFixed(0)} mg/kg',
        status: 'HARA CUKUP',
        accentColor: AppTheme.primaryGreen,
      ),
      _SensorItem(
        icon: Icons.spa_rounded,
        label: 'Phosphorus (P)',
        value: '${sensor.phosphorus.toStringAsFixed(0)} mg/kg',
        status: 'HARA CUKUP',
        accentColor: AppTheme.primaryGreen,
      ),
      _SensorItem(
        icon: Icons.eco_rounded,
        label: 'Potassium (K)',
        value: '${sensor.potassium.toStringAsFixed(0)} mg/kg',
        status: 'HARA CUKUP',
        accentColor: AppTheme.primaryGreen,
      ),
      _SensorItem(
        icon: Icons.waves_rounded,
        label: 'Ketinggian Air',
        value: '${sensor.ultrasonic.toStringAsFixed(0)} cm',
        status: 'LEVEL STABIL',
        accentColor: const Color(0xFF0284C7), // Sky Blue
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
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return SectionCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: item.accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          item.icon,
                          color: item.accentColor,
                          size: 20,
                        ),
                      ),
                      StatusChip(
                        label: item.status,
                        color: item.accentColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item.value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
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
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFFCA5A5),
                width: 1,
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bug_report_rounded,
                  color: Color(0xFFDC2626),
                  size: 30,
                ),
                SizedBox(height: 2),
                Text(
                  'AI ALERT',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Deteksi Hama Terbaru',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    StatusChip(
                      label: '${(detection.confidence * 100).round()}% MATCH',
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
                ),
                const SizedBox(height: 2),
                Text(
                  '${detection.type.toUpperCase()} • ${detection.cameraId}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
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
              Row(
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Aktuator Kipas Pentilasi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
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
                ],
              ),
              StatusChip(
                label: fanState.mode,
                color: fanState.mode == 'AUTO'
                    ? AppTheme.primaryGreen
                    : const Color(0xFF0D9488),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
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

