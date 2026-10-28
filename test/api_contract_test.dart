import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:padiapps/core/api/api_client.dart';
import 'package:padiapps/shared/repositories/nursery_repository.dart';

void main() {
  test(
    'alur data utama tidak meminta endpoint kamera atau detection',
    () async {
      SharedPreferences.setMockInitialValues({});
      final client = ApiClient();
      final adapter = _RecordingAdapter();
      client.dio.httpClientAdapter = adapter;
      final repository = NurseryRepository(client);

      final dashboard = await repository.getDashboard();
      await repository.getDevices();
      await repository.getLatestSensor();

      expect(dashboard.sensor.temperature, 28.5);
      expect(dashboard.sensor.humidity, 76);
      expect(dashboard.sensor.nitrogen, isNull);
      expect(
        adapter.paths,
        containsAll(['/dashboard', '/devices', '/sensors/latest']),
      );
      expect(
        adapter.paths.where(
          (path) => path.contains('/cameras') || path.contains('/detections'),
        ),
        isEmpty,
      );
    },
  );
}

class _RecordingAdapter implements HttpClientAdapter {
  final List<String> paths = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.path);
    final data = switch (options.path) {
      '/dashboard' => {
        'data': {
          'device': {
            'status': 'ONLINE',
            'is_online': true,
            'last_seen': '2026-10-28T05:30:00.000Z',
          },
          'sensors': {
            'temperature': 28.5,
            'humidity': 76,
            'recorded_at': '2026-10-28T05:30:00.000Z',
          },
          'fan': {'status': 'OFF', 'is_on': false, 'mode': 'MANUAL'},
          'alerts': <Object>[],
        },
      },
      '/devices' => {'data': <Object>[]},
      '/sensors/latest' => {
        'data': {
          'temperature': 28.5,
          'humidity': 76,
          'recorded_at': '2026-10-28T05:30:00.000Z',
        },
      },
      _ => {'data': <Object>[]},
    };

    return ResponseBody.fromString(
      jsonEncode(data),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
