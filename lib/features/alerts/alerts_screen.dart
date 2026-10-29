import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/nursery_models.dart';
import '../../shared/widgets/section_card.dart';
import '../../shared/widgets/status_chip.dart';
import '../dashboard/dashboard_controller.dart';

void showAlertsBottomSheet(
  BuildContext context, {
  required VoidCallback onOpenAll,
  required ValueChanged<SystemAlert> onAlertSelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AlertsModalSheet(
      onOpenAll: onOpenAll,
      onAlertSelected: onAlertSelected,
    ),
  );
}

class _AlertsModalSheet extends StatelessWidget {
  const _AlertsModalSheet({
    required this.onOpenAll,
    required this.onAlertSelected,
  });

  final VoidCallback onOpenAll;
  final ValueChanged<SystemAlert> onAlertSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.68,
      decoration: const BoxDecoration(
        color: AppTheme.bgMint,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: AlertsScreen(
              isEmbedded: true,
              maxItems: 6,
              onOpenAll: () {
                Navigator.pop(context);
                onOpenAll();
              },
              onAlertSelected: (alert) {
                Navigator.pop(context);
                onAlertSelected(alert);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({
    super.key,
    this.isEmbedded = false,
    this.maxItems,
    this.onOpenAll,
    this.onAlertSelected,
  });

  final bool isEmbedded;
  final int? maxItems;
  final VoidCallback? onOpenAll;
  final ValueChanged<SystemAlert>? onAlertSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsState = ref.watch(alertsProvider);

    Future<void> markAllRead(List<SystemAlert> alerts) async {
      final unreadIds = [
        for (final alert in alerts)
          if (!alert.isRead && alert.id != null) alert.id!,
      ];
      if (unreadIds.isEmpty) return;
      final repository = ref.read(nurseryRepositoryProvider);
      for (final id in unreadIds) {
        await repository.markAlertRead(id);
      }
      ref.invalidate(alertsProvider);
      ref.invalidate(dashboardProvider);
    }

    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: () async {
        ref.invalidate(alertsProvider);
      },
      child: alertsState.when(
        data: (alerts) {
          final visibleAlerts = maxItems == null
              ? alerts
              : alerts.take(maxItems!).toList();
          final hiddenCount = alerts.length - visibleAlerts.length;
          final unreadCount = alerts.where((alert) => !alert.isRead).length;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 640;

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  isWide ? 24 : 14,
                  isEmbedded ? 6 : 14,
                  isWide ? 24 : 14,
                  24,
                ),
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: AppTheme.primaryGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEmbedded ? 'Notifikasi Cepat' : 'Notifikasi & Peringatan',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textStrong,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              unreadCount > 0
                                  ? '$unreadCount belum dibaca dari ${alerts.length} data DB'
                                  : '${alerts.length} notifikasi tercatat di database',
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
                      if (unreadCount > 0)
                        IconButton(
                          constraints: const BoxConstraints.tightFor(
                            width: 36,
                            height: 36,
                          ),
                          padding: EdgeInsets.zero,
                          tooltip: 'Tandai semua dibaca',
                          onPressed: () => markAllRead(alerts),
                          icon: const Icon(
                            Icons.mark_email_read_rounded,
                            color: AppTheme.primaryGreen,
                            size: 20,
                          ),
                        ),
                      if (isEmbedded)
                        IconButton(
                          constraints: const BoxConstraints.tightFor(
                            width: 36,
                            height: 36,
                          ),
                          padding: EdgeInsets.zero,
                          tooltip: 'Tutup',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, size: 20),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (alerts.isEmpty)
                    const _EmptyAlertState()
                  else if (isWide && !isEmbedded)
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        for (final alert in visibleAlerts)
                          SizedBox(
                            width: (constraints.maxWidth - 60) / 2,
                            child: _AlertCard(
                              alert: alert,
                              onOpenTarget: onAlertSelected,
                            ),
                          ),
                      ],
                    )
                  else
                    for (final alert in visibleAlerts)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _AlertCard(
                          alert: alert,
                          onOpenTarget: onAlertSelected,
                        ),
                      ),
                  if (hiddenCount > 0 && isEmbedded) ...[
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        '$hiddenCount notifikasi lainnya tersedia',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  if (isEmbedded) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        onPressed: onOpenAll,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Lihat Semua Notifikasi',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ] else if (unreadCount > 0) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => markAllRead(alerts),
                        icon: const Icon(Icons.mark_email_read_rounded),
                        label: const Text('Tandai Semua Sudah Dibaca'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryGreen,
                          side: const BorderSide(color: AppTheme.cardBorder),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: AppTheme.primaryGreen),
          ),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Gagal memuat notifikasi dari API: $error'),
          ),
        ),
      ),
    );
  }
}

class _AlertCard extends ConsumerWidget {
  const _AlertCard({required this.alert, this.onOpenTarget});

  final SystemAlert alert;
  final ValueChanged<SystemAlert>? onOpenTarget;

  Future<void> _markRead(WidgetRef ref) async {
    final id = alert.id;
    if (id == null || alert.isRead) return;
    await ref.read(nurseryRepositoryProvider).markAlertRead(id);
    ref.invalidate(alertsProvider);
    ref.invalidate(dashboardProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCritical = alert.level == 'CRITICAL';
    final color = isCritical ? AppTheme.critical : AppTheme.warning;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await _markRead(ref);
          onOpenTarget?.call(alert);
        },
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: alert.isRead ? Colors.white : AppTheme.mintLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: alert.isRead
                  ? const Color(0xFFE2E8F0)
                  : AppTheme.primaryGreen.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Icon(
                  isCritical
                      ? Icons.error_rounded
                      : Icons.warning_amber_rounded,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alert.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13.5,
                              color: AppTheme.textStrong,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (alert.deviceCode != null) ...[
                          const SizedBox(width: 6),
                          StatusChip(
                            label: alert.deviceCode!,
                            color: AppTheme.primaryGreen,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.message,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM yyyy, HH:mm').format(alert.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        StatusChip(
                          label: isCritical ? 'KRITIS' : 'PERINGATAN',
                          color: color,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                alert.isRead
                    ? Icons.mark_email_read_rounded
                    : Icons.fiber_manual_record_rounded,
                color: alert.isRead ? AppTheme.textMuted : color,
                size: alert.isRead ? 16 : 10,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyAlertState extends StatelessWidget {
  const _EmptyAlertState();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 48,
            color: AppTheme.primaryGreen.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          const Text(
            'Kondisi Aman',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tidak ada alert aktif pada database.\nSemua sensor dan perangkat dalam batas ambang normal.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
