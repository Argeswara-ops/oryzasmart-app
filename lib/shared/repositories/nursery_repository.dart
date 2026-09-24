import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../models/nursery_models.dart';

class NurseryRepository {
  NurseryRepository(this._client);

  final ApiClient _client;
  FanState _fan = const FanState(status: 'ON', mode: 'AUTO');

  Future<DashboardSnapshot> getDashboard() async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/dashboard',
      );
      final data = response.data;
      if (data == null) return _mockDashboard();

      return DashboardSnapshot(
        device: DeviceStatus(
          code: '${data['device']?['device_code'] ?? 'ESP32-01'}',
          name: '${data['device']?['name'] ?? 'Nursery Controller'}',
          status: '${data['device']?['status'] ?? 'online'}',
          lastSeen: DateTime.now(),
        ),
        camera: DeviceStatus(
          code: '${data['camera']?['code'] ?? 'CAM-01'}',
          name: '${data['camera']?['name'] ?? 'Camera 01'}',
          status: '${data['camera']?['status'] ?? 'online'}',
          lastSeen: DateTime.now(),
        ),
        sensor: SensorReading.fromJson(
          data['sensor'] ?? data['latest_sensor'] ?? {},
        ),
        detection: Detection.fromJson(
          data['detection'] ?? data['latest_detection'] ?? {},
        ),
        fan: _fan,
        alerts: _mockDashboard().alerts,
        recommendation: _mockDashboard().recommendation,
      );
    } on DioException {
      return _mockDashboard();
    }
  }

  Future<List<SensorReading>> getSensorHistory() async {
    try {
      final response = await _client.dio.get<List<dynamic>>('/sensors/history');
      return response.data
              ?.whereType<Map<String, dynamic>>()
              .map(SensorReading.fromJson)
              .toList() ??
          _mockSensorHistory();
    } on DioException {
      return _mockSensorHistory();
    }
  }

  Future<List<Detection>> getDetections() async {
    try {
      final response = await _client.dio.get<List<dynamic>>('/detections');
      return response.data
              ?.whereType<Map<String, dynamic>>()
              .map(Detection.fromJson)
              .toList() ??
          _mockDetections();
    } on DioException {
      return _mockDetections();
    }
  }

  Future<FanState> setFanStatus(String status) async {
    try {
      await _client.dio.post(
        '/actuators/fan/control',
        data: {'command': status},
      );
    } on DioException {
      // Local fallback keeps the MVP usable before Laravel and MQTT are online.
    }
    _fan = _fan.copyWith(status: status);
    return _fan;
  }

  Future<FanState> setFanMode(String mode) async {
    try {
      await _client.dio.post('/actuators/fan/mode', data: {'mode': mode});
    } on DioException {
      // Local fallback keeps the MVP usable before Laravel and MQTT are online.
    }
    _fan = _fan.copyWith(mode: mode);
    return _fan;
  }

  DashboardSnapshot _mockDashboard() {
    final now = DateTime.now();
    return DashboardSnapshot(
      device: DeviceStatus(
        code: 'ESP32-01',
        name: 'Nursery Controller',
        status: 'online',
        lastSeen: now.subtract(const Duration(seconds: 18)),
      ),
      camera: DeviceStatus(
        code: 'CAM-01',
        name: 'Camera 01',
        status: 'online',
        lastSeen: now.subtract(const Duration(seconds: 31)),
      ),
      sensor: SensorReading(
        deviceId: 'ESP32-01',
        temperature: 29.4,
        humidity: 81,
        nitrogen: 40,
        phosphorus: 22,
        potassium: 31,
        light: 720,
        ultrasonic: 14,
        createdAt: now,
      ),
      detection: Detection(
        cameraId: 'CAM-01',
        type: 'disease',
        className: 'Rice Blast',
        confidence: 0.92,
        image: 'detections/cam01-001.jpg',
        detectedAt: now.subtract(const Duration(minutes: 6)),
      ),
      fan: _fan,
      alerts: [
        SystemAlert(
          level: 'WARNING',
          title: 'Kelembapan tinggi',
          message: 'Kelembapan udara berada di 81%.',
          createdAt: now.subtract(const Duration(minutes: 8)),
        ),
        SystemAlert(
          level: 'WARNING',
          title: 'Rice Blast terdeteksi',
          message: 'CAM-01 mendeteksi penyakit dengan confidence 92%.',
          createdAt: now.subtract(const Duration(minutes: 6)),
        ),
      ],
      recommendation: const Recommendation(
        status: 'PERLU PERHATIAN',
        cause: 'Kelembapan udara tinggi dan Rice Blast terdeteksi.',
        message:
            'Periksa tanaman pada area CAM-01 dan jaga sirkulasi udara pembibitan.',
      ),
    );
  }

  List<SensorReading> _mockSensorHistory() {
    final now = DateTime.now();
    return List.generate(12, (index) {
      final offset = 11 - index;
      return SensorReading(
        deviceId: 'ESP32-01',
        temperature: 27.8 + (index % 5) * 0.6,
        humidity: 76 + (index % 4) * 2,
        nitrogen: 38 + (index % 3),
        phosphorus: 21 + (index % 2),
        potassium: 30 + (index % 4),
        light: 640 + index * 12,
        ultrasonic: 16 - (index % 4),
        createdAt: now.subtract(Duration(hours: offset * 2)),
      );
    });
  }

  List<Detection> _mockDetections() {
    final now = DateTime.now();
    return [
      Detection(
        cameraId: 'CAM-01',
        type: 'disease',
        className: 'Rice Blast',
        confidence: 0.92,
        image: 'detections/cam01-001.jpg',
        detectedAt: now.subtract(const Duration(minutes: 6)),
      ),
      Detection(
        cameraId: 'CAM-01',
        type: 'pest',
        className: 'Brown Planthopper',
        confidence: 0.87,
        image: 'detections/cam01-002.jpg',
        detectedAt: now.subtract(const Duration(hours: 1, minutes: 31)),
      ),
      Detection(
        cameraId: 'CAM-01',
        type: 'healthy',
        className: 'Healthy',
        confidence: 0.96,
        image: 'detections/cam01-003.jpg',
        detectedAt: now.subtract(const Duration(hours: 4)),
      ),
    ];
  }
}
