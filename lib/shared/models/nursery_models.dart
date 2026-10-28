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
        fallbackName: 'Nursery Controller',
      ),
      sensor: SensorReading.fromJson(_map(json['sensor'])),
      fan: FanState.fromJson(_map(json['fan'])),
      alerts: alerts,
      recommendation: Recommendation.fromJson(_map(json['recommendation'])),
      systemStatus: '${json['system_status'] ?? 'UNKNOWN'}',
      unreadAlerts:
          _toNullableInt(json['unread_alerts']) ??
          alerts.where((alert) => !alert.isRead).length,
    );
  }
}

class SensorReading {
  const SensorReading({
    required this.deviceId,
    required this.temperature,
    required this.humidity,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.light,
    required this.ultrasonic,
    this.lightPercent = 0,
    this.uvIndex = 0,
    this.waterLevel = 0,
    required this.createdAt,
  });

  final String deviceId;
  final double temperature;
  final double humidity;
  final double nitrogen;
  final double phosphorus;
  final double potassium;
  final double light;
  final double ultrasonic;
  final double lightPercent;
  final double uvIndex;
  final double waterLevel;
  final DateTime createdAt;

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    final water = json['water_level'];
    return SensorReading(
      deviceId: '${json['device_id'] ?? json['device_code'] ?? 'ESP32-01'}',
      temperature: _toDouble(json['temperature']),
      humidity: _toDouble(json['humidity']),
      nitrogen: _toDouble(json['nitrogen']),
      phosphorus: _toDouble(json['phosphorus']),
      potassium: _toDouble(json['potassium']),
      light: _toDouble(json['light']),
      ultrasonic: _toDouble(
        json['distance_cm'] ??
            json['ultrasonic'] ??
            (water is Map<String, dynamic> ? water['distance_cm'] : null),
      ),
      lightPercent: _toDouble(json['light_percent'] ?? json['light']),
      uvIndex: _toDouble(json['uv_index']),
      waterLevel: _toDouble(
        json['water_level_percent'] ??
            json['level_percent'] ??
            (water is Map<String, dynamic> ? water['percent'] : water),
      ),
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
    'distance_cm': ultrasonic,
    'level_percent': waterLevel,
    'created_at': createdAt.toIso8601String(),
  };
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
    this.latestSensor,
  }) : isOnline = isOnline ?? status == 'ONLINE';

  final String code;
  final String name;
  final String status;
  final DateTime lastSeen;
  final String location;
  final bool isOnline;
  final FanState? fan;
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
    'latest_sensor': latestSensor?.toJson(),
  };
}

class FanState {
  const FanState({
    required this.status,
    required this.mode,
    this.deviceOnline = true,
  });

  final String status;
  final String mode;
  final bool deviceOnline;

  FanState copyWith({String? status, String? mode, bool? deviceOnline}) {
    return FanState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      deviceOnline: deviceOnline ?? this.deviceOnline,
    );
  }

  factory FanState.fromJson(Map<String, dynamic> json) {
    final nested = json['fan'] ?? json['actuator'];
    if (nested is Map<String, dynamic>) {
      return FanState.fromJson(nested);
    }
    return FanState(
      status: _normalizeStatus(json['status'] ?? 'OFF'),
      mode: _normalizeStatus(json['mode'] ?? 'MANUAL'),
      deviceOnline: json['device_online'] is bool
          ? json['device_online'] as bool
          : true,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'mode': mode,
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
      sensorType: '${json['sensor_type'] ?? ''}'.toLowerCase(),
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
    required this.level,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  final int? id;
  final String level;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  SystemAlert copyWith({bool? isRead}) {
    return SystemAlert(
      id: id,
      level: level,
      title: title,
      message: message,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  factory SystemAlert.fromJson(Map<String, dynamic> json) {
    return SystemAlert(
      id: _toNullableInt(json['id']),
      level: _normalizeStatus(json['level'] ?? json['severity'] ?? 'WARNING'),
      title: '${json['title'] ?? 'Alert'}',
      message: '${json['message'] ?? ''}',
      createdAt:
          _toDateTime(json['created_at'] ?? json['detected_at']) ??
          DateTime.now(),
      isRead: json['is_read'] == true || json['read_at'] != null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
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
