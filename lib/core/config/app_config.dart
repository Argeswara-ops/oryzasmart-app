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

  static const deviceId = 'ESP32-01';
  static const dataFlow =
      'Flutter -> Laravel API -> MQTT HiveMQ -> Wokwi ESP32';
}
