import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/repositories/nursery_repository.dart';
import '../../shared/widgets/section_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.user, required this.onLogout});

  final AuthUser user;
  final Future<void> Function() onLogout;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _criticalNotif = true;
  bool _dailySummary = true;
  double _temperatureLimit = 32;
  double _humidityLimit = 80;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _ProfileCard(
          name: widget.user.name,
          email: widget.user.email,
          role: widget.user.role,
          onLogout: widget.onLogout,
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                icon: Icons.notifications_active_rounded,
                title: 'Notifikasi',
              ),
              const SizedBox(height: 8),
              _SettingSwitch(
                title: 'Alert critical',
                subtitle: 'Peringatan saat kondisi perlu tindakan cepat',
                value: _criticalNotif,
                onChanged: (value) => setState(() => _criticalNotif = value),
              ),
              _SettingSwitch(
                title: 'Ringkasan harian',
                subtitle: 'Rekap kondisi nursery setiap hari',
                value: _dailySummary,
                onChanged: (value) => setState(() => _dailySummary = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                icon: Icons.tune_rounded,
                title: 'Ambang Sensor',
              ),
              const SizedBox(height: 12),
              _ThresholdSlider(
                label: 'Suhu maksimum',
                value: _temperatureLimit,
                min: 25,
                max: 40,
                unit: 'C',
                color: AppTheme.warning,
                onChanged: (value) => setState(() => _temperatureLimit = value),
              ),
              const SizedBox(height: 10),
              _ThresholdSlider(
                label: 'Kelembapan maksimum',
                value: _humidityLimit,
                min: 60,
                max: 95,
                unit: '%',
                color: AppTheme.infoBlue,
                onChanged: (value) => setState(() => _humidityLimit = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          padding: EdgeInsets.zero,
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: const Icon(
              Icons.dns_rounded,
              color: AppTheme.primaryGreen,
            ),
            title: const Text(
              'System info',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AppTheme.textStrong,
              ),
            ),
            children: const [
              _ConfigField(title: 'Backend API', value: AppConfig.apiBaseUrl),
              SizedBox(height: 10),
              _ConfigField(
                title: 'MQTT Sensor',
                value: AppConfig.mqttSensorTopic,
              ),
              SizedBox(height: 10),
              _ConfigField(
                title: 'MQTT Kipas',
                value: AppConfig.mqttFanCommandTopic,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.email,
    required this.role,
    required this.onLogout,
  });

  final String name;
  final String email;
  final String role;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryGreen.withValues(alpha: 0.2),
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppTheme.primaryGreen,
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textStrong,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$email - ${role.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
            color: AppTheme.critical,
          ),
        ],
      ),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  const _SettingSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      activeThumbColor: AppTheme.primaryGreen,
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          color: AppTheme.textStrong,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
      ),
      onChanged: onChanged,
    );
  }
}

class _ThresholdSlider extends StatelessWidget {
  const _ThresholdSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;
  final Color color;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textStrong,
                ),
              ),
            ),
            Text(
              '${value.round()} $unit',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).round(),
          activeColor: color,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryGreen, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: AppTheme.textStrong,
          ),
        ),
      ],
    );
  }
}

class _ConfigField extends StatelessWidget {
  const _ConfigField({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: AppTheme.textStrong,
          ),
        ),
        const SizedBox(height: 6),
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
    );
  }
}
