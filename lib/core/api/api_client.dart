import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

class ApiClient {
  ApiClient() : _dio = Dio(_baseOptions) {
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
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
  String? _token;

  Dio get dio => _dio;

  String? get token => _token;

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
    if (body is List) return body;
    if (body is Map<String, dynamic>) {
      _throwWhenUnsuccessful(body);
      final data = body['data'];
      if (data is List) return data;
      if (data is Map<String, dynamic>) {
        for (final key in ['items', 'data', 'series', 'alerts']) {
          final value = data[key];
          if (value is List) return value;
        }
      }
    }
    return const [];
  }

  void _throwWhenUnsuccessful(Map<String, dynamic> body) {
    if (body['success'] == false) {
      throw ApiException('${body['message'] ?? 'Request API gagal.'}');
    }
  }
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
