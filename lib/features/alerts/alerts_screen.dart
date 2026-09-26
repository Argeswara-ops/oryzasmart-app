import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/api/api_providers.dart';
import '../../shared/models/nursery_models.dart';
import '../../shared/widgets/section_card.dart';
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
      height: MediaQuery.sizeOf(context).height * 0.62,
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
              maxItems: 5,
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
    final dashboard = ref.watch(dashboardProvider);

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
      ref.invalidate(dashboardProvider);
    }

    return dashboard.when(
      data: (snapshot) {
        final alerts = snapshot.alerts;
        final visibleAlerts = maxItems == null
            ? alerts
            : alerts.take(maxItems!).toList();
        final hiddenCount = alerts.length - visibleAlerts.length;
        final unreadCount = alerts.where((alert) => !alert.isRead).length;
        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 20),
          children: [
            SectionCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isEmbedded) ...[
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
                                'Notifikasi',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.textStrong,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (unreadCount > 0)
                                Text(
                                  '$unreadCount belum dibaca dari ${alerts.length} data',
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          constraints: const BoxConstraints.tightFor(
                            width: 36,
                            height: 36,
                          ),
                          padding: EdgeInsets.zero,
                          tooltip: 'Tandai semua dibaca',
                          onPressed: unreadCount == 0
                              ? null
                              : () => markAllRead(alerts),
                          icon: const Icon(
                            Icons.mark_email_read_rounded,
                            size: 20,
                          ),
                        ),
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
                  ] else ...[
                    if (unreadCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          '$unreadCount belum dibaca dari ${alerts.length} data',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                  if (alerts.isEmpty)
                    const _EmptyAlertState()
                  else
                    for (final alert in visibleAlerts)
                      _AlertCard(alert: alert, onOpenTarget: onAlertSelected),
                  if (hiddenCount > 0 && isEmbedded) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$hiddenCount notifikasi lainnya',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (isEmbedded) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: onOpenAll,
                        child: const Text(
                          'Lihat semua',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ] else if (unreadCount > 0) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => markAllRead(alerts),
                        icon: const Icon(Icons.mark_email_read_rounded),
                        label: const Text('Tandai semua dibaca'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryGreen,
                          side: const BorderSide(color: AppTheme.cardBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
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
          child: Text('Gagal memuat notifikasi: $error'),
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
    ref.invalidate(dashboardProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCritical = alert.level == 'CRITICAL';
    final color = isCritical ? AppTheme.critical : AppTheme.warning;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await _markRead(ref);
            onOpenTarget?.call(alert);
          },
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: alert.isRead
                  ? const Color(0xFFF8FAFC)
                  : AppTheme.mintLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: alert.isRead
                    ? const Color(0xFFE2E8F0)
                    : AppTheme.primaryGreen.withValues(alpha: 0.28),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.18)),
                  ),
                  child: Icon(
                    isCritical
                        ? Icons.error_rounded
                        : Icons.warning_amber_rounded,
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: AppTheme.textStrong,
                          height: 1.15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        alert.message,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        DateFormat('dd MMM, HH:mm').format(alert.createdAt),
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      alert.isRead
                          ? Icons.mark_email_read_rounded
                          : Icons.fiber_manual_record_rounded,
                      color: alert.isRead ? AppTheme.textMuted : color,
                      size: alert.isRead ? 16 : 10,
                    ),
                    const SizedBox(height: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.textMuted,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 42,
            color: AppTheme.primaryGreen.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 10),
          const Text(
            'Aman',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 3),
          const Text(
            'Tidak ada alert aktif',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
