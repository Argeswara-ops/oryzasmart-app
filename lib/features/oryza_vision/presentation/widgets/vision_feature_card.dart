import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/vision_models.dart';
import '../screens/scan_screen.dart';

class OryzaVisionFeatureCard extends StatelessWidget {
  const OryzaVisionFeatureCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B6B47), Color(0xFF15966A)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.center_focus_strong_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Oryza Vision',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Identifikasi penyakit dan hama secara offline di perangkat.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .85),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ScanButton(
                  task: VisionTask.disease,
                  icon: Icons.eco_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ScanButton(
                  task: VisionTask.pest,
                  icon: Icons.bug_report_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.task, required this.icon});
  final VisionTask task;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => ScanScreen(task: task))),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primaryGreen, size: 25),
              const SizedBox(height: 5),
              Text(
                'Scan ${task.title}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textStrong,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
