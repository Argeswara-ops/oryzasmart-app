import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/nursery_models.dart';
import '../../shared/repositories/nursery_repository.dart';
import '../../shared/widgets/section_card.dart';
import '../../shared/widgets/status_chip.dart';
import 'dashboard_controller.dart';

const _sensorUnavailable = 'Sensor belum tersedia';

String _sensorValue(double? value, {String suffix = '', int decimals = 0}) {
  if (value == null) return _sensorUnavailable;
  return '${value.toStringAsFixed(decimals)}$suffix';
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key, required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);

    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: () => ref.refresh(dashboardProvider.future),
      child: dashboard.when(
        data: (snapshot) => _DashboardContent(snapshot: snapshot, user: user),
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
  const _DashboardContent({required this.snapshot, required this.user});

  final DashboardSnapshot snapshot;
  final AuthUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final condition = _Condition.fromSnapshot(snapshot);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        _ConditionBanner(snapshot: snapshot, condition: condition),
        const SizedBox(height: 12),
        _GreetingCard(snapshot: snapshot, user: user),
        const SizedBox(height: 12),
        _DashboardSection(
          title: 'Sensor Realtime',
          subtitle: 'Data terakhir ESP32',
          child: _SensorGrid(sensor: snapshot.sensor),
        ),
        const SizedBox(height: 12),
        _DashboardSection(
          title: 'Kontrol Pompa Air',
          subtitle: 'Status aktuator dari API',
          child: _FanControl(
            fan: snapshot.fan,
            deviceOnline: snapshot.device.isOnline,
          ),
        ),
      ],
    );
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({required this.snapshot, required this.user});

  final DashboardSnapshot snapshot;
  final AuthUser user;

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
    final firstName = _firstName(user.name);

    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $firstName 👋',
                  style: const TextStyle(
                    color: AppTheme.textStrong,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Nursery ${snapshot.device.code} dipantau secara realtime',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11.5,
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
      padding: const EdgeInsets.all(12),
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
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 86),
                child: _DarkStatusPill(
                  label: snapshot.device.status.toUpperCase(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _BannerInfoLine(
            icon: Icons.info_rounded,
            text: snapshot.recommendation.cause,
            isStrong: true,
          ),
          const SizedBox(height: 6),
          _BannerInfoLine(
            icon: Icons.task_alt_rounded,
            text: snapshot.recommendation.message,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _BannerMetric(
                  label: 'Kelembapan',
                  value: _sensorValue(snapshot.sensor.humidity, suffix: '%'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BannerMetric(
                  label: 'Ketinggian air',
                  value: _sensorValue(snapshot.sensor.waterLevel, suffix: '%'),
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
    final temp = sensor.temperature;
    final hum = sensor.humidity;

    final items = [
      _SensorItem(
        icon: Icons.thermostat_rounded,
        label: 'Suhu',
        value: _sensorValue(temp, suffix: ' C', decimals: 1),
        status: temp == null
            ? 'BELUM TERSEDIA'
            : (temp >= 32 ? 'WASPADA' : 'NORMAL'),
        accentColor: (temp != null && temp >= 32)
            ? AppTheme.warning
            : AppTheme.primaryGreen,
      ),
      _SensorItem(
        icon: Icons.water_drop_rounded,
        label: 'Kelembapan',
        value: _sensorValue(hum, suffix: '%'),
        status: hum == null
            ? 'BELUM TERSEDIA'
            : (hum >= 80 ? 'TINGGI' : 'NORMAL'),
        accentColor: (hum != null && hum >= 80)
            ? AppTheme.warning
            : AppTheme.infoBlue,
      ),
      _SensorItem(
        icon: Icons.wb_sunny_rounded,
        label: 'Cahaya',
        value: _sensorValue(sensor.lightPercent, suffix: '%'),
        status: sensor.lightPercent == null ? 'BELUM TERSEDIA' : 'OPTIMAL',
        accentColor: AppTheme.warning,
      ),
      _SensorItem(
        icon: Icons.waves_rounded,
        label: 'Ketinggian Air',
        value: _sensorValue(sensor.waterLevel, suffix: '%'),
        status: sensor.waterLevel == null
            ? 'BELUM TERSEDIA'
            : sensor.waterLevel! < 30
            ? 'RENDAH'
            : 'STABIL',
        accentColor: AppTheme.infoBlue,
      ),
      _SensorItem(
        icon: Icons.grass_rounded,
        label: 'Nitrogen',
        value: _sensorValue(sensor.nitrogen, suffix: ' mg/kg'),
        status: sensor.nitrogen == null ? 'BELUM TERSEDIA' : 'CUKUP',
        accentColor: AppTheme.primaryGreen,
      ),
      _SensorItem(
        icon: Icons.spa_rounded,
        label: 'Fosfor',
        value: _sensorValue(sensor.phosphorus, suffix: ' mg/kg'),
        status: sensor.phosphorus == null ? 'BELUM TERSEDIA' : 'CUKUP',
        accentColor: AppTheme.teal,
      ),
      _SensorItem(
        icon: Icons.eco_rounded,
        label: 'Kalium',
        value: _sensorValue(sensor.potassium, suffix: ' mg/kg'),
        status: sensor.potassium == null ? 'BELUM TERSEDIA' : 'CUKUP',
        accentColor: AppTheme.primaryGreenDark,
      ),
      _SensorItem(
        icon: Icons.wb_twilight_rounded,
        label: 'Indeks UV',
        value: _sensorValue(sensor.uvIndex, decimals: 1),
        status: sensor.uvIndex == null
            ? 'BELUM TERSEDIA'
            : sensor.uvIndex! >= 6
            ? 'TINGGI'
            : 'NORMAL',
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
            childAspectRatio: constraints.maxWidth > 620 ? 1.8 : 1.42,
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

class _FanControl extends ConsumerWidget {
  const _FanControl({required this.fan, required this.deviceOnline});

  final FanState fan;
  final bool deviceOnline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(fanControlErrorProvider, (previous, next) {
      if (next != null && previous != next) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Kontrol pompa air gagal: $next')));
      }
    });
    final fanAsync = ref.watch(fanControllerProvider);
    final fanState = fanAsync.value ?? fan;
    final isBusy = ref.watch(fanControlBusyProvider);
    final canControl = deviceOnline && fanState.deviceOnline;

    final isFanOn = fanState.isOn;

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
                  Icons.water_drop_rounded,
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
                      'Pompa air',
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
              if (isBusy) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
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
              onSelectionChanged: isBusy || !canControl
                  ? null
                  : (value) {
                      ref
                          .read(fanControllerProvider.notifier)
                          .setMode(value.first);
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
                      'Saklar daya pompa air',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                  Switch(
                    value: isFanOn,
                    activeThumbColor: AppTheme.primaryGreen,
                    onChanged: isBusy || !canControl
                        ? null
                        : (value) {
                            ref
                                .read(fanControllerProvider.notifier)
                                .setStatus(value ? 'ON' : 'OFF');
                          },
                  ),
                ],
              ),
            ),
          ],
          if (!canControl) ...[
            const SizedBox(height: 10),
            const Text(
              'Kontrol dinonaktifkan karena ESP32 sedang offline.',
              style: TextStyle(
                color: AppTheme.critical,
                fontSize: 12,
                fontWeight: FontWeight.w700,
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

class _BannerInfoLine extends StatelessWidget {
  const _BannerInfoLine({
    required this.icon,
    required this.text,
    this.isStrong = false,
  });

  final IconData icon;
  final String text;
  final bool isStrong;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 13, color: Colors.white),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: isStrong ? 0.98 : 0.9),
              fontSize: isStrong ? 12.5 : 11.5,
              height: 1.25,
              fontWeight: isStrong ? FontWeight.w900 : FontWeight.w700,
            ),
            maxLines: isStrong ? 2 : 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DarkStatusPill extends StatelessWidget {
  const _DarkStatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isLive = label == 'ONLINE' || label == 'LIVE' || label == 'ON';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            const _BlinkDot(color: Colors.white),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlinkDot extends StatefulWidget {
  const _BlinkDot({required this.color});

  final Color color;

  @override
  State<_BlinkDot> createState() => _BlinkDotState();
}

class _BlinkDotState extends State<_BlinkDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(
      begin: 0.35,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.58),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
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

    if (status.contains('CRITICAL')) {
      return const _Condition(
        title: 'Critical',
        icon: Icons.error_rounded,
        gradient: [Color(0xFF7F1D1D), AppTheme.critical],
        borderColor: Color(0xFF991B1B),
      );
    }
    if (status.contains('PERLU') || status.contains('WARNING')) {
      return const _Condition(
        title: 'Perlu Perhatian',
        icon: Icons.warning_amber_rounded,
        gradient: [AppTheme.primaryGreenDark, AppTheme.teal],
        borderColor: AppTheme.primaryGreen,
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

String _firstName(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  final first = parts.where((part) => part.isNotEmpty).firstOrNull;
  return first ?? 'Operator';
}
