import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../models/nursery_models.dart';

class NurseryRepository {
  NurseryRepository(this._client);

  final ApiClient _client;
  FanState _fan = const FanState(status: 'ON', mode: 'AUTO');

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/login',
      data: {'email': email, 'password': password},
    );
    final data = _client.dataEnvelope(response);
    final token = '${data['token'] ?? ''}';
    if (token.isEmpty) {
      throw StateError('Token login tidak ditemukan dari backend.');
    }

    _client.setToken(token);
    final user = data['user'] is Map<String, dynamic>
        ? AuthUser.fromJson(data['user'] as Map<String, dynamic>)
        : AuthUser.fallback(email);
    return user;
  }

  Future<void> logout() async {
    try {
      await _client.dio.post<Map<String, dynamic>>('/logout');
    } on DioException {
      // Sesi lokal tetap perlu dibersihkan saat backend tidak terjangkau.
    } finally {
      _client.clearToken();
    }
  }

  Future<DashboardSnapshot> getDashboard() async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/dashboard',
      );
      final data = _client.dataEnvelope(response);
      if (data.isEmpty) return _mockDashboard();

      final fallback = _mockDashboard();
      return DashboardSnapshot(
        device: DeviceStatus.fromJson(
          _mapOf(data['device']),
          fallbackCode: 'ESP32-01',
          fallbackName: 'Nursery Controller',
          fallbackStatus: data['device_status']?.toString(),
        ),
        camera: DeviceStatus.fromJson(
          _mapOf(data['camera']),
          fallbackCode: 'CAM-01',
          fallbackName: 'Camera 01',
          fallbackStatus: 'ONLINE',
        ),
        sensor: SensorReading.fromJson(
          _mapOf(data['sensors'] ?? data['sensor'] ?? data['latest_sensor']),
        ),
        detection: Detection.fromJson(
          _mapOf(data['latest_detection'] ?? data['detection']),
        ),
        fan: FanState.fromJson(_mapOf(data['fan'])),
        alerts: _alertsFrom(data['alerts'], fallback.alerts),
        recommendation: data['recommendation'] is Map<String, dynamic>
            ? Recommendation.fromJson(
                data['recommendation'] as Map<String, dynamic>,
              )
            : _recommendationFromStatus(
                '${data['system_status'] ?? 'NORMAL'}',
                fallback.recommendation,
              ),
        systemStatus: '${data['system_status'] ?? 'NORMAL'}',
        unreadAlerts: _toInt(data['unread_alerts']),
      );
    } on DioException {
      return _mockDashboard();
    }
  }

  Future<List<SensorReading>> getSensorHistory({String range = '7days'}) async {
    try {
      final response = await _client.dio.get<dynamic>(
        '/sensors/history',
        queryParameters: {'range': range},
      );
      final body = response.data;
      final items = body is Map<String, dynamic>
          ? _seriesFromHistory(body)
          : _client.listEnvelope(response);
      return items
          .whereType<Map<String, dynamic>>()
          .map(SensorReading.fromJson)
          .toList();
    } on DioException {
      return _mockSensorHistory();
    }
  }

  Future<SensorReading> getLatestSensor() async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/sensors/latest',
      );
      return SensorReading.fromJson(_client.dataEnvelope(response));
    } on DioException {
      return _mockDashboard().sensor;
    }
  }

  Future<List<DeviceStatus>> getDevices() async {
    try {
      final response = await _client.dio.get<dynamic>('/devices');
      return _client
          .listEnvelope(response)
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => DeviceStatus.fromJson(
              item,
              fallbackCode: 'ESP32-01',
              fallbackName: 'Nursery Controller',
            ),
          )
          .toList();
    } on DioException {
      return [_mockDashboard().device];
    }
  }

  Future<List<DeviceStatus>> getCameras() async {
    try {
      final response = await _client.dio.get<dynamic>('/cameras');
      return _client
          .listEnvelope(response)
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => DeviceStatus.fromJson(
              item,
              fallbackCode: 'CAM-01',
              fallbackName: 'Camera 01',
            ),
          )
          .toList();
    } on DioException {
      return [_mockDashboard().camera];
    }
  }

  Future<List<Detection>> getDetections({String? type, String? camera}) async {
    try {
      final queryParameters = <String, dynamic>{
        if (type != null && type != 'all') 'type': type,
      };
      if (camera != null) queryParameters['camera'] = camera;

      final response = await _client.dio.get<dynamic>(
        '/detections',
        queryParameters: queryParameters,
      );
      return _client
          .listEnvelope(response)
          .whereType<Map<String, dynamic>>()
          .map(Detection.fromJson)
          .toList();
    } on DioException {
      return _mockDetections();
    }
  }

  Future<Detection> getLatestDetection() async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/detections/latest',
      );
      return Detection.fromJson(_client.dataEnvelope(response));
    } on DioException {
      return _mockDashboard().detection;
    }
  }

  Future<List<SystemAlert>> getAlerts() async {
    try {
      final response = await _client.dio.get<dynamic>('/alerts');
      return _client
          .listEnvelope(response)
          .whereType<Map<String, dynamic>>()
          .map(SystemAlert.fromJson)
          .toList();
    } on DioException {
      return _mockDashboard().alerts;
    }
  }

  Future<void> markAlertRead(int id) async {
    try {
      await _client.dio.post<Map<String, dynamic>>('/alerts/$id/read');
    } on DioException {
      // Status baca akan ikut sinkron saat refresh backend berikutnya.
    }
  }

  Future<List<Recommendation>> getRecommendations() async {
    try {
      final response = await _client.dio.get<dynamic>('/recommendations');
      return _client
          .listEnvelope(response)
          .whereType<Map<String, dynamic>>()
          .map(Recommendation.fromJson)
          .toList();
    } on DioException {
      return [_mockDashboard().recommendation];
    }
  }

  Future<Recommendation> getLatestRecommendation() async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/recommendations/latest',
      );
      return Recommendation.fromJson(_client.dataEnvelope(response));
    } on DioException {
      return _mockDashboard().recommendation;
    }
  }

  Future<FanState> getFanStatus() async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/actuators/fan/status',
      );
      _fan = FanState.fromJson(_client.dataEnvelope(response));
      return _fan;
    } on DioException {
      return _fan;
    }
  }

  Future<FanState> setFanStatus(String status) async {
    return _controlFan(command: status, mode: _fan.mode);
  }

  Future<FanState> setFanMode(String mode) async {
    return _controlFan(command: _fan.status, mode: mode);
  }

  Future<void> updateThreshold({
    required String sensorType,
    required double minValue,
    required double maxValue,
  }) async {
    await _client.dio.put<Map<String, dynamic>>(
      '/thresholds/$sensorType',
      data: {'min_value': minValue, 'max_value': maxValue},
    );
  }

  Future<List<Map<String, dynamic>>> getThresholds() async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/thresholds',
      );
      final data = _client.dataEnvelope(response);
      if (data['thresholds'] is List) {
        return (data['thresholds'] as List)
            .whereType<Map<String, dynamic>>()
            .toList();
      }
      return data.entries
          .where((entry) => entry.value is Map<String, dynamic>)
          .map(
            (entry) => {
              'sensor_type': entry.key,
              ...(entry.value as Map<String, dynamic>),
            },
          )
          .toList();
    } on DioException {
      return const [];
    }
  }

  Future<FanState> _controlFan({
    required String command,
    required String mode,
  }) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/actuators/fan/control',
        data: {'device_id': 'ESP32-01', 'command': command, 'mode': mode},
      );
      final data = _client.dataEnvelope(response);
      _fan = data.isEmpty
          ? _fan.copyWith(status: command, mode: mode)
          : FanState.fromJson(data);
    } on DioException {
      _fan = _fan.copyWith(status: command, mode: mode);
    }
    return _fan;
  }

  List<dynamic> _seriesFromHistory(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      final series = data['series'];
      if (series is List) return series;
    }
    return _client.listEnvelope(
      Response<dynamic>(
        data: body,
        requestOptions: RequestOptions(path: ''),
      ),
    );
  }

  List<SystemAlert> _alertsFrom(Object? value, List<SystemAlert> fallback) {
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .map(SystemAlert.fromJson)
          .toList();
    }
    return fallback;
  }

  Recommendation _recommendationFromStatus(
    String status,
    Recommendation fallback,
  ) {
    final normalized = status.toUpperCase();
    if (normalized == 'NORMAL') {
      return const Recommendation(
        status: 'NORMAL',
        cause: 'Kondisi nursery normal.',
        message: 'Lanjutkan pemantauan berkala.',
      );
    }
    return Recommendation(
      status: normalized,
      cause: fallback.cause,
      message: fallback.message,
    );
  }

  Map<String, dynamic> _mapOf(Object? value) {
    return value is Map<String, dynamic> ? value : <String, dynamic>{};
  }

  int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  DashboardSnapshot _mockDashboard() {
    final now = DateTime.now();
    return DashboardSnapshot(
      device: DeviceStatus(
        code: 'ESP32-01',
        name: 'Nursery Controller',
        status: 'ONLINE',
        lastSeen: now.subtract(const Duration(seconds: 18)),
      ),
      camera: DeviceStatus(
        code: 'CAM-01',
        name: 'Camera 01',
        status: 'ONLINE',
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
      systemStatus: 'WARNING',
      unreadAlerts: 2,
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

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  final int id;
  final String name;
  final String email;
  final String role;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      name: '${json['name'] ?? 'Operator Pembibitan'}',
      email: '${json['email'] ?? 'operator@padibackend.test'}',
      role: '${json['role'] ?? 'operator'}',
    );
  }

  factory AuthUser.fallback(String email) {
    return AuthUser(
      id: 0,
      name: 'Operator Pembibitan',
      email: email,
      role: 'operator',
    );
  }
}
