import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/nursery_models.dart';
import '../../shared/widgets/section_card.dart';
import '../../shared/widgets/status_chip.dart';
import '../dashboard/dashboard_controller.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);
    final devices = ref.watch(devicesProvider);

    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: () async {
        final refreshedDevices = ref.refresh(devicesProvider.future);
        final refreshedDashboard = ref.refresh(dashboardProvider.future);
        await Future.wait([refreshedDevices, refreshedDashboard]);
      },
      child: devices.when(
        data: (deviceItems) => dashboard.when(
          data: (snapshot) {
            final anyOnline = deviceItems.any((device) => device.isOnline);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _FleetSummary(devices: deviceItems, fan: snapshot.fan),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Node Sensor & Pengendali (ESP32)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
                if (deviceItems.isEmpty)
                  const SectionCard(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Belum ada perangkat ESP32 yang terdaftar di database.',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                  )
                else
                  for (final device in deviceItems) ...[
                    _DeviceCard(
                      icon: Icons.developer_board_rounded,
                      iconColor: AppTheme.primaryGreen,
                      title: device.name,
                      code: device.code,
                      status: device.status,
                      isOnline: device.isOnline,
                      lastSeen: device.lastSeen,
                      details: [
                        _DeviceDetail(
                          icon: Icons.location_on_outlined,
                          label: 'Lokasi',
                          value: device.location.isEmpty
                              ? 'Belum diatur'
                              : device.location,
                        ),
                        _DeviceDetail(
                          icon: Icons.sensors_rounded,
                          label: 'Sensor terbaru',
                          value: device.latestSensor == null
                              ? 'Belum ada data'
                              : '${device.latestSensor!.temperature != null ? '${device.latestSensor!.temperature!.toStringAsFixed(1)}°C' : '-'} · Kelembapan ${device.latestSensor!.humidity != null ? '${device.latestSensor!.humidity!.toStringAsFixed(0)}%' : '-'}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                const SizedBox(height: 6),
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Aktuator Nursery (Output Lapangan)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
                _PumpDeviceCard(
                  fan: snapshot.fan,
                  deviceOnline: anyOnline,
                ),
                const SizedBox(height: 10),
                _MistDeviceCard(
                  deviceOnline: anyOnline,
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen),
          ),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Status aktuator belum tersedia: $error'),
            ),
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Data perangkat belum tersedia dari API: $error'),
          ),
        ),
      ),
    );
  }
}

class _FleetSummary extends StatelessWidget {
  const _FleetSummary({required this.devices, required this.fan});

  final List<DeviceStatus> devices;
  final FanState fan;

  @override
  Widget build(BuildContext context) {
    final onlineCount = devices.where((device) => device.isOnline).length;

    return SectionCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.hub_rounded,
              color: AppTheme.primaryGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Perangkat lapangan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textStrong,
                  ),
                ),
                Text(
                  '$onlineCount dari ${devices.length} ESP32 online · Pompa air ${fan.status}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          StatusChip(
            label: onlineCount > 0 ? 'LIVE' : 'OFFLINE',
            color: onlineCount > 0 ? AppTheme.primaryGreen : AppTheme.critical,
            isPulse: onlineCount > 0,
          ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.code,
    required this.status,
    required this.isOnline,
    required this.lastSeen,
    required this.details,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String code;
  final String status;
  final bool isOnline;
  final DateTime lastSeen;
  final List<_DeviceDetail> details;

  @override
  Widget build(BuildContext context) {
    final age = DateTime.now().difference(lastSeen);
    final isStale = isOnline && age.inMinutes >= 5;
    final statusColor = isStale
        ? AppTheme.warning
        : isOnline
        ? iconColor
        : AppTheme.critical;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
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
                      code,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: isStale ? 'STALE' : status.toUpperCase(),
                color: statusColor,
                isPulse: isOnline && !isStale,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _InfoTile(detail: details[0])),
              Expanded(child: _InfoTile(detail: details[1])),
            ],
          ),
          const SizedBox(height: 10),
          _LastSeenStrip(
            lastSeen: lastSeen,
            isStale: isStale,
            isOffline: !isOnline,
          ),
        ],
      ),
    );
  }
}

class _PumpDeviceCard extends ConsumerWidget {
  const _PumpDeviceCard({required this.fan, required this.deviceOnline});

  final FanState fan;
  final bool deviceOnline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(fanControlErrorProvider, (previous, next) {
      if (next != null && previous != next) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kontrol pompa air gagal: $next')),
        );
      }
    });
    final fanAsync = ref.watch(fanControllerProvider);
    final fanState = fanAsync.value ?? fan;
    final isBusy = ref.watch(fanControlBusyProvider);
    final canControl = deviceOnline && fanState.deviceOnline;
    final isOn = fanState.isOn;
    final color = isOn ? AppTheme.primaryGreen : AppTheme.textMuted;

    return SectionCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.water_drop_rounded, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pompa air',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textStrong,
                  ),
                ),
                Text(
                  'Mode ${fanState.mode} · Status ${fanState.status}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isOn,
            activeThumbColor: AppTheme.primaryGreen,
            onChanged: isBusy || !canControl
                ? null
                : (value) {
                    ref
                        .read(fanControllerProvider.notifier)
                        .setStatus(value ? 'ON' : 'OFF');
                  },
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
    );
  }
}

class _MistDeviceCard extends StatelessWidget {
  const _MistDeviceCard({required this.deviceOnline});

  final bool deviceOnline;

  @override
  Widget build(BuildContext context) {
    final color = deviceOnline ? AppTheme.teal : AppTheme.textMuted;

    return SectionCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.grain_rounded, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kabut air (Misting)',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textStrong,
                  ),
                ),
                Text(
                  deviceOnline
                      ? 'Mode AUTO · Mengatur kelembapan'
                      : 'Perangkat standby / offline',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          StatusChip(
            label: deviceOnline ? 'STANDBY' : 'OFFLINE',
            color: deviceOnline ? AppTheme.teal : AppTheme.textMuted,
            isPulse: deviceOnline,
          ),
        ],
      ),
    );
  }
}

class _LastSeenStrip extends StatelessWidget {
  const _LastSeenStrip({
    required this.lastSeen,
    required this.isStale,
    required this.isOffline,
  });

  final DateTime lastSeen;
  final bool isStale;
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    final color = isOffline
        ? AppTheme.critical
        : isStale
        ? AppTheme.warning
        : AppTheme.textMuted;
    final text = isOffline
        ? 'Offline sejak ${DateFormat('dd MMM HH:mm').format(lastSeen)}'
        : isStale
        ? 'Data tertahan ${DateFormat('HH:mm').format(lastSeen)}'
        : 'Update ${DateFormat('HH:mm:ss').format(lastSeen)}';

    return Row(
      children: [
        Icon(Icons.schedule_rounded, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.detail});

  final _DeviceDetail detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(detail.icon, size: 14, color: AppTheme.textMuted),
            const SizedBox(width: 4),
            Text(
              detail.label,
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          detail.value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppTheme.textStrong,
          ),
        ),
      ],
    );
  }
}

class _DeviceDetail {
  const _DeviceDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}
