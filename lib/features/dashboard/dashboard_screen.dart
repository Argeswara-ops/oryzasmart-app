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
        loading: () => const _DashboardSkeleton(),
        error: (error, stackTrace) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SectionCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
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
    final condition = _Condition.fromSnapshot(snapshot);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        _GreetingCard(snapshot: snapshot),
        const SizedBox(height: 12),
        _ConditionBanner(snapshot: snapshot, condition: condition),
        const SizedBox(height: 12),
        _DashboardSection(
          title: 'Sensor Realtime',
          subtitle: 'Pembacaan terakhir dari node ESP32',
          trailing: IconButton(
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            padding: EdgeInsets.zero,
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(dashboardProvider),
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppTheme.primaryGreen,
              size: 20,
            ),
          ),
          child: _SensorGrid(sensor: snapshot.sensor),
        ),
        const SizedBox(height: 12),
        _DashboardSection(
          title: 'Kontrol & Bukti AI',
          subtitle: 'Aksi perangkat dan deteksi kamera terbaru',
          child: Column(
            children: [
              _FanControl(fan: snapshot.fan),
              const SizedBox(height: 10),
              _LatestDetection(detection: snapshot.detection),
            ],
          ),
        ),
      ],
    );
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 11
        ? 'Selamat pagi'
        : hour < 15
        ? 'Selamat siang'
        : hour < 18
        ? 'Selamat sore'
        : 'Selamat malam';
    final icon = hour < 18 ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded;

    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, Petani',
                  style: const TextStyle(
                    color: AppTheme.textStrong,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Nursery ${snapshot.device.code} dipantau secara realtime',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConditionBanner extends StatelessWidget {
  const _ConditionBanner({required this.snapshot, required this.condition});

  final DashboardSnapshot snapshot;
  final _Condition condition;

  @override
  Widget build(BuildContext context) {
    final updatedAt = DateFormat.Hm().format(snapshot.sensor.createdAt);

    return SectionCard(
      gradient: LinearGradient(
        colors: condition.gradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: condition.borderColor,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(condition.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      condition.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Update $updatedAt WIB',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _DarkStatusPill(label: snapshot.device.status.toUpperCase()),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            snapshot.recommendation.cause,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          Text(
            snapshot.recommendation.message,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12.5,
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _BannerMetric(
                  label: 'Kelembapan',
                  value: '${snapshot.sensor.humidity.toStringAsFixed(0)}%',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BannerMetric(
                  label: 'Deteksi',
                  value: snapshot.detection.type.toUpperCase(),
                ),
              ),
            ],
          ),
        ],
      ),
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
        label: 'Suhu',
        value: '${sensor.temperature.toStringAsFixed(1)} C',
        status: sensor.temperature >= 32 ? 'WASPADA' : 'NORMAL',
        accentColor: sensor.temperature >= 32
            ? AppTheme.warning
            : AppTheme.primaryGreen,
      ),
      _SensorItem(
        icon: Icons.water_drop_rounded,
        label: 'Kelembapan',
        value: '${sensor.humidity.toStringAsFixed(0)}%',
        status: sensor.humidity >= 80 ? 'TINGGI' : 'NORMAL',
        accentColor: sensor.humidity >= 80
            ? AppTheme.warning
            : AppTheme.primaryGreen,
      ),
      _SensorItem(
        icon: Icons.wb_sunny_rounded,
        label: 'Cahaya',
        value: '${sensor.light.toStringAsFixed(0)} lux',
        status: 'OPTIMAL',
        accentColor: AppTheme.teal,
      ),
      _SensorItem(
        icon: Icons.waves_rounded,
        label: 'Air',
        value: '${sensor.ultrasonic.toStringAsFixed(0)} cm',
        status: 'STABIL',
        accentColor: AppTheme.infoBlue,
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
        icon: Icons.schedule_rounded,
        label: 'Data',
        value: DateFormat.Hm().format(sensor.createdAt),
        status: 'LIVE',
        accentColor: AppTheme.teal,
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
            childAspectRatio: constraints.maxWidth > 620 ? 1.7 : 1.48,
          ),
          itemBuilder: (context, index) => _SensorCard(item: items[index]),
        );
      },
    );
  }
}

class _SensorCard extends StatelessWidget {
  const _SensorCard({required this.item});

  final _SensorItem item;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: item.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, color: item.accentColor, size: 17),
              ),
              const Spacer(),
              Flexible(
                child: StatusChip(label: item.status, color: item.accentColor),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            item.label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textMuted,
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
                fontWeight: FontWeight.w900,
                color: AppTheme.textStrong,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestDetection extends StatelessWidget {
  const _LatestDetection({required this.detection});

  final Detection detection;

  @override
  Widget build(BuildContext context) {
    final isHealthy = detection.type == 'healthy';
    final color = isHealthy ? AppTheme.primaryGreen : AppTheme.warning;

    return SectionCard(
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.28)),
            ),
            child: Icon(
              isHealthy ? Icons.verified_rounded : Icons.center_focus_strong,
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Deteksi terbaru',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    StatusChip(
                      label: '${(detection.confidence * 100).round()}%',
                      color: color,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  detection.className,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textStrong,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${detection.type.toUpperCase()} - ${detection.cameraId}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
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
                  color: isFanOn ? AppTheme.primaryGreen : AppTheme.textMuted,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kipas ventilasi',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textStrong,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Status ${fanState.status}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isFanOn
                            ? AppTheme.primaryGreen
                            : AppTheme.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: fanState.mode,
                color: fanState.mode == 'AUTO'
                    ? AppTheme.primaryGreen
                    : AppTheme.teal,
              ),
            ],
          ),
          const SizedBox(height: 14),
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
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Saklar daya kipas',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF334155),
                      ),
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

class _DashboardSection extends StatelessWidget {
  const _DashboardSection({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textStrong,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: const [
        _SkeletonBlock(height: 92),
        SizedBox(height: 12),
        _SkeletonBlock(height: 176),
        SizedBox(height: 12),
        _SkeletonBlock(height: 330),
        SizedBox(height: 12),
        _SkeletonBlock(height: 250),
      ],
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonLine(width: MediaQuery.sizeOf(context).width * 0.42),
            const SizedBox(height: 10),
            const _SkeletonLine(width: 140),
            const Spacer(),
            Row(
              children: const [
                Expanded(child: _SkeletonLine(width: double.infinity)),
                SizedBox(width: 10),
                Expanded(child: _SkeletonLine(width: double.infinity)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3EE),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _BannerMetric extends StatelessWidget {
  const _BannerMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _DarkStatusPill extends StatelessWidget {
  const _DarkStatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Condition {
  const _Condition({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.borderColor,
  });

  final String title;
  final IconData icon;
  final List<Color> gradient;
  final Color borderColor;

  static _Condition fromSnapshot(DashboardSnapshot snapshot) {
    final status = snapshot.recommendation.status.toUpperCase();
    final hasDisease = snapshot.detection.type == 'disease';
    final hasPest = snapshot.detection.type == 'pest';

    if (status.contains('CRITICAL')) {
      return const _Condition(
        title: 'Critical',
        icon: Icons.error_rounded,
        gradient: [Color(0xFF7F1D1D), AppTheme.critical],
        borderColor: Color(0xFF991B1B),
      );
    }
    if (status.contains('PERLU') || hasDisease || hasPest) {
      return const _Condition(
        title: 'Perlu Perhatian',
        icon: Icons.warning_amber_rounded,
        gradient: [Color(0xFF92400E), AppTheme.warning],
        borderColor: Color(0xFFB45309),
      );
    }
    return const _Condition(
      title: 'Normal',
      icon: Icons.verified_rounded,
      gradient: [Color(0xFF064E3B), AppTheme.primaryGreen],
      borderColor: AppTheme.primaryGreenDark,
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
