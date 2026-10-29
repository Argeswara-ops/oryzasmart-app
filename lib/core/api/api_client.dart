import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

enum AppConnectionStatus { checking, online, offline }

class ApiClient {
  ApiClient() : _dio = Dio(_baseOptions) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          _lastOnlineTime = DateTime.now();
          _setConnectionStatus(AppConnectionStatus.online);
          handler.next(response);
        },
        onError: (error, handler) {
          if (error.response == null) {
            _lastOfflineTime ??= DateTime.now();
            _setConnectionStatus(AppConnectionStatus.offline);
          } else {
            _lastOnlineTime = DateTime.now();
            _setConnectionStatus(AppConnectionStatus.online);
          }
          handler.next(error);
        },
      ),
    );
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: false,
          responseBody: false,
          error: true,
          logPrint: (object) => debugPrint(object.toString()),
        ),
      );
    }
  }

  static final _baseOptions = BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
    headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
  );

  final Dio _dio;
  final StreamController<AppConnectionStatus> _connectionController =
      StreamController<AppConnectionStatus>.broadcast();
  String? _token;
  AppConnectionStatus _connectionStatus = AppConnectionStatus.checking;
  DateTime? _lastOnlineTime = DateTime.now();
  DateTime? _lastOfflineTime;

  Dio get dio => _dio;

  String? get token => _token;
  AppConnectionStatus get connectionStatus => _connectionStatus;
  DateTime? get lastOnlineTime => _lastOnlineTime;
  DateTime? get lastOfflineTime => _lastOfflineTime;
  Stream<AppConnectionStatus> get connectionChanges =>
      _connectionController.stream;

  void _setConnectionStatus(AppConnectionStatus status) {
    if (status == AppConnectionStatus.online) {
      _lastOnlineTime = DateTime.now();
      _lastOfflineTime = null;
    } else if (status == AppConnectionStatus.offline) {
      _lastOfflineTime ??= DateTime.now();
    }
    if (_connectionStatus == status) return;
    _connectionStatus = status;
    _connectionController.add(status);
  }

  void setToken(String token) {
    _token = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    _token = null;
    _dio.options.headers.remove('Authorization');
  }

  Map<String, dynamic> dataEnvelope(Response<Map<String, dynamic>> response) {
    final body = response.data ?? <String, dynamic>{};
    _throwWhenUnsuccessful(body);
    final payload = body['data'];
    return payload is Map<String, dynamic> ? payload : body;
  }

  List<dynamic> listEnvelope(Response<dynamic> response) {
    final body = response.data;
    if (body is Map<String, dynamic>) {
      _throwWhenUnsuccessful(body);
      final payload = body['data'];
      if (payload is List) return payload;
    }
    if (body is List) return body;
    return const [];
  }

  void _throwWhenUnsuccessful(Map<String, dynamic> body) {
    if (body['success'] == false) {
      final message = body['message'] ?? 'Permintaan API gagal.';
      throw ApiException(message.toString());
    }
  }
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
