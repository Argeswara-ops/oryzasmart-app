import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/section_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _name = 'Petani Padi';
  String _email = 'petani@oryza.smart';

  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: _name);
    final emailController = TextEditingController(text: _email);

    final result = await showDialog<({String name, String email})>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, (
              name: nameController.text.trim(),
              email: emailController.text.trim(),
            )),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    nameController.dispose();
    emailController.dispose();

    if (result == null) return;
    setState(() {
      _name = result.name.isEmpty ? _name : result.name;
      _email = result.email.isEmpty ? _email : result.email;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        SectionCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.12),
                child: const Icon(
                  Icons.grass_rounded,
                  color: AppTheme.primaryGreen,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit',
                onPressed: _editProfile,
                icon: const Icon(Icons.edit_rounded),
                color: AppTheme.primaryGreen,
              ),
              IconButton(
                tooltip: 'Logout',
                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout_rounded),
                color: const Color(0xFFDC2626),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _ConfigCard(title: 'Backend API', value: AppConfig.apiBaseUrl),
        const SizedBox(height: 14),
        const _ConfigCard(
          title: 'MQTT Sensor',
          value: AppConfig.mqttSensorTopic,
        ),
        const SizedBox(height: 10),
        const _ConfigCard(
          title: 'MQTT Kipas',
          value: AppConfig.mqttFanCommandTopic,
        ),
      ],
    );
  }
}

class _ConfigCard extends StatelessWidget {
  const _ConfigCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
