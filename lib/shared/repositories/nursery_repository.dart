import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/api_client.dart';
import '../../core/config/app_config.dart';
import '../models/nursery_models.dart';

class NurseryRepository {
  NurseryRepository(this._client);

  static const _tokenKey = 'oryza_auth_token';
  static const _userIdKey = 'oryza_auth_user_id';
  static const _userNameKey = 'oryza_auth_user_name';
  static const _userEmailKey = 'oryza_auth_user_email';
  static const _userRoleKey = 'oryza_auth_user_role';
  static const _secureStorage = FlutterSecureStorage();

  final ApiClient _client;
  FanState _fan = const FanState(status: 'ON', mode: 'AUTO');
  final Set<int> _readAlertIds = {};

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/login',
        data: {'email': email, 'password': password},
      );
      final data = _client.dataEnvelope(response);
      final token = '${data['token'] ?? ''}';
      if (token.isEmpty) {
        throw const LoginException('Token login tidak ditemukan dari backend.');
      }

      _client.setToken(token);
      final user = data['user'] is Map<String, dynamic>
          ? AuthUser.fromJson(data['user'] as Map<String, dynamic>)
          : AuthUser.fallback(email);
      await _saveSession(token: token, user: user);
      return user;
    } on DioException catch (error) {
      throw LoginException.fromDio(error);
    } on ApiException catch (error) {
      throw LoginException(error.message);
    }
  }

  Future<void> logout() async {
    try {
      await _client.dio.post<Map<String, dynamic>>('/logout');
    } on DioException {
      // Sesi lokal tetap perlu dibersihkan saat backend tidak terjangkau.
    } finally {
      _client.clearToken();
      await _clearSession();
    }
  }

  Future<AuthUser?> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacyToken = prefs.getString(_tokenKey);
      final token = await _secureStorage.read(key: _tokenKey) ?? legacyToken;
      final email = prefs.getString(_userEmailKey);
      if (token == null || token.isEmpty || email == null || email.isEmpty) {
        return null;
      }

      if (legacyToken != null && legacyToken.isNotEmpty) {
        await _secureStorage.write(key: _tokenKey, value: legacyToken);
        await prefs.remove(_tokenKey);
      }
      _client.setToken(token);
      return AuthUser(
        id: prefs.getInt(_userIdKey) ?? 0,
        name: prefs.getString(_userNameKey) ?? 'Operator Pembibitan',
        email: email,
        role: prefs.getString(_userRoleKey) ?? 'operator',
      );
    } catch (_) {
      return null;
    }
  }

  Future<DashboardSnapshot> getDashboard() async {
    final response = await _client.dio.get<Map<String, dynamic>>('/dashboard');
    final data = _client.dataEnvelope(response);
    if (data.isEmpty) {
      throw const ApiException('Response dashboard Laravel kosong.');
    }

    final alerts = _applyReadState(_alertsFrom(data['alerts']));
    final localUnreadAlerts = alerts.where((alert) => !alert.isRead).length;
    final serverUnreadAlerts = _toInt(data['unread_alerts']);
    final unreadAlerts = serverUnreadAlerts > localUnreadAlerts
        ? (serverUnreadAlerts - _readAlertIds.length).clamp(0, 999)
        : localUnreadAlerts;

    final systemStatus = '${data['system_status'] ?? 'NORMAL'}';
    final recommendation = await _dashboardRecommendation(
      data['recommendation'],
      systemStatus,
    );

    return DashboardSnapshot(
      device: DeviceStatus.fromJson(
        _mapOf(data['device']),
        fallbackCode: AppConfig.deviceId,
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
      alerts: alerts,
      recommendation: recommendation,
      systemStatus: systemStatus,
      unreadAlerts: unreadAlerts,
    );
  }

  Future<List<SensorReading>> getSensorHistory({String range = 'today'}) async {
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
  }

  Future<SensorReading> getLatestSensor() async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/sensors/latest',
    );
    return SensorReading.fromJson(_client.dataEnvelope(response));
  }

  Future<List<DeviceStatus>> getDevices() async {
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
  }

  Future<List<DeviceStatus>> getCameras() async {
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
  }

  Future<List<Detection>> getDetections({String? type, String? camera}) async {
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
  }

  Future<Detection> getLatestDetection() async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/detections/latest',
    );
    return Detection.fromJson(_client.dataEnvelope(response));
  }

  Future<PaddyPrediction> predictPaddyImage(XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          bytes,
          filename: image.name.isEmpty ? 'paddy-image.jpg' : image.name,
        ),
      });
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/paddy/predict',
        data: formData,
        options: Options(contentType: Headers.multipartFormDataContentType),
      );
      final body = response.data ?? <String, dynamic>{};
      final prediction = body['prediction'] is Map<String, dynamic>
          ? body['prediction'] as Map<String, dynamic>
          : _client.dataEnvelope(response);
      return PaddyPrediction.fromJson(prediction);
    } on DioException catch (error) {
      throw PredictionException.fromDio(error);
    }
  }

  Future<List<SystemAlert>> getAlerts() async {
    final response = await _client.dio.get<dynamic>('/alerts');
    final alerts = _client
        .listEnvelope(response)
        .whereType<Map<String, dynamic>>()
        .map(SystemAlert.fromJson)
        .toList();
    return _applyReadState(alerts);
  }

  Future<void> markAlertRead(int id) async {
    _readAlertIds.add(id);
    try {
      await _client.dio.post<Map<String, dynamic>>('/alerts/$id/read');
    } on DioException {
      // Status baca akan ikut sinkron saat refresh backend berikutnya.
    }
  }

  Future<void> _saveSession({
    required String token,
    required AuthUser user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.write(key: _tokenKey, value: token);
    await prefs.remove(_tokenKey);
    await prefs.setInt(_userIdKey, user.id);
    await prefs.setString(_userNameKey, user.name);
    await prefs.setString(_userEmailKey, user.email);
    await prefs.setString(_userRoleKey, user.role);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.delete(key: _tokenKey);
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userRoleKey);
    _readAlertIds.clear();
  }

  Future<List<Recommendation>> getRecommendations() async {
    final response = await _client.dio.get<dynamic>('/recommendations');
    return _client
        .listEnvelope(response)
        .whereType<Map<String, dynamic>>()
        .map(Recommendation.fromJson)
        .toList();
  }

  Future<Recommendation> getLatestRecommendation() async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/recommendations/latest',
    );
    return Recommendation.fromJson(_client.dataEnvelope(response));
  }

  Future<FanState> getFanStatus() async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/actuators/fan/status',
      );
      _fan = FanState.fromJson(_client.dataEnvelope(response));
      return _fan;
    } on DioException {
      rethrow;
    }
  }

  Future<FanState> setFanStatus(String status) async {
    return _controlFan(command: status, mode: 'MANUAL');
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
    final response = await _client.dio.get<dynamic>('/thresholds');
    final list = _client.listEnvelope(response);
    if (list.isNotEmpty) {
      return list.whereType<Map<String, dynamic>>().toList();
    }
    final body = response.data;
    final data = body is Map<String, dynamic>
        ? _client.dataEnvelope(
            Response<Map<String, dynamic>>(
              data: body,
              requestOptions: response.requestOptions,
            ),
          )
        : <String, dynamic>{};
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
  }

  Future<FanState> _controlFan({
    required String command,
    required String mode,
  }) async {
    try {
      final normalizedCommand = command.toUpperCase();
      final normalizedMode = mode.toUpperCase();
      final isAuto = normalizedCommand == 'AUTO' || normalizedMode == 'AUTO';
      final payload = <String, dynamic>{
        'device_id': AppConfig.deviceId,
        'command': isAuto ? 'AUTO' : normalizedCommand,
        if (!isAuto) 'mode': 'MANUAL',
      };
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/actuators/fan/control',
        data: payload,
      );
      final data = _client.dataEnvelope(response);
      _fan = data.isEmpty ? await getFanStatus() : FanState.fromJson(data);
    } on DioException {
      rethrow;
    }
    return _fan;
  }

  List<dynamic> _seriesFromHistory(Map<String, dynamic> body) {
    if (body['success'] == false) {
      throw ApiException('${body['message'] ?? 'Request API gagal.'}');
    }
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

  List<SystemAlert> _alertsFrom(Object? value) {
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .map(SystemAlert.fromJson)
          .toList();
    }
    return const [];
  }

  List<SystemAlert> _applyReadState(List<SystemAlert> alerts) {
    return [
      for (final alert in alerts)
        if (alert.id != null && _readAlertIds.contains(alert.id))
          alert.copyWith(isRead: true)
        else
          alert,
    ];
  }

  Future<Recommendation> _dashboardRecommendation(
    Object? value,
    String status,
  ) async {
    if (value is Map<String, dynamic>) {
      return Recommendation.fromJson(value);
    }
    try {
      return await getLatestRecommendation();
    } on DioException {
      return _recommendationFromStatus(status);
    }
  }

  Recommendation _recommendationFromStatus(String status) {
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
      cause: 'Kondisi nursery memerlukan perhatian.',
      message: 'Periksa sensor dan kondisi tanaman terbaru.',
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
}

class LoginException implements Exception {
  const LoginException(this.message);

  final String message;

  factory LoginException.fromDio(DioException error) {
    final statusCode = error.response?.statusCode;
    final message = _messageFromResponse(error.response?.data);
    if (statusCode == 401 || statusCode == 422) {
      return LoginException(message ?? 'Email atau password tidak sesuai.');
    }
    if (statusCode != null) {
      return LoginException(
        message ?? 'Backend menolak login. Kode HTTP $statusCode.',
      );
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return LoginException(
        'Backend tidak merespons di ${AppConfig.apiBaseUrl}. Pastikan HP satu Wi-Fi dan firewall Windows mengizinkan port 8000.',
      );
    }
    return LoginException(
      'Backend tidak terjangkau dari perangkat di ${AppConfig.apiBaseUrl}. Periksa jaringan, IP laptop, dan firewall.',
    );
  }

  @override
  String toString() => message;
}

class PredictionException implements Exception {
  const PredictionException(this.message);

  final String message;

  factory PredictionException.fromDio(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    final nestedMessage = data is Map<String, dynamic> && data['error'] is Map
        ? _messageFromResponse(data['error'])
        : null;
    final message = nestedMessage ?? _messageFromResponse(data);
    if (statusCode != null) {
      return PredictionException(
        message ?? 'Prediksi gagal diproses. Kode HTTP $statusCode.',
      );
    }
    return const PredictionException(
      'Backend prediksi tidak terjangkau. Periksa koneksi dan base URL API.',
    );
  }

  @override
  String toString() => message;
}

String? _messageFromResponse(dynamic data) {
  if (data is Map<String, dynamic>) {
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) return message;
  }
  return null;
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
