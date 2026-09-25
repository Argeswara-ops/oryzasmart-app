import 'package:dio/dio.dart';

import '../config/app_config.dart';

class ApiClient {
  ApiClient()
    : dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
          headers: {'Accept': 'application/json'},
        ),
      );

  final Dio dio;
}
