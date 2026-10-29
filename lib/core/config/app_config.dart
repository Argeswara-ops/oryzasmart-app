import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  const AppConfig._();

  static const appName = 'ORYZA SMART';

  static String get apiBaseUrl {
    try {
      return dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api';
    } catch (_) {
      return 'http://10.0.2.2:8000/api';
    }
  }

  static String get deviceId {
    try {
      return dotenv.env['DEVICE_ID'] ?? 'ESP32-01';
    } catch (_) {
      return 'ESP32-01';
    }
  }

  static String get mqttBroker {
    try {
      return dotenv.env['MQTT_BROKER'] ?? 'broker.hivemq.com:1883';
    } catch (_) {
      return 'broker.hivemq.com:1883';
    }
  }

  static String get databaseInfo {
    try {
      return dotenv.env['DB_INFO'] ?? 'MySQL (padibackend @ 3306)';
    } catch (_) {
      return 'MySQL (padibackend @ 3306)';
    }
  }

  static String get mqttSensorTopic => 'oryza-smart/$deviceId/sensors';
  static String get mqttStatusTopic => 'oryza-smart/$deviceId/status';
  static String get mqttActuatorTopic => 'oryza-smart/$deviceId/actuator/fan/command';

  static const dataFlow =
      'ESP32 Wokwi -> HiveMQ MQTT -> Laravel Backend -> MySQL -> REST API -> Flutter Mobile';

  /// Resolves an image URL from backend so that localhost/127.0.0.1/10.0.2.2 or
  /// relative storage URLs resolve to the actual active backend server host.
  static String resolveImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmed = url.trim();
    final baseUri = Uri.tryParse(apiBaseUrl);
    if (baseUri == null) return trimmed;

    final origin = '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';

    if (trimmed.startsWith('/')) {
      return '$origin$trimmed';
    }

    final uri = Uri.tryParse(trimmed);
    if (uri != null) {
      final host = uri.host.toLowerCase();
      if (host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2') {
        return uri.replace(
          scheme: baseUri.scheme,
          host: baseUri.host,
          port: baseUri.hasPort ? baseUri.port : null,
        ).toString();
      }
    }

    return trimmed;
  }
}
