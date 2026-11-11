class DashboardSnapshot {
  const DashboardSnapshot({
    required this.device,
    required this.sensor,
    required this.fan,
    required this.alerts,
    required this.recommendation,
    required this.systemStatus,
    required this.unreadAlerts,
  });

  final DeviceStatus device;
  final SensorReading sensor;
  final FanState fan;
  final List<SystemAlert> alerts;
  final Recommendation recommendation;
  final String systemStatus;
  final int unreadAlerts;

  Map<String, dynamic> toJson() => {
    'device': device.toJson(),
    'sensor': sensor.toJson(),
    'fan': fan.toJson(),
    'alerts': alerts.map((alert) => alert.toJson()).toList(),
    'recommendation': recommendation.toJson(),
    'system_status': systemStatus,
    'unread_alerts': unreadAlerts,
  };

  factory DashboardSnapshot.fromJson(Map<String, dynamic> json) {
    final alerts = (json['alerts'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SystemAlert.fromJson)
        .toList();
    return DashboardSnapshot(
      device: DeviceStatus.fromJson(
        _map(json['device']),
        fallbackCode: 'ESP32-01',
        fallbackName: 'ESP32 Utama',
      ),
      sensor: SensorReading.fromJson(_map(json['sensor'] ?? json['sensors'] ?? json['latest_sensor'])),
      fan: FanState.fromJson(_map(json['fan'] ?? json['pump'])),
      alerts: alerts,
      recommendation: Recommendation.fromJson(_map(json['recommendation'])),
      systemStatus: '${json['system_status'] ?? 'NORMAL'}',
      unreadAlerts:
          _toNullableInt(json['unread_alerts']) ??
          alerts.where((alert) => !alert.isRead).length,
    );
  }

  static DashboardSnapshot get dummy => DashboardSnapshot(
    device: dummyDevices.first,
    sensor: SensorReading.dummy,
    fan: const FanState(status: 'ON', mode: 'AUTO', isOn: true, deviceOnline: true),
    alerts: dummyAlerts,
    recommendation: const Recommendation(
      status: 'NORMAL',
      cause: 'Kondisi lingkungan pembibitan normal',
      message: 'Suhu dan kelembapan optimal. Pertahankan aerasi dan kontrol air berkala.',
    ),
    systemStatus: 'NORMAL',
    unreadAlerts: 1,
  );

  static List<SystemAlert> get dummyAlerts => [
    SystemAlert(
      id: 1,
      deviceCode: 'ESP32-01',
      level: 'WARNING',
      title: 'Fluktuasi Kelembapan',
      message: 'Kelembaban udara sempat menyentuh 88% di nursery utama.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 35)),
      isRead: false,
    ),
    SystemAlert(
      id: 2,
      deviceCode: 'ESP32-01',
      level: 'INFO',
      title: 'Sirkulasi Terjaga',
      message: 'Suhu stabil di 28.5°C dengan aerasi berjalan normal.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: true,
    ),
  ];

  static List<DeviceStatus> get dummyDevices => [
    DeviceStatus(
      code: 'ESP32-01',
      name: 'ESP32 Utama',
      status: 'ONLINE',
      lastSeen: DateTime.now(),
      location: 'Rumah Kaca Pembibitan',
      isOnline: true,
      fan: const FanState(status: 'ON', mode: 'AUTO', isOn: true, deviceOnline: true),
      latestSensor: SensorReading.dummy,
    ),
    DeviceStatus(
      code: 'ESP32-CAM-01',
      name: 'Kamera Monitor Daun',
      status: 'ONLINE',
      lastSeen: DateTime.now().subtract(const Duration(minutes: 12)),
      location: 'Lahan Riset Agrotek',
      isOnline: true,
      fan: const FanState(status: 'OFF', mode: 'AUTO', isOn: false, deviceOnline: true),
      latestSensor: SensorReading.dummy,
    ),
  ];
}

class SensorReading {
  const SensorReading({
    required this.deviceId,
    this.temperature,
    this.humidity,
    this.nitrogen,
    this.phosphorus,
    this.potassium,
    this.light,
    this.lightPercent,
    this.uvIndex,
    this.ultrasonic,
    this.distanceCm,
    this.levelPercent,
    this.waterLevelPercent,
    this.fanState,
    this.fanMode,
    required this.createdAt,
  });

  final String deviceId;
  final double? temperature;
  final double? humidity;
  final double? nitrogen;
  final double? phosphorus;
  final double? potassium;
  final double? light;
  final double? lightPercent;
  final double? uvIndex;
  final double? ultrasonic;
  final double? distanceCm;
  final double? levelPercent;
  final double? waterLevelPercent;
  final String? fanState;
  final String? fanMode;
  final DateTime createdAt;

  double? get waterLevel => waterLevelPercent ?? levelPercent;

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    final water = json['water_level'];
    return SensorReading(
      deviceId: '${json['device_id'] ?? json['device_code'] ?? 'ESP32-01'}',
      temperature: _toNullableDouble(json['temperature']),
      humidity: _toNullableDouble(json['humidity']),
      nitrogen: _toNullableDouble(json['nitrogen']),
      phosphorus: _toNullableDouble(json['phosphorus']),
      potassium: _toNullableDouble(json['potassium']),
      light: _toNullableDouble(json['light']),
      lightPercent: _toNullableDouble(json['light_percent']),
      uvIndex: _toNullableDouble(json['uv_index']),
      ultrasonic: _toNullableDouble(json['ultrasonic']),
      distanceCm: _toNullableDouble(
        json['distance_cm'] ??
            (water is Map<String, dynamic> ? water['distance_cm'] : null),
      ),
      levelPercent: _toNullableDouble(json['level_percent']),
      waterLevelPercent: _toNullableDouble(
        json['water_level_percent'] ??
            (water is Map<String, dynamic> ? water['percent'] : water),
      ),
      fanState: json['fan_state']?.toString(),
      fanMode: json['fan_mode']?.toString(),
      createdAt:
          _toDateTime(json['created_at'] ?? json['recorded_at']) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'device_id': deviceId,
    'temperature': temperature,
    'humidity': humidity,
    'nitrogen': nitrogen,
    'phosphorus': phosphorus,
    'potassium': potassium,
    'light': light,
    'light_percent': lightPercent,
    'uv_index': uvIndex,
    'ultrasonic': ultrasonic,
    'distance_cm': distanceCm,
    'level_percent': levelPercent,
    'water_level_percent': waterLevelPercent,
    'fan_state': fanState,
    'fan_mode': fanMode,
    'created_at': createdAt.toIso8601String(),
  };

  static SensorReading get dummy => SensorReading(
    deviceId: 'ESP32-01',
    temperature: 28.5,
    humidity: 75.0,
    nitrogen: 48.0,
    phosphorus: 26.0,
    potassium: 38.0,
    light: 850.0,
    lightPercent: 72.0,
    uvIndex: 3.2,
    ultrasonic: 14.0,
    distanceCm: 14.0,
    levelPercent: 80.0,
    waterLevelPercent: 80.0,
    fanState: 'ON',
    fanMode: 'AUTO',
    createdAt: DateTime.now(),
  );

  static List<SensorReading> generateDummyHistory({String range = 'today'}) {
    final baseTime = DateTime.now().subtract(const Duration(hours: 24));
    final temps = [27.2, 27.5, 26.8, 26.5, 26.2, 26.0, 26.8, 27.9, 29.1, 30.5, 31.4, 32.2, 31.8, 31.0, 30.2, 29.5, 28.8, 28.2, 27.9, 28.1, 28.4, 28.6, 28.8, 29.2, 29.5];
    final hums =  [82.0, 84.0, 85.0, 86.0, 88.0, 87.0, 83.0, 78.0, 74.0, 68.0, 65.0, 62.0, 64.0, 68.0, 72.0, 75.0, 78.0, 80.0, 82.0, 80.0, 78.0, 76.0, 75.0, 74.0, 72.0];
    final waters =[75.0, 75.0, 74.0, 74.0, 73.0, 73.0, 74.0, 76.0, 78.0, 80.0, 80.0, 79.0, 78.0, 78.0, 77.0, 77.0, 78.0, 78.0, 79.0, 80.0, 82.0, 82.0, 80.0, 80.0, 82.0];

    return List.generate(temps.length, (i) {
      return SensorReading(
        deviceId: 'ESP32-01',
        temperature: temps[i],
        humidity: hums[i],
        nitrogen: 45.0 + (i % 8),
        phosphorus: 24.0 + (i % 5),
        potassium: 35.0 + (i % 6),
        light: 600.0 + (i * 25),
        lightPercent: (55.0 + (i % 35)).clamp(0, 95).toDouble(),
        uvIndex: 2.5 + ((i % 6) * 0.4),
        ultrasonic: 15.0 - ((i % 4) * 0.5),
        distanceCm: 15.0 - ((i % 4) * 0.5),
        levelPercent: waters[i],
        waterLevelPercent: waters[i],
        fanState: temps[i] > 30 ? 'ON' : 'OFF',
        fanMode: 'AUTO',
        createdAt: baseTime.add(Duration(minutes: i * 58)),
      );
    });
  }
}

class PaddyPrediction {
  const PaddyPrediction({
    required this.classId,
    required this.className,
    required this.displayName,
    required this.confidence,
    required this.status,
  });

  final int? classId;
  final String className;
  final String displayName;
  final double confidence;
  final String status;

  double get confidencePercent =>
      confidence <= 1 ? confidence * 100 : confidence;

  factory PaddyPrediction.fromJson(Map<String, dynamic> json) {
    return PaddyPrediction(
      classId: _toNullableInt(json['class_id']),
      className: '${json['class'] ?? json['class_name'] ?? 'unknown'}',
      displayName:
          '${json['display_name'] ?? json['class_name'] ?? json['class'] ?? 'Unknown'}',
      confidence: _toDouble(json['confidence']),
      status: '${json['status'] ?? 'unknown'}',
    );
  }
}

class DeviceStatus {
  const DeviceStatus({
    required this.code,
    required this.name,
    required this.status,
    required this.lastSeen,
    this.location = '',
    bool? isOnline,
    this.fan,
    this.mist,
    this.latestSensor,
  }) : isOnline = isOnline ?? status == 'ONLINE';

  final String code;
  final String name;
  final String status;
  final DateTime lastSeen;
  final String location;
  final bool isOnline;
  final FanState? fan;
  final Map<String, dynamic>? mist;
  final SensorReading? latestSensor;

  factory DeviceStatus.fromJson(
    Map<String, dynamic> json, {
    required String fallbackCode,
    required String fallbackName,
    String? fallbackStatus,
  }) {
    final status = _normalizeStatus(
      json['status'] ?? fallbackStatus ?? 'OFFLINE',
    );
    return DeviceStatus(
      code: '${json['code'] ?? json['device_code'] ?? fallbackCode}',
      name: '${json['name'] ?? fallbackName}',
      status: status,
      lastSeen:
          _toDateTime(json['last_seen'] ?? json['updated_at']) ??
          DateTime.now(),
      location: '${json['location'] ?? ''}',
      isOnline: json['is_online'] is bool
          ? json['is_online'] as bool
          : status == 'ONLINE',
      fan: json['fan'] is Map<String, dynamic>
          ? FanState.fromJson(json['fan'] as Map<String, dynamic>)
          : (json['pump'] is Map<String, dynamic>
              ? FanState.fromJson(json['pump'] as Map<String, dynamic>)
              : null),
      mist: json['mist'] is Map<String, dynamic>
          ? json['mist'] as Map<String, dynamic>
          : null,
      latestSensor: json['latest_sensor'] is Map<String, dynamic>
          ? SensorReading.fromJson(
              json['latest_sensor'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'status': status,
    'last_seen': lastSeen.toIso8601String(),
    'location': location,
    'is_online': isOnline,
    'fan': fan?.toJson(),
    'mist': mist,
    'latest_sensor': latestSensor?.toJson(),
  };
}

class FanState {
  const FanState({
    required this.status,
    required this.mode,
    bool? isOn,
    this.deviceOnline = true,
  }) : isOn = isOn ?? status == 'ON';

  final String status;
  final String mode;
  final bool isOn;
  final bool deviceOnline;

  FanState copyWith({
    String? status,
    String? mode,
    bool? isOn,
    bool? deviceOnline,
  }) {
    final nextStatus = status ?? this.status;
    return FanState(
      status: nextStatus,
      mode: mode ?? this.mode,
      isOn: isOn ?? (status == null ? this.isOn : nextStatus == 'ON'),
      deviceOnline: deviceOnline ?? this.deviceOnline,
    );
  }

  factory FanState.fromJson(Map<String, dynamic> json) {
    final payload = json['actuator'] is Map<String, dynamic>
        ? json['actuator'] as Map<String, dynamic>
        : (json['fan'] is Map<String, dynamic>
            ? json['fan'] as Map<String, dynamic>
            : (json['pump'] is Map<String, dynamic>
                ? json['pump'] as Map<String, dynamic>
                : json));
    final status = _normalizeStatus(payload['status'] ?? 'OFF');
    return FanState(
      status: status,
      mode: _normalizeStatus(payload['mode'] ?? 'AUTO'),
      isOn: payload['is_on'] is bool
          ? payload['is_on'] as bool
          : status == 'ON',
      deviceOnline:
          (payload['device_online'] ?? json['device_online']) as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'mode': mode,
    'is_on': isOn,
    'device_online': deviceOnline,
  };
}


class SensorThreshold {
  const SensorThreshold({
    required this.sensorType,
    required this.minValue,
    required this.maxValue,
  });

  final String sensorType;
  final double minValue;
  final double maxValue;

  factory SensorThreshold.fromJson(Map<String, dynamic> json) {
    return SensorThreshold(
      sensorType: '${json['sensor_type'] ?? ''}',
      minValue: _toDouble(json['min_value']),
      maxValue: _toDouble(json['max_value']),
    );
  }

  Map<String, dynamic> toJson() => {
    'sensor_type': sensorType,
    'min_value': minValue,
    'max_value': maxValue,
  };
}

class SystemAlert {
  const SystemAlert({
    this.id,
    this.deviceCode,
    required this.level,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  final int? id;
  final String? deviceCode;
  final String level;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  SystemAlert copyWith({bool? isRead}) {
    return SystemAlert(
      id: id,
      deviceCode: deviceCode,
      level: level,
      title: title,
      message: message,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  factory SystemAlert.fromJson(Map<String, dynamic> json) {
    final dev = json['device'];
    final devCode = dev is Map<String, dynamic>
        ? dev['device_code']?.toString()
        : (json['device_code']?.toString() ??
            (json['device_id'] != null ? 'ESP32-${json['device_id']}' : null));
    return SystemAlert(
      id: _toNullableInt(json['id']),
      deviceCode: devCode,
      level: _normalizeStatus(json['level'] ?? json['severity'] ?? 'WARNING'),
      title: '${json['title'] ?? 'Alert'}',
      message: '${json['message'] ?? ''}',
      createdAt:
          _toDateTime(json['created_at'] ?? json['detected_at']) ??
          DateTime.now(),
      isRead: json['is_read'] == true ||
          json['read_at'] != null ||
          json['status'] == 'READ',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'device_code': deviceCode,
    'level': level,
    'title': title,
    'message': message,
    'created_at': createdAt.toIso8601String(),
    'is_read': isRead,
  };
}

class Recommendation {
  const Recommendation({
    required this.status,
    required this.cause,
    required this.message,
  });

  final String status;
  final String cause;
  final String message;

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      status: _normalizeStatus(json['status'] ?? 'NORMAL'),
      cause: '${json['cause'] ?? json['title'] ?? 'Kondisi nursery normal.'}',
      message:
          '${json['message'] ?? json['recommendation'] ?? 'Lanjutkan pemantauan berkala.'}',
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'cause': cause,
    'message': message,
  };
}

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : <String, dynamic>{};

double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

double? _toNullableDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}

int? _toNullableInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value');
}

DateTime? _toDateTime(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse('$value');
}

String _normalizeStatus(Object? value) => '${value ?? ''}'.toUpperCase();
