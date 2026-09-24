import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../shared/widgets/section_card.dart';
import '../../shared/widgets/status_chip.dart';
import '../dashboard/dashboard_controller.dart';

class VisionScreen extends ConsumerWidget {
  const VisionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detections = ref.watch(detectionsProvider);

    return detections.when(
      data: (items) {
        final latest = items.first;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            Text(
              'Vision',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          latest.cameraId,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      StatusChip(
                        label: 'ONLINE',
                        color: Theme.of(context).colorScheme.primary,
                        icon: Icons.circle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFF1C2B22),
                      ),
                      child: Stack(
                        children: [
                          const Center(
                            child: Icon(
                              Icons.agriculture,
                              color: Colors.white70,
                              size: 54,
                            ),
                          ),
                          Positioned(
                            left: 82,
                            top: 48,
                            width: 142,
                            height: 84,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.redAccent,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 82,
                            top: 28,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              color: Colors.redAccent,
                              child: Text(
                                latest.className,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    latest.className,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${latest.type.toUpperCase()} - Confidence ${(latest.confidence * 100).round()}%',
                  ),
                  Text(
                    'Detected ${DateFormat('dd MMM yyyy HH:mm').format(latest.detectedAt)}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SectionCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      item.type == 'healthy'
                          ? Icons.verified
                          : Icons.warning_amber_rounded,
                      color: item.type == 'healthy'
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.tertiary,
                    ),
                    title: Text(item.className),
                    subtitle: Text(
                      '${item.type.toUpperCase()} - ${item.cameraId}',
                    ),
                    trailing: Text('${(item.confidence * 100).round()}%'),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('$error')),
    );
  }
}
