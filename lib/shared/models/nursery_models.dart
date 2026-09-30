class DashboardSnapshot {
  const DashboardSnapshot({
    required this.device,
    required this.camera,
    required this.sensor,
    required this.detection,
    required this.fan,
    required this.alerts,
    required this.recommendation,
    required this.systemStatus,
    required this.unreadAlerts,
  });

  final DeviceStatus device;
  final DeviceStatus camera;
  final SensorReading sensor;
  final Detection detection;
  final FanState fan;
  final List<SystemAlert> alerts;
  final Recommendation recommendation;
  final String systemStatus;
  final int unreadAlerts;
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
  final DateTime createdAt;

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      deviceId: '${json['device_id'] ?? json['device_code'] ?? 'ESP32-01'}',
      temperature: _toDouble(json['temperature']),
      humidity: _toDouble(json['humidity']),
      nitrogen: _toDouble(json['nitrogen']),
      phosphorus: _toDouble(json['phosphorus']),
      potassium: _toDouble(json['potassium']),
      light: _toDouble(json['light']),
      ultrasonic: _toDouble(json['ultrasonic']),
      createdAt:
          _toDateTime(json['created_at'] ?? json['recorded_at']) ??
          DateTime.now(),
    );
  }
}

class Detection {
  const Detection({
    required this.cameraId,
    required this.type,
    required this.className,
    required this.confidence,
    required this.image,
    required this.detectedAt,
  });

  final String cameraId;
  final String type;
  final String className;
  final double confidence;
  final String image;
  final DateTime detectedAt;

  factory Detection.fromJson(Map<String, dynamic> json) {
    final camera = json['camera'];
    return Detection(
      cameraId: camera is Map<String, dynamic>
          ? '${camera['camera_code'] ?? camera['code'] ?? 'CAM-01'}'
          : '${json['camera_code'] ?? json['camera'] ?? json['camera_id'] ?? 'CAM-01'}',
      type: _normalizeType(json['detection_type'] ?? json['type']),
      className: '${json['class_name'] ?? json['class'] ?? 'unknown'}',
      confidence: _toDouble(json['confidence']),
      image: '${json['image_path'] ?? json['image'] ?? ''}',
      detectedAt:
          _toDateTime(json['detected_at'] ?? json['created_at']) ??
          DateTime.now(),
    );
  }
}

class DeviceStatus {
  const DeviceStatus({
    required this.code,
    required this.name,
    required this.status,
    required this.lastSeen,
  });

  final String code;
  final String name;
  final String status;
  final DateTime lastSeen;

  factory DeviceStatus.fromJson(
    Map<String, dynamic> json, {
    required String fallbackCode,
    required String fallbackName,
    String? fallbackStatus,
  }) {
    return DeviceStatus(
      code:
          '${json['code'] ?? json['device_code'] ?? json['camera_id'] ?? fallbackCode}',
      name: '${json['name'] ?? fallbackName}',
      status: _normalizeStatus(json['status'] ?? fallbackStatus ?? 'OFFLINE'),
      lastSeen:
          _toDateTime(json['last_seen'] ?? json['updated_at']) ??
          DateTime.now(),
    );
  }
}

class FanState {
  const FanState({required this.status, required this.mode});

  final String status;
  final String mode;

  FanState copyWith({String? status, String? mode}) {
    return FanState(status: status ?? this.status, mode: mode ?? this.mode);
  }

  factory FanState.fromJson(Map<String, dynamic> json) {
    final nested = json['fan'];
    if (nested is Map<String, dynamic>) {
      return FanState.fromJson(nested);
    }
    return FanState(
      status: _normalizeStatus(json['status'] ?? 'OFF'),
      mode: _normalizeStatus(json['mode'] ?? 'MANUAL'),
    );
  }
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
}

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

String _normalizeType(Object? value) => '${value ?? 'UNKNOWN'}'.toLowerCase();

String _normalizeStatus(Object? value) => '${value ?? ''}'.toUpperCase();
