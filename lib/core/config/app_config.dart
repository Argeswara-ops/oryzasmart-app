import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  const AppConfig._();

  static const appName = 'ORYZA SMART';
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api';
  static const mqttSensorTopic = 'rice-nursery/sensors';
  static const mqttFanCommandTopic = 'rice-nursery/actuator/fan/command';
}
