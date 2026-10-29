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

  test('FCM token disinkronkan dan dihapus melalui endpoint Laravel', () async {
    final client = ApiClient();
    final adapter = _RecordingAdapter();
    client.dio.httpClientAdapter = adapter;
    final repository = NurseryRepository(client);
    client.setToken('test-sanctum-token');

    await repository.syncFcmToken('test-fcm-registration-token');
    await repository.removeFcmToken();

    expect(adapter.requests, hasLength(2));
    expect(adapter.requests[0].method, 'POST');
    expect(adapter.requests[0].path, '/user/fcm-token');
    expect(adapter.requests[0].data, {
      'fcm_token': 'test-fcm-registration-token',
    });
    expect(
      adapter.requests[0].headers['Authorization'],
      'Bearer test-sanctum-token',
    );
    expect(adapter.requests[1].method, 'DELETE');
    expect(adapter.requests[1].path, '/user/fcm-token');
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  final List<String> paths = [];
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.path);
    requests.add(options);
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
