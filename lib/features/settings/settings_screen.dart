import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../shared/widgets/section_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: [
        Text(
          'Settings',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            children: const [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.api),
                title: Text('Laravel REST API'),
                subtitle: Text(AppConfig.apiBaseUrl),
              ),
              Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.sensors),
                title: Text('MQTT sensor topic'),
                subtitle: Text(AppConfig.mqttSensorTopic),
              ),
              Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.air),
                title: Text('MQTT fan command topic'),
                subtitle: Text(AppConfig.mqttFanCommandTopic),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
