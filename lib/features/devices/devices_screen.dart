import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../shared/widgets/section_card.dart';
import '../../shared/widgets/status_chip.dart';
import '../dashboard/dashboard_controller.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);

    return dashboard.when(
      data: (snapshot) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          Text(
            'Device',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.memory),
              title: Text(snapshot.device.name),
              subtitle: Text(
                '${snapshot.device.code} - Last seen ${DateFormat.Hms().format(snapshot.device.lastSeen)}',
              ),
              trailing: StatusChip(
                label: snapshot.device.status.toUpperCase(),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SectionCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.videocam),
              title: Text(snapshot.camera.name),
              subtitle: Text(
                '${snapshot.camera.code} - Last seen ${DateFormat.Hms().format(snapshot.camera.lastSeen)}',
              ),
              trailing: StatusChip(
                label: snapshot.camera.status.toUpperCase(),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('$error')),
    );
  }
}
