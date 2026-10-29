import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/api_client.dart';
import '../../core/config/app_config.dart';
import '../../core/services/notification_service.dart';
import '../models/nursery_models.dart';

class NurseryRepository {
  NurseryRepository(this._client) {
    NotificationService.instance.onTokenRefresh = syncFcmToken;
  }

  static const _tokenKey = 'oryza_auth_token';
  static const _userIdKey = 'oryza_auth_user_id';
  static const _userNameKey = 'oryza_auth_user_name';
  static const _userEmailKey = 'oryza_auth_user_email';
  static const _userRoleKey = 'oryza_auth_user_role';
  static const _dashboardCacheKey = 'oryza_dashboard_cache_v1';
  static const _sensorHistoryCachePrefix = 'oryza_sensor_history_cache_v1_';
  static const _devicesCacheKey = 'oryza_devices_cache_v1';
  static const _thresholdsCacheKey = 'oryza_thresholds_cache_v1';
  static const _lastSyncKey = 'oryza_last_sync_at';
  static const _supportedThresholdTypes = {
    'temperature',
    'humidity',
    'nitrogen',
    'phosphorus',
    'potassium',
    'light_percent',
    'uv_index',
    'water_level',
  };
  static const _secureStorage = FlutterSecureStorage();

  final ApiClient _client;
  FanState _fan = const FanState(status: 'OFF', mode: 'AUTO');
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
      final fcmToken = NotificationService.instance.fcmToken;
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await syncFcmToken(fcmToken);
      }
      return user;
    } on DioException catch (error) {
      throw LoginException.fromDio(error);
    } on ApiException catch (error) {
      throw LoginException(error.message);
    }
  }

  Future<void> logout() async {
    await removeFcmToken();
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
      final fcmToken = NotificationService.instance.fcmToken;
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await syncFcmToken(fcmToken);
      }
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

  Future<void> syncFcmToken(String? fcmToken) async {
    if (fcmToken == null || fcmToken.isEmpty || _client.token == null) {
      return;
    }

    try {
      await _client.dio.post<Map<String, dynamic>>(
        '/user/fcm-token',
        data: {'fcm_token': fcmToken},
      );
    } on DioException catch (error) {
      developer.log(
        'Failed to sync FCM token with Laravel '
        '(HTTP ${error.response?.statusCode ?? 'network error'}).',
        name: 'NurseryRepository',
      );
    }
  }

  Future<void> removeFcmToken() async {
    if (_client.token == null) return;

    try {
      await _client.dio.delete<Map<String, dynamic>>('/user/fcm-token');
    } on DioException catch (error) {
      developer.log(
        'Failed to remove FCM token from Laravel '
        '(HTTP ${error.response?.statusCode ?? 'network error'}).',
        name: 'NurseryRepository',
      );
    }
  }

  Future<DashboardSnapshot> getDashboard() async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/dashboard',
      );
      final data = _client.dataEnvelope(response);
      if (data.isEmpty) {
        throw const ApiException('Response dashboard Laravel kosong.');
      }
      final snapshot = await _dashboardFromApi(data);
      await _saveJson(_dashboardCacheKey, snapshot.toJson());
      await _recordSuccessfulSync();
      return snapshot;
    } on DioException {
      final cached = await _loadDashboardCache();
      if (cached != null) return cached;
      throw const OfflineDataUnavailableException();
    }
  }

  Future<DashboardSnapshot> _dashboardFromApi(Map<String, dynamic> data) async {
    final alerts = data['alerts'] is List
        ? _applyReadState(_alertsFrom(data['alerts'], const []))
        : _applyReadState(await getAlerts());
    final localUnreadAlerts = alerts.where((alert) => !alert.isRead).length;
    final serverUnreadAlerts = _toInt(data['unread_alerts']);
    final unreadAlerts = serverUnreadAlerts > localUnreadAlerts
        ? (serverUnreadAlerts - _readAlertIds.length).clamp(0, 999)
        : localUnreadAlerts;

    return DashboardSnapshot(
      device: DeviceStatus.fromJson(
        _mapOf(data['device']),
        fallbackCode: AppConfig.deviceId,
        fallbackName: 'Nursery Controller',
        fallbackStatus: data['device_status']?.toString(),
      ),
      sensor: SensorReading.fromJson(
        _mapOf(data['sensors'] ?? data['sensor'] ?? data['latest_sensor']),
      ),
      fan: FanState.fromJson(_mapOf(data['fan'])),
      alerts: alerts,
      recommendation: data['recommendation'] is Map<String, dynamic>
          ? Recommendation.fromJson(
              data['recommendation'] as Map<String, dynamic>,
            )
          : _recommendationFromStatus('${data['system_status'] ?? 'NORMAL'}'),
      systemStatus: '${data['system_status'] ?? 'NORMAL'}',
      unreadAlerts: unreadAlerts,
    );
  }

  Future<List<SensorReading>> getSensorHistory({String range = 'today'}) async {
    final cacheKey = '$_sensorHistoryCachePrefix$range';
    try {
      final response = await _client.dio.get<dynamic>(
        '/sensors/history',
        queryParameters: {'range': range},
      );
      final body = response.data;
      final items = body is Map<String, dynamic>
          ? _seriesFromHistory(body)
          : _client.listEnvelope(response);
      final readings = items
          .whereType<Map<String, dynamic>>()
          .map(SensorReading.fromJson)
          .toList();
      await _saveJson(
        cacheKey,
        readings.map((reading) => reading.toJson()).toList(),
      );
      await _recordSuccessfulSync();
      return readings;
    } on DioException {
      return _loadListCache(cacheKey, SensorReading.fromJson);
    }
  }

  Future<SensorReading> getLatestSensor() async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/sensors/latest',
    );
    return SensorReading.fromJson(_client.dataEnvelope(response));
  }

  Future<List<DeviceStatus>> getDevices() async {
    try {
      final response = await _client.dio.get<dynamic>('/devices');
      final devices = _client
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
      await _saveJson(
        _devicesCacheKey,
        devices.map((device) => device.toJson()).toList(),
      );
      return devices;
    } on DioException {
      return _loadListCache(
        _devicesCacheKey,
        (item) => DeviceStatus.fromJson(
          item,
          fallbackCode: 'ESP32',
          fallbackName: 'Perangkat ESP32',
        ),
      );
    }
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
    try {
      final response = await _client.dio.get<dynamic>('/alerts');
      final alerts = _client
          .listEnvelope(response)
          .whereType<Map<String, dynamic>>()
          .map(SystemAlert.fromJson)
          .toList();
      return _applyReadState(alerts);
    } on DioException {
      return const [];
    }
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
    await prefs.remove(_dashboardCacheKey);
    await prefs.remove(_devicesCacheKey);
    await prefs.remove(_thresholdsCacheKey);
    await prefs.remove(_lastSyncKey);
    final historyKeys = prefs.getKeys().where(
      (key) => key.startsWith(_sensorHistoryCachePrefix),
    );
    for (final key in historyKeys) {
      await prefs.remove(key);
    }
    _readAlertIds.clear();
  }

  Future<DashboardSnapshot?> _loadDashboardCache() async {
    final value = await _loadJson(_dashboardCacheKey);
    if (value is! Map<String, dynamic>) return null;
    try {
      return DashboardSnapshot.fromJson(value);
    } catch (_) {
      return null;
    }
  }

  Future<List<T>> _loadListCache<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final value = await _loadJson(key);
    if (value is! List) return <T>[];
    return value.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }

  Future<Object?> _loadJson(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveJson(String key, Object value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(value));
  }

  Future<void> _recordSuccessfulSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
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
      return const [];
    }
  }

  Future<Recommendation> getLatestRecommendation() async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/recommendations/latest',
      );
      return Recommendation.fromJson(_client.dataEnvelope(response));
    } on DioException {
      return const Recommendation(
        status: 'NORMAL',
        cause: 'Koneksi data rekomendasi belum terhubung.',
        message: 'Lanjutkan pemantauan berkala.',
      );
    }
  }

  Future<FanState> getFanStatus() async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/actuators/fan/status',
        queryParameters: {'device_id': AppConfig.deviceId},
      );
      _fan = FanState.fromJson(_client.dataEnvelope(response));
      return _fan;
    } on DioException catch (error) {
      if (error.response == null) {
        throw const ApiException(
          'Kontrol pompa air tidak tersedia saat offline. Data terakhir tetap ditampilkan.',
        );
      }
      throw ApiException(
        _messageFromResponse(error.response?.data) ??
            'Status pompa air tidak dapat dibaca dari API.',
      );
    }
  }

  Future<FanState> setFanStatus(String status) async {
    return _controlFan(command: status, mode: 'MANUAL');
  }

  Future<FanState> setFanMode(String mode) async {
    return _controlFan(command: _fan.status, mode: mode);
  }

  Future<SensorThreshold> updateThreshold({
    required String sensorType,
    required double minValue,
    required double maxValue,
  }) async {
    final response = await _client.dio.put<Map<String, dynamic>>(
      '/thresholds/$sensorType',
      data: {'min_value': minValue, 'max_value': maxValue},
    );
    final updated = SensorThreshold.fromJson(_client.dataEnvelope(response));
    final cached = await _loadListCache(
      _thresholdsCacheKey,
      SensorThreshold.fromJson,
    );
    await _saveJson(_thresholdsCacheKey, [
      for (final item in cached)
        if (item.sensorType != updated.sensorType) item.toJson(),
      updated.toJson(),
    ]);
    return updated;
  }

  Future<List<SensorThreshold>> getThresholds() async {
    try {
      final response = await _client.dio.get<dynamic>('/thresholds');
      final thresholds = _client
          .listEnvelope(response)
          .whereType<Map<String, dynamic>>()
          .map(SensorThreshold.fromJson)
          .where(
            (threshold) =>
                _supportedThresholdTypes.contains(threshold.sensorType),
          )
          .toList();
      await _saveJson(
        _thresholdsCacheKey,
        thresholds.map((threshold) => threshold.toJson()).toList(),
      );
      return thresholds;
    } on DioException {
      final cached = await _loadListCache(
        _thresholdsCacheKey,
        SensorThreshold.fromJson,
      );
      return cached
          .where(
            (threshold) =>
                _supportedThresholdTypes.contains(threshold.sensorType),
          )
          .toList();
    }
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
    } on DioException catch (error) {
      if (error.response == null) {
        throw const ApiException(
          'Kontrol pompa air tidak tersedia saat offline. Data terakhir tetap ditampilkan.',
        );
      }
      throw ApiException(
        _messageFromResponse(error.response?.data) ??
            'Perintah pompa air ditolak oleh API.',
      );
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

  List<SystemAlert> _alertsFrom(Object? value, List<SystemAlert> fallback) {
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .map(SystemAlert.fromJson)
          .toList();
    }
    return fallback;
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

  Recommendation _recommendationFromStatus(String status) {
    final normalized = status.toUpperCase();
    if (normalized == 'NORMAL') {
      return const Recommendation(
        status: 'NORMAL',
        cause: 'Kondisi nursery normal.',
        message: 'Lanjutkan pemantauan berkala.',
      );
    }
    if (normalized == 'CRITICAL') {
      return const Recommendation(
        status: 'CRITICAL',
        cause: 'Satu atau lebih sensor berada pada kondisi kritis.',
        message: 'Periksa ESP32, sensor, ketinggian air, dan kipas segera.',
      );
    }
    return Recommendation(
      status: normalized,
      cause: 'Satu atau lebih sensor berada di luar ambang normal.',
      message: 'Periksa nilai sensor dan kondisi perangkat lapangan.',
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

class OfflineDataUnavailableException implements Exception {
  const OfflineDataUnavailableException();

  @override
  String toString() =>
      'Anda sedang offline dan belum ada data tersinkron di perangkat ini.';
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
