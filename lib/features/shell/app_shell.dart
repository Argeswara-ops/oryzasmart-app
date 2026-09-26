import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/nursery_models.dart';
import '../../shared/repositories/nursery_repository.dart';
import '../alerts/alerts_screen.dart';
import '../dashboard/dashboard_controller.dart';
import '../dashboard/dashboard_screen.dart';
import '../devices/devices_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';
import '../vision/vision_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.user, required this.onLogout});

  final AuthUser user;
  final Future<void> Function() onLogout;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;
  bool _showNotifications = false;

  void _openNotificationsPage() {
    setState(() => _showNotifications = true);
  }

  void _openAlertTarget(SystemAlert alert) {
    final target = _targetIndexForAlert(alert);
    if (target == 2) {
      ref.read(visionFocusAlertProvider.notifier).setAlert(alert);
    }
    setState(() {
      _index = target;
      _showNotifications = false;
    });
  }

  int _targetIndexForAlert(SystemAlert alert) {
    final text = '${alert.title} ${alert.message}'.toLowerCase();
    if (text.contains('deteksi') ||
        text.contains('camera') ||
        text.contains('cam-') ||
        text.contains('rice') ||
        text.contains('blast') ||
        text.contains('hama') ||
        text.contains('penyakit')) {
      return 2;
    }
    if (text.contains('riwayat') || text.contains('history')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);
    final selectedDetection = ref.watch(visionSelectedDetectionProvider);
    final isVisionDetail =
        !_showNotifications && _index == 2 && selectedDetection != null;
    final alertCount = dashboardState.maybeWhen(
      data: (data) => data.unreadAlerts,
      orElse: () => 0,
    );

    PreferredSizeWidget buildAppBar() {
      final titleWidget = _showNotifications
          ? const _AppBarTitle(title: 'Notifikasi')
          : isVisionDetail
          ? const _AppBarTitle(title: 'Detail Deteksi')
          : switch (_index) {
              0 => const _BrandTitle(),
              1 => const _AppBarTitle(title: 'Device'),
              2 => const _AppBarTitle(title: 'Vision'),
              3 => const _AppBarTitle(title: 'Riwayat'),
              4 => const _AppBarTitle(title: 'Settings'),
              _ => const Text('ORYZA SMART'),
            };

      return AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 16,
        leading: _showNotifications || isVisionDetail
            ? IconButton(
                tooltip: 'Kembali',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  if (isVisionDetail) {
                    ref
                        .read(visionSelectedDetectionProvider.notifier)
                        .select(null);
                    return;
                  }
                  setState(() => _showNotifications = false);
                },
              )
            : null,
        title: titleWidget,
        actions: _showNotifications || isVisionDetail
            ? null
            : [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        constraints: const BoxConstraints.tightFor(
                          width: 38,
                          height: 38,
                        ),
                        padding: EdgeInsets.zero,
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFF8FAFC),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                            side: const BorderSide(color: AppTheme.cardBorder),
                          ),
                        ),
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: Color(0xFF334155),
                          size: 21,
                        ),
                        tooltip: 'Notifikasi',
                        onPressed: () => showAlertsBottomSheet(
                          context,
                          onOpenAll: _openNotificationsPage,
                          onAlertSelected: _openAlertTarget,
                        ),
                      ),
                      if (alertCount > 0)
                        Positioned(
                          right: -1,
                          top: -1,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 15,
                              minHeight: 15,
                            ),
                            child: Text(
                              '$alertCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
      );
    }

    final screens = [
      DashboardScreen(user: widget.user),
      const DevicesScreen(),
      const VisionScreen(),
      const HistoryScreen(),
      SettingsScreen(user: widget.user, onLogout: widget.onLogout),
    ];
    final body = _showNotifications
        ? AlertsScreen(onAlertSelected: _openAlertTarget)
        : screens[_index];

    return Scaffold(
      appBar: buildAppBar(),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: body,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          height: 58,
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() {
            ref.read(visionSelectedDetectionProvider.notifier).select(null);
            _index = value;
            _showNotifications = false;
          }),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Dasbor',
            ),
            NavigationDestination(
              icon: Icon(Icons.sensors_outlined),
              selectedIcon: Icon(Icons.sensors_rounded),
              label: 'Device',
            ),
            NavigationDestination(
              icon: Icon(Icons.center_focus_weak_rounded),
              selectedIcon: Icon(Icons.center_focus_strong_rounded),
              label: 'Vision',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics_rounded),
              label: 'Riwayat',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_outlined),
              selectedIcon: Icon(Icons.tune_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.grass_rounded,
            color: AppTheme.primaryGreen,
            size: 20,
          ),
        ),
        const SizedBox(width: 9),
        const Expanded(
          child: Text(
            'ORYZA SMART',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.textStrong,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0xFF0F172A),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
