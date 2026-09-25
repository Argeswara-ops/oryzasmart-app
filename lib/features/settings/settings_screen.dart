import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/section_card.dart';
import '../../shared/widgets/status_chip.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController(text: 'Petani Padi');
  final _emailController = TextEditingController(text: 'petani@padi.local');
  final _phoneController = TextEditingController(text: '0812-0000-1234');
  bool _hasProfile = true;
  bool _isEditing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    setState(() {
      _hasProfile = true;
      _isEditing = false;
    });
  }

  void _deleteProfile() {
    setState(() {
      _hasProfile = false;
      _isEditing = true;
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppTheme.primaryGreen,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _hasProfile ? _nameController.text : 'Profil baru',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: _isEditing ? 'Simpan' : 'Edit',
                    onPressed: _isEditing
                        ? _saveProfile
                        : () => setState(() => _isEditing = true),
                    icon: Icon(
                      _isEditing ? Icons.check_rounded : Icons.edit_rounded,
                    ),
                    color: AppTheme.primaryGreen,
                  ),
                  IconButton(
                    tooltip: 'Hapus',
                    onPressed: _hasProfile ? _deleteProfile : null,
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: const Color(0xFFDC2626),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _ProfileField(
                controller: _nameController,
                label: 'Nama',
                icon: Icons.badge_outlined,
                enabled: _isEditing,
              ),
              const SizedBox(height: 10),
              _ProfileField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                enabled: _isEditing,
              ),
              const SizedBox(height: 10),
              _ProfileField(
                controller: _phoneController,
                label: 'Telepon',
                icon: Icons.call_outlined,
                enabled: _isEditing,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() {
                        _hasProfile = true;
                        _isEditing = true;
                      }),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Tambah'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: widget.onLogout,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Logout'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.api_rounded,
                    color: AppTheme.primaryGreen,
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Backend API',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.link_rounded,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppConfig.apiBaseUrl,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.hub_rounded, color: Color(0xFF0D9488), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'MQTT',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Spacer(),
                  StatusChip(label: 'v1.0.0', color: AppTheme.primaryGreen),
                ],
              ),
              const SizedBox(height: 12),
              _SettingTile(
                icon: Icons.sensors_rounded,
                title: 'Sensor',
                subtitle: AppConfig.mqttSensorTopic,
              ),
              const SizedBox(height: 8),
              _SettingTile(
                icon: Icons.air_rounded,
                title: 'Kipas',
                subtitle: AppConfig.mqttFanCommandTopic,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.enabled,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
