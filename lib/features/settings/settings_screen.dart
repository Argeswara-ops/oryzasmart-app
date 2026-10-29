import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/repositories/nursery_repository.dart';
import '../../shared/models/nursery_models.dart';
import '../../shared/widgets/section_card.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, required this.user, required this.onLogout});

  final AuthUser user;
  final Future<void> Function() onLogout;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _criticalNotif = true;
  bool _dailySummary = true;

  @override
  Widget build(BuildContext context) {
    final thresholds = ref.watch(sensorThresholdsProvider);
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
              const SizedBox(height: 4),
              const Text(
                'Nilai minimum dan maksimum berikut dibaca langsung dari API.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),
              thresholds.when(
                data: (items) => items.isEmpty
                    ? const Text('Ambang sensor belum tersedia dari API.')
                    : Column(
                        children: [
                          for (
                            var index = 0;
                            index < items.length;
                            index++
                          ) ...[
                            _ThresholdEditor(
                              key: ValueKey(
                                '${items[index].sensorType}-${items[index].minValue}-${items[index].maxValue}',
                              ),
                              threshold: items[index],
                              onSave: (threshold) async {
                                final success = await ref
                                    .read(sensorThresholdsProvider.notifier)
                                    .saveThreshold(threshold);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Ambang ${_thresholdLabel(threshold.sensorType)} tersimpan.'
                                          : 'Ambang gagal disimpan. Periksa koneksi dan hak akses.',
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (index < items.length - 1)
                              const Divider(height: 24),
                          ],
                        ],
                      ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
                error: (error, _) => Column(
                  children: [
                    const Text(
                      'Ambang sensor belum dapat dimuat dari API.',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          ref.read(sensorThresholdsProvider.notifier).reload(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Coba lagi'),
                    ),
                  ],
                ),
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
            children: [
              _ConfigField(title: 'Backend API (Laravel)', value: AppConfig.apiBaseUrl),
              const SizedBox(height: 10),
              _ConfigField(title: 'Database Engine', value: AppConfig.databaseInfo),
              const SizedBox(height: 10),
              _ConfigField(title: 'MQTT Broker', value: AppConfig.mqttBroker),
              const SizedBox(height: 10),
              const _ConfigField(title: 'MQTT Client ID', value: 'laravel_oryza_smart'),
              const SizedBox(height: 10),
              _ConfigField(title: 'Device ID Lapangan', value: AppConfig.deviceId),
              const SizedBox(height: 10),
              _ConfigField(title: 'Topik Sensor', value: AppConfig.mqttSensorTopic),
              const SizedBox(height: 10),
              _ConfigField(title: 'Topik Aktuator Pompa', value: AppConfig.mqttActuatorTopic),
              const SizedBox(height: 10),
              _ConfigField(title: 'Topik Status ESP32', value: AppConfig.mqttStatusTopic),
              const SizedBox(height: 10),
              const _ConfigField(title: 'Alur Data Sistem', value: AppConfig.dataFlow),
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

class _ThresholdEditor extends StatefulWidget {
  const _ThresholdEditor({
    super.key,
    required this.threshold,
    required this.onSave,
  });

  final SensorThreshold threshold;
  final Future<void> Function(SensorThreshold threshold) onSave;

  @override
  State<_ThresholdEditor> createState() => _ThresholdEditorState();
}

class _ThresholdEditorState extends State<_ThresholdEditor> {
  late RangeValues _values;
  bool _saving = false;
  bool _saved = false;
  Timer? _debounceTimer;
  Timer? _savedIndicatorTimer;

  @override
  void initState() {
    super.initState();
    final bounds = _thresholdBounds(widget.threshold.sensorType);
    _values = RangeValues(
      widget.threshold.minValue.clamp(bounds.start, bounds.end),
      widget.threshold.maxValue.clamp(bounds.start, bounds.end),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _savedIndicatorTimer?.cancel();
    super.dispose();
  }

  Future<void> _autoSave() async {
    _debounceTimer?.cancel();
    final type = widget.threshold.sensorType;
    if (_values.start == widget.threshold.minValue &&
        _values.end == widget.threshold.maxValue) {
      return;
    }

    setState(() {
      _saving = true;
      _saved = false;
    });

    await widget.onSave(
      SensorThreshold(
        sensorType: type,
        minValue: _values.start,
        maxValue: _values.end,
      ),
    );

    if (mounted) {
      setState(() {
        _saving = false;
        _saved = true;
      });
      _savedIndicatorTimer?.cancel();
      _savedIndicatorTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _saved = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.threshold.sensorType;
    final bounds = _thresholdBounds(type);
    final unit = _thresholdUnit(type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    _thresholdLabel(type),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textStrong,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_saving) ...[
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Menyimpan...',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ] else if (_saved) ...[
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 13,
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      'Tersimpan',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              '${_formatThreshold(_values.start)}–${_formatThreshold(_values.end)} $unit',
              style: const TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ],
        ),
        RangeSlider(
          values: _values,
          min: bounds.start,
          max: bounds.end,
          divisions: (bounds.end - bounds.start).round(),
          activeColor: AppTheme.primaryGreen,
          labels: RangeLabels(
            _formatThreshold(_values.start),
            _formatThreshold(_values.end),
          ),
          onChanged: (values) {
            setState(() {
              _values = values;
              _saved = false;
            });
            _debounceTimer?.cancel();
            _debounceTimer = Timer(const Duration(milliseconds: 500), () {
              _autoSave();
            });
          },
          onChangeEnd: (values) {
            _debounceTimer?.cancel();
            _autoSave();
          },
        ),
      ],
    );
  }
}

RangeValues _thresholdBounds(String type) => switch (type) {
  'temperature' => const RangeValues(0, 50),
  'humidity' || 'light_percent' || 'water_level' => const RangeValues(0, 100),
  'uv_index' => const RangeValues(0, 15),
  'nitrogen' || 'phosphorus' || 'potassium' => const RangeValues(0, 200),
  _ => const RangeValues(0, 100),
};

String _thresholdLabel(String type) => switch (type) {
  'temperature' => 'Suhu',
  'humidity' => 'Kelembapan',
  'nitrogen' => 'Nitrogen',
  'phosphorus' => 'Fosfor',
  'potassium' => 'Kalium',
  'light_percent' => 'Intensitas cahaya',
  'uv_index' => 'Indeks UV',
  'water_level' => 'Ketinggian air',
  _ => type,
};

String _thresholdUnit(String type) => switch (type) {
  'temperature' => '°C',
  'humidity' || 'light_percent' || 'water_level' => '%',
  'uv_index' => 'indeks',
  'nitrogen' || 'phosphorus' || 'potassium' => 'mg/kg',
  _ => '',
};

String _formatThreshold(double value) => value == value.roundToDouble()
    ? value.round().toString()
    : value.toStringAsFixed(1);

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
