import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/nursery_models.dart';
import '../../shared/repositories/nursery_repository.dart';
import '../alerts/alerts_screen.dart';
import '../dashboard/dashboard_controller.dart';
import '../dashboard/dashboard_screen.dart';
import '../devices/devices_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';
import '../oryza_vision/presentation/screens/vision_screen.dart';

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
    setState(() {
      _index = target;
      _showNotifications = false;
    });
  }

  int _targetIndexForAlert(SystemAlert alert) {
    final text = '${alert.title} ${alert.message}'.toLowerCase();
    if (text.contains('riwayat') || text.contains('history')) return 3;
    // Alert perangkat tetap diarahkan ke dashboard. Tab Vision khusus scan
    // manual dari kamera/galeri perangkat pengguna.
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);
    final connectionStatus =
        ref.watch(connectionStatusProvider).value ??
        AppConnectionStatus.checking;
    final alertCount = dashboardState.maybeWhen(
      data: (data) => data.unreadAlerts,
      orElse: () => 0,
    );

    PreferredSizeWidget buildAppBar() {
      final titleWidget = _showNotifications
          ? const _AppBarTitle(title: 'Notifikasi')
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
        leading: _showNotifications
            ? IconButton(
                tooltip: 'Kembali',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  setState(() => _showNotifications = false);
                },
              )
            : null,
        title: titleWidget,
        actions: _showNotifications
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
        child: Column(
          children: [
            _ConnectionBanner(status: connectionStatus),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: body,
              ),
            ),
          ],
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

class _ConnectionBanner extends ConsumerWidget {
  const _ConnectionBanner({required this.status});

  final AppConnectionStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(apiClientProvider);
    final offline = status == AppConnectionStatus.offline;
    final checking = status == AppConnectionStatus.checking;
    final color = offline
        ? const Color(0xFFD97706)
        : checking
        ? const Color(0xFF2563EB)
        : AppTheme.primaryGreen;

    final nowTime = DateFormat('HH:mm:ss').format(DateTime.now());
    final onlineTime = client.lastOnlineTime != null
        ? DateFormat('HH:mm:ss').format(client.lastOnlineTime!)
        : nowTime;
    final offlineTime = client.lastOfflineTime != null
        ? DateFormat('HH:mm:ss').format(client.lastOfflineTime!)
        : nowTime;

    final message = offline
        ? 'ANDA OFFLINE • Terputus sejak $offlineTime WIB • Menampilkan cache data lokal'
        : checking
        ? 'MEMERIKSA KONEKSI • Menghubungkan ke backend server...'
        : 'ANDA ONLINE • Data diperbarui pukul $onlineTime WIB • Sinkronisasi realtime aktif';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      color: color.withValues(alpha: 0.10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Row(
        children: [
          Icon(
            offline
                ? Icons.cloud_off_rounded
                : checking
                ? Icons.sync_rounded
                : Icons.cloud_done_rounded,
            size: 17,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MarqueeTicker(
              text: message,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarqueeTicker extends StatefulWidget {
  const _MarqueeTicker({required this.text, required this.style});
  final String text;
  final TextStyle style;

  @override
  State<_MarqueeTicker> createState() => _MarqueeTickerState();
}

class _MarqueeTickerState extends State<_MarqueeTicker>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..addListener(() {
        if (_scrollController.hasClients) {
          final maxScroll = _scrollController.position.maxScrollExtent;
          if (maxScroll > 0) {
            _scrollController.jumpTo(_animController.value * maxScroll);
          }
        }
      });
    _animController.repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final display = '${widget.text}       ★       ${widget.text}       ★       ';
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(display, style: widget.style),
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
