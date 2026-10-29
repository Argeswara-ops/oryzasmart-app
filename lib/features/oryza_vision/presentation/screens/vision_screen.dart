import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../data/models/vision_knowledge.dart';
import '../../data/repositories/vision_history_repository.dart';
import '../../domain/entities/vision_models.dart';
import '../controllers/vision_history_controller.dart';
import '../widgets/vision_feature_card.dart';
import 'vision_history_detail_screen.dart';

export 'vision_history_detail_screen.dart';

class VisionScreen extends ConsumerStatefulWidget {
  const VisionScreen({super.key});

  @override
  ConsumerState<VisionScreen> createState() => _VisionScreenState();
}

class _VisionScreenState extends ConsumerState<VisionScreen> {
  VisionTask? _filter;

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(visionHistoryProvider);
    return RefreshIndicator(
      onRefresh: () => ref.read(visionHistoryProvider.notifier).refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          history.when(
            data: (state) => VisionConnectionNotice(state: state),
            loading: () => const VisionConnectionNotice(
              state: VisionHistoryState(records: []),
            ),
            error: (error, _) => VisionConnectionNotice(
              state: VisionHistoryState(
                records: const [],
                networkStatus: VisionNetworkStatus.offline,
                syncMessage: 'Riwayat lokal gagal dibuka: $error',
              ),
            ),
          ),
          const SizedBox(height: 12),
          const OryzaVisionFeatureCard(),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Riwayat scan manual',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textStrong,
                  ),
                ),
              ),
              PopupMenuButton<VisionTask?>(
                tooltip: 'Filter riwayat',
                initialValue: _filter,
                onSelected: (value) => setState(() => _filter = value),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: null, child: Text('Semua scan')),
                  PopupMenuItem(
                    value: VisionTask.disease,
                    child: Text('Penyakit'),
                  ),
                  PopupMenuItem(value: VisionTask.pest, child: Text('Hama')),
                ],
                icon: const Icon(Icons.filter_list_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          history.when(
            data: (state) => VisionHistoryList(
              records: state.records
                  .where((record) => _filter == null || record.task == _filter)
                  .toList(),
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              ),
            ),
            error: (error, _) => _EmptyHistory(message: '$error'),
          ),
        ],
      ),
    );
  }
}

class VisionConnectionBanner extends StatelessWidget {
  const VisionConnectionBanner({super.key, required this.state, this.onClose});
  final VisionHistoryState state;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final offline = state.networkStatus == VisionNetworkStatus.offline;
    final checking = state.networkStatus == VisionNetworkStatus.checking;
    final color = offline
        ? const Color(0xFFD97706)
        : checking
        ? AppTheme.infoBlue
        : AppTheme.primaryGreen;
    final title = offline
        ? 'Anda sedang offline'
        : checking
        ? 'Memeriksa koneksi…'
        : 'Anda online';
    final message =
        state.syncMessage ??
        (offline
            ? 'Scan baru akan disimpan lokal dan disinkronkan saat online.'
            : checking
            ? 'Riwayat lokal tetap dapat digunakan.'
            : 'Riwayat scan akan disinkronkan otomatis.');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: .2)),
      ),
      child: Row(
        children: [
          if (state.isSyncing || checking)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          else
            Icon(
              offline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
              color: color,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (state.pendingCount > 0)
            Text(
              '${state.pendingCount} pending',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          if (onClose != null) ...[
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Tutup notifikasi',
              visualDensity: VisualDensity.compact,
              onPressed: onClose,
              icon: Icon(Icons.close_rounded, size: 18, color: color),
            ),
          ],
        ],
      ),
    );
  }
}

class VisionConnectionNotice extends StatefulWidget {
  const VisionConnectionNotice({
    super.key,
    required this.state,
    this.visibleDuration = const Duration(seconds: 6),
  });

  final VisionHistoryState state;
  final Duration visibleDuration;

  @override
  State<VisionConnectionNotice> createState() => _VisionConnectionNoticeState();
}

class _VisionConnectionNoticeState extends State<VisionConnectionNotice> {
  Timer? _hideTimer;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _scheduleHide();
  }

  @override
  void didUpdateWidget(covariant VisionConnectionNotice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_noticeKey(oldWidget.state) != _noticeKey(widget.state)) {
      _visible = true;
      _scheduleHide();
    }
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    if (widget.state.isSyncing ||
        widget.state.networkStatus == VisionNetworkStatus.checking) {
      return;
    }
    _hideTimer = Timer(widget.visibleDuration, () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: _visible
          ? VisionConnectionBanner(
              key: ValueKey(_noticeKey(widget.state)),
              state: widget.state,
              onClose: () => setState(() => _visible = false),
            )
          : const SizedBox.shrink(key: ValueKey('hidden')),
    );
  }
}

String _noticeKey(VisionHistoryState state) =>
    '${state.networkStatus.name}-${state.isSyncing}-${state.pendingCount}-${state.syncMessage}';

class VisionHistoryList extends StatelessWidget {
  const VisionHistoryList({super.key, required this.records});
  final List<VisionScanRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const _EmptyHistory(
        message: 'Belum ada scan manual. Pilih Scan Penyakit atau Scan Hama.',
      );
    }
    return Column(
      children: [
        for (final record in records)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _HistoryTile(record: record),
          ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.record});
  final VisionScanRecord record;

  @override
  Widget build(BuildContext context) {
    final knowledge = knowledgeFor(record.label);
    final synced = record.syncStatus == ScanSyncStatus.synced;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => VisionHistoryDetailScreen(record: record),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _ScanImage(record: record, width: 58, height: 58),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      knowledge.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textStrong,
                      ),
                    ),
                    Text(
                      '${record.task.title} • ${DateFormat('dd MMM yyyy, HH:mm').format(record.scannedAt)}',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          '${(record.confidence * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          synced
                              ? Icons.cloud_done_outlined
                              : Icons.cloud_upload_outlined,
                          size: 14,
                          color: synced
                              ? AppTheme.primaryGreen
                              : const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          synced ? 'Tersinkron' : 'Menunggu sinkron',
                          style: TextStyle(
                            fontSize: 10,
                            color: synced
                                ? AppTheme.primaryGreen
                                : const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LegacyVisionHistoryDetailScreen extends StatelessWidget {
  const LegacyVisionHistoryDetailScreen({super.key, required this.record});
  final VisionScanRecord record;

  @override
  Widget build(BuildContext context) {
    final knowledge = knowledgeFor(record.label);
    final synced = record.syncStatus == ScanSyncStatus.synced;
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Riwayat Scan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: _ScanImage(
                record: record,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  knowledge.name,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textStrong,
                  ),
                ),
                Text(
                  record.label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                _DetailRow(label: 'Jenis scan', value: record.task.title),
                _DetailRow(
                  label: 'Confidence',
                  value: '${(record.confidence * 100).toStringAsFixed(1)}%',
                ),
                _DetailRow(
                  label: 'Waktu scan',
                  value: DateFormat(
                    'dd MMMM yyyy, HH:mm',
                  ).format(record.scannedAt),
                ),
                _DetailRow(
                  label: 'Penyimpanan',
                  value: synced
                      ? 'Lokal & database'
                      : 'Lokal, menunggu sinkron',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tentang hasil',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textStrong,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  knowledge.description,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Pemeriksaan awal',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textStrong,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  knowledge.recommendation,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    height: 1.45,
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: AppTheme.textMuted)),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppTheme.textStrong,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ScanImage extends StatelessWidget {
  const _ScanImage({
    required this.record,
    required this.width,
    required this.height,
  });
  final VisionScanRecord record;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final path = record.localImagePath;
    final local = path == null ? null : File(path);
    final placeholder = Container(
      width: width,
      height: height,
      color: const Color(0xFFF1F5F9),
      child: Icon(
        record.task == VisionTask.pest
            ? Icons.bug_report_rounded
            : Icons.eco_rounded,
        color: AppTheme.textMuted,
      ),
    );
    if (local != null && local.existsSync()) {
      return Image.file(local, width: width, height: height, fit: BoxFit.cover);
    }
    final remote = AppConfig.resolveImageUrl(record.remoteImageUrl);
    if (remote.isNotEmpty) {
      return Image.network(
        remote,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      );
    }
    return placeholder;
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const Icon(
            Icons.history_rounded,
            size: 38,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textMuted),
          ),
        ],
      ),
    ),
  );
}
