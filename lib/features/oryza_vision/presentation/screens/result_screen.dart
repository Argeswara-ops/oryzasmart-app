import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/vision_knowledge.dart';
import '../../domain/entities/vision_models.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.imageBytes,
    required this.prediction,
    required this.onScanAgain,
    this.confidenceThreshold = 0.65,
  });

  final Uint8List imageBytes;
  final VisionPrediction prediction;
  final VoidCallback onScanAgain;
  final double confidenceThreshold;

  @override
  Widget build(BuildContext context) {
    final knowledge = knowledgeFor(prediction.label);
    final confident = prediction.probability >= confidenceThreshold;
    final color = confident ? AppTheme.primaryGreen : const Color(0xFFD97706);
    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Identifikasi')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.memory(imageBytes, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: .2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    confident
                        ? '${prediction.task.title} teridentifikasi'
                        : 'Hasil belum meyakinkan',
                    style: TextStyle(color: color, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    knowledge.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textStrong,
                    ),
                  ),
                  Text(
                    prediction.label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: prediction.probability,
                            minHeight: 9,
                            color: color,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(prediction.probability * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: color,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _InfoCard(
              icon: Icons.info_outline_rounded,
              title: 'Tentang hasil',
              body: knowledge.description,
            ),
            const SizedBox(height: 10),
            _InfoCard(
              icon: Icons.assignment_turned_in_outlined,
              title: 'Pemeriksaan awal',
              body: knowledge.recommendation,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 7, 4, 0),
              child: Text(
                'Sumber informasi: ${knowledge.source}',
                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 10),
            const _InfoCard(
              icon: Icons.verified_user_outlined,
              title: 'Catatan keselamatan',
              body:
                  'Konfirmasikan hasil pada petugas pertanian. Jangan menentukan atau mengubah penggunaan pestisida hanya berdasarkan hasil aplikasi.',
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onScanAgain,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Scan Ulang'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryGreen, size: 21),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textStrong,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
