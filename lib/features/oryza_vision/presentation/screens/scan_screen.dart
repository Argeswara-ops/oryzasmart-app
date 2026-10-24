import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/services/vision_model_service.dart';
import '../../domain/entities/vision_models.dart';
import '../controllers/vision_history_controller.dart';
import 'result_screen.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key, required this.task});
  final VisionTask task;

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final _picker = ImagePicker();
  final _model = VisionModelService();
  bool _processing = false;
  String? _error;

  Future<void> _select(ImageSource source) async {
    if (_processing) return;
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1600,
        maxHeight: 1600,
        requestFullMetadata: true,
      );
      if (file == null || !mounted) return;
      setState(() {
        _processing = true;
        _error = null;
      });
      final Uint8List bytes = await file.readAsBytes();
      if (bytes.isEmpty) throw const FormatException('File gambar kosong.');
      final result = await _model.classify(bytes, widget.task);
      final record = await ref
          .read(visionHistoryRepositoryProvider)
          .saveLocal(result, bytes);
      await ref.read(visionHistoryProvider.notifier).addLocal(record);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ResultScreen(
            imageBytes: bytes,
            prediction: result,
            onScanAgain: () => Navigator.of(context).pop(),
          ),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.task.scanTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              height: 210,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppTheme.primaryGreen.withValues(alpha: .18),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.task == VisionTask.disease
                        ? Icons.eco_rounded
                        : Icons.bug_report_rounded,
                    size: 64,
                    color: AppTheme.primaryGreen,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.task.scanTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textStrong,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Ambil foto yang terang, fokus, dan memperlihatkan objek utama dengan jelas.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textMuted, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _processing ? null : () => _select(ImageSource.camera),
              icon: const Icon(Icons.photo_camera_rounded),
              label: const Text('Buka Kamera'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _processing
                  ? null
                  : () => _select(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_rounded),
              label: const Text('Pilih dari Galeri'),
            ),
            if (_processing) ...[
              const SizedBox(height: 24),
              const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              ),
              const SizedBox(height: 10),
              const Text(
                'Menyiapkan gambar dan menjalankan model di perangkat…',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 18),
              _ErrorMessage(message: _error!),
            ],
            const SizedBox(height: 22),
            const Text(
              'Hasil AI adalah alat bantu skrining, bukan diagnosis pasti. Foto dari objek di luar kelas model tetap dapat memperoleh prediksi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                height: 1.45,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.critical.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: AppTheme.critical),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: AppTheme.critical,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

String _friendlyError(Object error) {
  final text = error
      .toString()
      .replaceFirst('Bad state: ', '')
      .replaceFirst('FormatException: ', '');
  if (text.contains('camera_access_denied')) {
    return 'Izin kamera ditolak. Aktifkan izin kamera dari pengaturan perangkat.';
  }
  if (text.contains('photo_access_denied')) {
    return 'Izin galeri ditolak. Aktifkan izin foto dari pengaturan perangkat.';
  }
  return 'Analisis gagal: $text';
}
