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

    return dashboard.when(
      data: (snapshot) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _FleetSummary(snapshot: snapshot),
          const SizedBox(height: 12),
          _DeviceCard(
            icon: Icons.developer_board_rounded,
            iconColor: AppTheme.primaryGreen,
            title: snapshot.device.name,
            code: snapshot.device.code,
            status: snapshot.device.status,
            lastSeen: snapshot.device.lastSeen,
            details: const [
              _DeviceDetail(
                icon: Icons.wifi_rounded,
                label: 'Koneksi',
                value: 'Wi-Fi RSSI 98%',
              ),
              _DeviceDetail(
                icon: Icons.sensors_rounded,
                label: 'Payload',
                value: 'Sensor node',
              ),
            ],
          ),
          const SizedBox(height: 10),
          _DeviceCard(
            icon: Icons.videocam_rounded,
            iconColor: AppTheme.teal,
            title: snapshot.camera.name,
            code: snapshot.camera.code,
            status: snapshot.camera.status,
            lastSeen: snapshot.camera.lastSeen,
            details: const [
              _DeviceDetail(
                icon: Icons.camera_indoor_rounded,
                label: 'Kamera',
                value: 'FHD Vision Cam',
              ),
              _DeviceDetail(
                icon: Icons.center_focus_strong,
                label: 'AI',
                value: 'YOLO detection',
              ),
            ],
          ),
          const SizedBox(height: 10),
          _FanDeviceCard(fan: snapshot.fan),
        ],
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
      ),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Gagal memuat info perangkat: $error'),
        ),
      ),
    );
  }
}

class _FleetSummary extends StatelessWidget {
  const _FleetSummary({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final onlineCount =
        [snapshot.device.status, snapshot.camera.status, snapshot.fan.status]
            .where(
              (status) => status.toUpperCase() == 'ONLINE' || status == 'ON',
            )
            .length;

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
                  '$onlineCount dari 3 aktif',
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
            label: 'LIVE',
            color: AppTheme.primaryGreen,
            isPulse: true,
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
    required this.lastSeen,
    required this.details,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String code;
  final String status;
  final DateTime lastSeen;
  final List<_DeviceDetail> details;

  @override
  Widget build(BuildContext context) {
    final age = DateTime.now().difference(lastSeen);
    final isStale = age.inMinutes >= 5;
    final statusColor = isStale ? AppTheme.warning : iconColor;

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
                isPulse: !isStale,
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
          _LastSeenStrip(lastSeen: lastSeen, isStale: isStale),
        ],
      ),
    );
  }
}

class _FanDeviceCard extends ConsumerWidget {
  const _FanDeviceCard({required this.fan});

  final FanState fan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fanState = ref
        .watch(fanControllerProvider)
        .maybeWhen(data: (value) => value, orElse: () => fan);
    final isOn = fanState.status == 'ON';
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
            child: Icon(Icons.air_rounded, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kipas ventilasi',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textStrong,
                  ),
                ),
                Text(
                  'Mode ${fanState.mode}',
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
            onChanged: (value) {
              ref
                  .read(fanControllerProvider.notifier)
                  .setStatus(value ? 'ON' : 'OFF');
            },
          ),
        ],
      ),
    );
  }
}

class _LastSeenStrip extends StatelessWidget {
  const _LastSeenStrip({required this.lastSeen, required this.isStale});

  final DateTime lastSeen;
  final bool isStale;

  @override
  Widget build(BuildContext context) {
    final color = isStale ? AppTheme.warning : AppTheme.primaryGreen;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time_rounded, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Terakhir terlihat ${DateFormat.Hms().format(lastSeen)}',
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.detail});

  final _DeviceDetail detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(detail.icon, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.label,
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                detail.value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textStrong,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
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
