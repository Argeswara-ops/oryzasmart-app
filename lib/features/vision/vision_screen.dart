import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/nursery_models.dart';
import '../../shared/widgets/section_card.dart';
import '../../shared/widgets/status_chip.dart';
import '../dashboard/dashboard_controller.dart';

class VisionScreen extends ConsumerStatefulWidget {
  const VisionScreen({super.key});

  @override
  ConsumerState<VisionScreen> createState() => _VisionScreenState();
}

class _VisionScreenState extends ConsumerState<VisionScreen> {
  String _filter = 'all';
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  Future<void> _pickAndPredict(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1600,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      _selectedImage = image;
      _selectedImageBytes = bytes;
    });
    ref.read(visionPredictionProvider.notifier).clear();
    await ref.read(visionPredictionProvider.notifier).predict(image);
  }

  @override
  Widget build(BuildContext context) {
    final detections = ref.watch(detectionsProvider);
    final selectedDetection = ref.watch(visionSelectedDetectionProvider);
    final prediction = ref.watch(visionPredictionProvider);

    return detections.when(
      data: (items) {
        final focusAlert = ref.watch(visionFocusAlertProvider);
        if (focusAlert != null && items.isNotEmpty) {
          final focusedDetection = _findDetectionForAlert(items, focusAlert);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ref.read(visionFocusAlertProvider.notifier).setAlert(null);
            ref
                .read(visionSelectedDetectionProvider.notifier)
                .select(focusedDetection);
          });
        }

        if (selectedDetection case final selected?) {
          return _DetectionDetailView(detection: selected);
        }

        final filtered = _filter == 'all'
            ? items
            : items.where((item) => item.type == _filter).toList();
        final latest = filtered.isEmpty ? items.first : filtered.first;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _VisionUploadPanel(
              imageBytes: _selectedImageBytes,
              imageName: _selectedImage?.name,
              prediction: prediction,
              onCamera: () => _pickAndPredict(ImageSource.camera),
              onGallery: () => _pickAndPredict(ImageSource.gallery),
            ),
            const SizedBox(height: 12),
            if (items.isNotEmpty) ...[
              _CameraEvidence(detection: latest),
              const SizedBox(height: 12),
              _FilterControl(
                value: _filter,
                onChanged: (value) => setState(() => _filter = value),
              ),
              const SizedBox(height: 12),
            ],
            SectionCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Riwayat deteksi',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textStrong,
                          ),
                        ),
                      ),
                      Text(
                        '${items.isEmpty ? 0 : filtered.length} data',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (items.isEmpty)
                    _EmptyVisionHistory(
                      onRefresh: () => ref.refresh(detectionsProvider),
                    )
                  else if (filtered.isEmpty)
                    const _EmptyListMessage()
                  else
                    for (final item in filtered.take(8))
                      _DetectionHistoryTile(
                        item,
                        onTap: () => ref
                            .read(visionSelectedDetectionProvider.notifier)
                            .select(item),
                      ),
                ],
              ),
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
          child: Text('Gagal memuat kamera vision: $error'),
        ),
      ),
    );
  }
}

class _VisionUploadPanel extends StatelessWidget {
  const _VisionUploadPanel({
    required this.imageBytes,
    required this.imageName,
    required this.prediction,
    required this.onCamera,
    required this.onGallery,
  });

  final Uint8List? imageBytes;
  final String? imageName;
  final AsyncValue<PaddyPrediction?> prediction;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final isLoading = prediction.isLoading;

    return SectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.document_scanner_rounded,
                  color: AppTheme.primaryGreen,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan Tanaman Padi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textStrong,
                      ),
                    ),
                    Text(
                      'Kamera atau galeri',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppTheme.primaryGreen,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
                child: imageBytes == null
                    ? const _UploadPlaceholder()
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(imageBytes!, fit: BoxFit.cover),
                          Positioned(
                            left: 10,
                            bottom: 10,
                            right: 10,
                            child: _ImageNameBadge(
                              label: imageName == null || imageName!.isEmpty
                                  ? 'Foto tanaman'
                                  : imageName!,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: isLoading ? null : onCamera,
                  icon: const Icon(Icons.photo_camera_rounded, size: 18),
                  label: const Text('Scan Foto'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : onGallery,
                  icon: const Icon(Icons.photo_library_rounded, size: 18),
                  label: const Text('Galeri'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          prediction.when(
            data: (result) => result == null
                ? const _PredictionIdle()
                : _PredictionResult(prediction: result),
            loading: () => const _PredictionLoading(),
            error: (error, stackTrace) =>
                _PredictionError(message: _errorText(error)),
          ),
        ],
      ),
    );
  }
}

class _UploadPlaceholder extends StatelessWidget {
  const _UploadPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_photo_alternate_rounded,
            color: AppTheme.textMuted,
            size: 44,
          ),
          SizedBox(height: 8),
          Text(
            'Belum ada foto',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageNameBadge extends StatelessWidget {
  const _ImageNameBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _PredictionIdle extends StatelessWidget {
  const _PredictionIdle();

  @override
  Widget build(BuildContext context) {
    return const _PredictionNotice(
      icon: Icons.image_search_rounded,
      title: 'Hasil prediksi akan tampil di sini',
      color: AppTheme.textMuted,
    );
  }
}

class _PredictionLoading extends StatelessWidget {
  const _PredictionLoading();

  @override
  Widget build(BuildContext context) {
    return const _PredictionNotice(
      icon: Icons.auto_awesome_rounded,
      title: 'Menganalisis foto',
      color: AppTheme.primaryGreen,
    );
  }
}

class _PredictionError extends StatelessWidget {
  const _PredictionError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _PredictionNotice(
      icon: Icons.error_rounded,
      title: message,
      color: AppTheme.critical,
    );
  }
}

class _PredictionNotice extends StatelessWidget {
  const _PredictionNotice({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PredictionResult extends StatelessWidget {
  const _PredictionResult({required this.prediction});

  final PaddyPrediction prediction;

  @override
  Widget build(BuildContext context) {
    final confidence = prediction.confidencePercent;
    final color = _predictionColor(prediction.status, confidence);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.eco_rounded, color: color, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prediction.displayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textStrong,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      prediction.className,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: '${confidence.toStringAsFixed(1)}%',
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: (confidence / 100).clamp(0, 1).toDouble(),
              color: color,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          StatusChip(
            label: prediction.status.replaceAll('_', ' ').toUpperCase(),
            color: color,
          ),
        ],
      ),
    );
  }
}

class _CameraEvidence extends StatelessWidget {
  const _CameraEvidence({required this.detection});

  final Detection detection;

  @override
  Widget build(BuildContext context) {
    final color = _detectionColor(detection.type);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.videocam_rounded,
                  color: AppTheme.teal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detection.cameraId,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textStrong,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      'Snapshot analisis AI',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip(label: 'ONLINE', color: AppTheme.teal, isPulse: true),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: const Color(0xFF111827),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _FieldPreviewPainter()),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _CameraBadge(label: 'REC'),
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: _CameraBadge(label: '1080p'),
                    ),
                    Positioned(
                      left: 52,
                      top: 42,
                      width: 142,
                      height: 82,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: color, width: 2),
                          borderRadius: BorderRadius.circular(6),
                          color: color.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 52,
                      top: 18,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 210),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '${detection.className} ${(detection.confidence * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _EvidenceMetric(
                  label: 'Kelas',
                  value: detection.className,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _EvidenceMetric(
                  label: 'Waktu',
                  value: DateFormat(
                    'dd MMM HH:mm',
                  ).format(detection.detectedAt),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              StatusChip(label: detection.type.toUpperCase(), color: color),
              const SizedBox(width: 8),
              StatusChip(
                label: '${(detection.confidence * 100).round()}% confidence',
                color: AppTheme.primaryGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterControl extends StatelessWidget {
  const _FilterControl({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final filters = const [
      ('all', 'Semua'),
      ('disease', 'Penyakit'),
      ('pest', 'Hama'),
      ('healthy', 'Sehat'),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final filter in filters)
          ChoiceChip(
            label: Text(filter.$2),
            selected: value == filter.$1,
            labelStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: value == filter.$1 ? Colors.white : AppTheme.textMuted,
            ),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            selectedColor: AppTheme.primaryGreen,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: value == filter.$1
                  ? AppTheme.primaryGreen
                  : AppTheme.cardBorder,
            ),
            onSelected: (_) => onChanged(filter.$1),
          ),
      ],
    );
  }
}

class _DetectionHistoryTile extends StatelessWidget {
  const _DetectionHistoryTile(this.item, {this.onTap});

  final Detection item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = _detectionColor(item.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.18)),
                  ),
                  child: Icon(
                    _detectionIcon(item.type),
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.className,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textStrong,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${DateFormat('dd MMM HH:mm').format(item.detectedAt)} - ${item.cameraId}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusChip(
                  label: '${(item.confidence * 100).round()}%',
                  color: color,
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetectionDetailView extends StatelessWidget {
  const _DetectionDetailView({required this.detection});

  final Detection detection;

  @override
  Widget build(BuildContext context) {
    final color = _detectionColor(detection.type);
    final date = DateFormat('dd MMM, HH:mm').format(detection.detectedAt);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _CameraEvidence(detection: detection),
        const SizedBox(height: 12),
        SectionCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withValues(alpha: 0.18)),
                    ),
                    child: Icon(_detectionIcon(detection.type), color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detection.className,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textStrong,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          detection.image.isEmpty ? '-' : detection.image,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
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
              const SizedBox(height: 12),
              _DetectionDataGrid(
                items: [
                  _DetectionDataItem(
                    icon: Icons.category_rounded,
                    label: 'Tipe',
                    value: detection.type.toUpperCase(),
                    color: color,
                  ),
                  _DetectionDataItem(
                    icon: Icons.percent_rounded,
                    label: 'Confidence',
                    value: '${(detection.confidence * 100).round()}%',
                    color: AppTheme.primaryGreen,
                  ),
                  _DetectionDataItem(
                    icon: Icons.videocam_rounded,
                    label: 'Kamera',
                    value: detection.cameraId,
                    color: AppTheme.teal,
                  ),
                  _DetectionDataItem(
                    icon: Icons.schedule_rounded,
                    label: 'Waktu',
                    value: date,
                    color: AppTheme.infoBlue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetectionDataGrid extends StatelessWidget {
  const _DetectionDataGrid({required this.items});

  final List<_DetectionDataItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: compact ? 1.22 : 1.42,
          ),
          itemBuilder: (context, index) =>
              _DetectionDataTile(item: items[index]),
        );
      },
    );
  }
}

class _DetectionDataItem {
  const _DetectionDataItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
}

class _DetectionDataTile extends StatelessWidget {
  const _DetectionDataTile({required this.item});

  final _DetectionDataItem item;

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
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, color: item.color, size: 17),
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
                fontSize: 15,
                color: AppTheme.textStrong,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceMetric extends StatelessWidget {
  const _EvidenceMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textStrong,
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

class _CameraBadge extends StatelessWidget {
  const _CameraBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(6),
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

class _EmptyVisionHistory extends StatelessWidget {
  const _EmptyVisionHistory({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Belum ada riwayat vision',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

class _EmptyListMessage extends StatelessWidget {
  const _EmptyListMessage();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Text(
          'Tidak ada data untuk filter ini',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      ),
    );
  }
}

class _FieldPreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()..color = const Color(0xFF1F2937);
    final bed = Paint()..color = const Color(0xFF064E3B);
    final rowPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.34)
      ..strokeWidth = 2;

    canvas.drawRect(Offset.zero & size, sky);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.35, size.width, size.height * 0.65),
      bed,
    );

    for (var i = 0; i < 8; i++) {
      final y = size.height * (0.42 + i * 0.07);
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 20), rowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Color _detectionColor(String type) {
  return switch (type) {
    'healthy' => AppTheme.primaryGreen,
    'disease' => AppTheme.critical,
    'pest' => AppTheme.warning,
    _ => AppTheme.textMuted,
  };
}

IconData _detectionIcon(String type) {
  return switch (type) {
    'healthy' => Icons.verified_rounded,
    'disease' => Icons.coronavirus_rounded,
    'pest' => Icons.bug_report_rounded,
    _ => Icons.help_rounded,
  };
}

Color _predictionColor(String status, double confidence) {
  final normalized = status.toLowerCase();
  if (normalized.contains('high') || confidence >= 80) {
    return AppTheme.primaryGreen;
  }
  if (normalized.contains('medium') || confidence >= 50) {
    return AppTheme.warning;
  }
  return AppTheme.critical;
}

String _errorText(Object error) {
  final text = error.toString();
  return text.startsWith('Exception: ') ? text.substring(11) : text;
}

Detection _findDetectionForAlert(
  List<Detection> detections,
  SystemAlert alert,
) {
  final alertText = '${alert.title} ${alert.message}'.toLowerCase();
  var bestDetection = detections.first;
  var bestScore = -1;

  for (final detection in detections) {
    final className = detection.className.toLowerCase();
    final cameraId = detection.cameraId.toLowerCase();
    final type = detection.type.toLowerCase();
    var score = 0;

    if (alertText.contains(className)) score += 4;
    if (alertText.contains(cameraId)) score += 3;
    if (alertText.contains(type)) score += 2;
    for (final token in className.split(RegExp(r'\s+'))) {
      if (token.length > 2 && alertText.contains(token)) score++;
    }

    if (score > bestScore) {
      bestScore = score;
      bestDetection = detection;
    }
  }

  return bestDetection;
}
