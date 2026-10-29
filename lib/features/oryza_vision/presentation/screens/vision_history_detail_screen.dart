import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/vision_knowledge.dart';
import '../../data/repositories/vision_history_repository.dart';
import '../../domain/entities/vision_models.dart';

class VisionHistoryDetailScreen extends StatelessWidget {
  const VisionHistoryDetailScreen({super.key, required this.record});

  final VisionScanRecord record;

  @override
  Widget build(BuildContext context) {
    final knowledge = knowledgeFor(record.label);
    return Scaffold(
      backgroundColor: AppTheme.bgMint,
      appBar: AppBar(title: const Text('Detail Riwayat Scan')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 28 : 16,
                vertical: 14,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 9,
                              child: _ImageHero(record: record),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 11,
                              child: _DetailContent(
                                record: record,
                                knowledge: knowledge,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _ImageHero(record: record),
                            const SizedBox(height: 14),
                            _DetailContent(
                              record: record,
                              knowledge: knowledge,
                            ),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ImageHero extends StatelessWidget {
  const _ImageHero({required this.record});

  final VisionScanRecord record;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _HistoryImage(record: record),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xB3000000)],
                  stops: [.48, 1],
                ),
              ),
            ),
            Positioned(
              left: 14,
              top: 14,
              child: _Pill(
                icon: record.task == VisionTask.pest
                    ? Icons.bug_report_rounded
                    : Icons.eco_rounded,
                label: 'Scan ${record.task.title}',
                foreground: Colors.white,
                background: Colors.black.withValues(alpha: .48),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 15,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Confidence model',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        Text(
                          '${(record.confidence * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _SyncPill(status: record.syncStatus),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.record, required this.knowledge});

  final VisionScanRecord record;
  final VisionKnowledge knowledge;

  @override
  Widget build(BuildContext context) {
    final confident = record.confidence >= .65;
    final accent = confident ? AppTheme.primaryGreen : const Color(0xFFD97706);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .11),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      confident
                          ? Icons.task_alt_rounded
                          : Icons.help_outline_rounded,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          confident
                              ? '${record.task.title} teridentifikasi'
                              : 'Hasil belum meyakinkan',
                          style: TextStyle(
                            color: accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          knowledge.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textStrong,
                            fontSize: 21,
                            height: 1.15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: record.confidence.clamp(0, 1),
                  minHeight: 8,
                  color: accent,
                  backgroundColor: const Color(0xFFEFF4F1),
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 370;
                  final cards = [
                    _Metric(
                      icon: Icons.calendar_today_rounded,
                      label: 'Tanggal',
                      value: DateFormat('dd MMM yyyy').format(record.scannedAt),
                    ),
                    _Metric(
                      icon: Icons.schedule_rounded,
                      label: 'Waktu',
                      value: DateFormat('HH:mm').format(record.scannedAt),
                    ),
                    _Metric(
                      icon: Icons.category_outlined,
                      label: 'Jenis scan',
                      value: record.task.title,
                    ),
                    _Metric(
                      icon: record.syncStatus == ScanSyncStatus.synced
                          ? Icons.cloud_done_outlined
                          : Icons.cloud_upload_outlined,
                      label: 'Penyimpanan',
                      value: record.syncStatus == ScanSyncStatus.synced
                          ? 'Lokal & database'
                          : 'Lokal • menunggu',
                    ),
                  ];
                  if (compact) {
                    return Column(
                      children: [
                        for (final card in cards) ...[
                          card,
                          if (card != cards.last) const SizedBox(height: 8),
                        ],
                      ],
                    );
                  }
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2.55,
                    children: cards,
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _InformationCard(
          icon: Icons.info_outline_rounded,
          title: 'Tentang hasil',
          body: knowledge.description,
        ),
        const SizedBox(height: 10),
        _InformationCard(
          icon: Icons.assignment_turned_in_outlined,
          title: 'Pemeriksaan awal',
          body: knowledge.recommendation,
        ),
        const SizedBox(height: 10),
        _SurfaceCard(
          color: const Color(0xFFFFFBEB),
          borderColor: const Color(0xFFFDE68A),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.health_and_safety_outlined, color: Color(0xFFD97706)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Gunakan hasil sebagai skrining awal. Konfirmasikan kondisi tanaman kepada petugas pertanian sebelum melakukan penanganan.',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 11,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sumber informasi: ${knowledge.source}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 9,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textStrong,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
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

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textStrong,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    height: 1.5,
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

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.color = Colors.white,
    this.borderColor = const Color(0xFFE2E8F0),
  });

  final Widget child;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: .035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SyncPill extends StatelessWidget {
  const _SyncPill({required this.status});

  final ScanSyncStatus status;

  @override
  Widget build(BuildContext context) {
    final synced = status == ScanSyncStatus.synced;
    return _Pill(
      icon: synced ? Icons.cloud_done_rounded : Icons.cloud_upload_rounded,
      label: synced ? 'Tersinkron' : 'Tersimpan lokal',
      foreground: Colors.white,
      background: synced
          ? AppTheme.primaryGreen.withValues(alpha: .92)
          : const Color(0xFFD97706).withValues(alpha: .92),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryImage extends StatelessWidget {
  const _HistoryImage({required this.record});

  final VisionScanRecord record;

  @override
  Widget build(BuildContext context) {
    final localPath = record.localImagePath;
    if (localPath != null) {
      final file = File(localPath);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }
    final remoteUrl = AppConfig.resolveImageUrl(record.remoteImageUrl);
    if (remoteUrl.isNotEmpty) {
      return Image.network(
        remoteUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return ColoredBox(
            color: const Color(0xFFF1F5F9),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          );
        },
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => ColoredBox(
    color: const Color(0xFFE8F3EE),
    child: Center(
      child: Icon(
        record.task == VisionTask.pest
            ? Icons.bug_report_rounded
            : Icons.eco_rounded,
        size: 64,
        color: AppTheme.primaryGreen.withValues(alpha: .55),
      ),
    ),
  );
}
