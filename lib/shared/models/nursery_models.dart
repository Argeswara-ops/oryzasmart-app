class DashboardSnapshot {
  const DashboardSnapshot({
    required this.device,
    required this.camera,
    required this.sensor,
    required this.detection,
    required this.fan,
    required this.alerts,
    required this.recommendation,
  });

  final DeviceStatus device;
  final DeviceStatus camera;
  final SensorReading sensor;
  final Detection detection;
  final FanState fan;
  final List<SystemAlert> alerts;
  final Recommendation recommendation;
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
      deviceId: '${json['device_id'] ?? 'ESP32-01'}',
      temperature: _toDouble(json['temperature']),
      humidity: _toDouble(json['humidity']),
      nitrogen: _toDouble(json['nitrogen']),
      phosphorus: _toDouble(json['phosphorus']),
      potassium: _toDouble(json['potassium']),
      light: _toDouble(json['light']),
      ultrasonic: _toDouble(json['ultrasonic']),
      createdAt:
          DateTime.tryParse('${json['created_at'] ?? ''}') ?? DateTime.now(),
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
    return Detection(
      cameraId: '${json['camera_id'] ?? 'CAM-01'}',
      type: '${json['type'] ?? 'unknown'}',
      className: '${json['class_name'] ?? json['class'] ?? 'unknown'}',
      confidence: _toDouble(json['confidence']),
      image: '${json['image'] ?? ''}',
      detectedAt:
          DateTime.tryParse('${json['detected_at'] ?? ''}') ?? DateTime.now(),
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
}

class FanState {
  const FanState({required this.status, required this.mode});

  final String status;
  final String mode;

  FanState copyWith({String? status, String? mode}) {
    return FanState(status: status ?? this.status, mode: mode ?? this.mode);
  }
}

class SystemAlert {
  const SystemAlert({
    required this.level,
    required this.title,
    required this.message,
    required this.createdAt,
  });

  final String level;
  final String title;
  final String message;
  final DateTime createdAt;
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
}

double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}
