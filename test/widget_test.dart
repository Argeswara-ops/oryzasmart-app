import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:padiapps/core/api/api_client.dart';
import 'package:padiapps/core/api/api_providers.dart';
import 'package:padiapps/main.dart';
import 'package:padiapps/shared/models/nursery_models.dart';
import 'package:padiapps/shared/repositories/nursery_repository.dart';

void main() {
  test('snapshot dasbor dapat diserialisasi untuk cache offline', () {
    final snapshot = _FakeRepository().dashboardSnapshot();
    final restored = DashboardSnapshot.fromJson(snapshot.toJson());

    expect(restored.sensor.temperature, snapshot.sensor.temperature);
    expect(restored.device.code, snapshot.device.code);
    expect(restored.recommendation.status, snapshot.recommendation.status);
    expect(restored.alerts, hasLength(snapshot.alerts.length));
    expect(restored.sensor.waterLevel, 64);
  });

  test('status kipas membaca bentuk respons actuator dari API', () {
    final fan = FanState.fromJson({
      'actuator': {'status': 'ON', 'mode': 'AUTO'},
    });

    expect(fan.status, 'ON');
    expect(fan.mode, 'AUTO');
  });

  test('model membaca kontrak device dan sensor API terbaru', () {
    final device = DeviceStatus.fromJson(
      {
        'device_code': 'ESP32-01',
        'name': 'ESP32 Utama',
        'location': 'Rumah Kaca',
        'status': 'ONLINE',
        'is_online': true,
        'last_seen': '2026-10-28T05:30:00.000Z',
        'fan': {'status': 'ON', 'is_on': true, 'mode': 'AUTO'},
        'latest_sensor': {
          'temperature': 28.5,
          'light_percent': 65,
          'uv_index': 3.2,
          'water_level_percent': 72,
          'distance_cm': 18,
          'recorded_at': '2026-10-28T05:30:00.000Z',
        },
      },
      fallbackCode: 'ESP32',
      fallbackName: 'ESP32',
    );

    expect(device.isOnline, isTrue);
    expect(device.location, 'Rumah Kaca');
    expect(device.fan?.status, 'ON');
    expect(device.latestSensor?.lightPercent, 65);
    expect(device.latestSensor?.uvIndex, 3.2);
    expect(device.latestSensor?.waterLevel, 72);
  });

  test('sensor membaca objek water_level alternatif', () {
    final sensor = SensorReading.fromJson({
      'water_level': {'distance_cm': 21, 'percent': 68},
    });

    expect(sensor.ultrasonic, 21);
    expect(sensor.waterLevel, 68);
  });

  testWidgets('shows login then opens dashboard', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nurseryRepositoryProvider.overrideWithValue(_FakeRepository()),
        ],
        child: const SmartRiceNurseryApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pantau Bibit Padi'), findsOneWidget);

    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();

    expect(find.text('ORYZA SMART'), findsOneWidget);
    expect(find.text('Masuk Akun'), findsOneWidget);

    await tester.tap(find.text('Masuk'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('ORYZA SMART'), findsOneWidget);
  });

  testWidgets('mode tamu hanya membuka Vision tanpa login', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nurseryRepositoryProvider.overrideWithValue(_FakeRepository()),
        ],
        child: const SmartRiceNurseryApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lanjut sebagai Tamu'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Mode tamu'), findsOneWidget);
    expect(find.text('Vision'), findsOneWidget);
    expect(find.text('Dasbor'), findsNothing);
    expect(find.text('Device'), findsNothing);
    expect(find.text('Settings'), findsNothing);
  });
}

class _FakeRepository extends NurseryRepository {
  _FakeRepository() : super(ApiClient());

  @override
  Future<AuthUser?> restoreSession() async => null;

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    return AuthUser(id: 1, name: 'Operator', email: email, role: 'operator');
  }

  @override
  Future<FanState> getFanStatus() async {
    return const FanState(status: 'ON', mode: 'AUTO');
  }

  @override
  Future<DashboardSnapshot> getDashboard() async {
    return dashboardSnapshot();
  }

  DashboardSnapshot dashboardSnapshot() {
    final now = DateTime.now();
    return DashboardSnapshot(
      device: DeviceStatus(
        code: 'ESP32-01',
        name: 'Nursery Controller',
        status: 'ONLINE',
        lastSeen: now,
      ),
      sensor: SensorReading(
        deviceId: 'ESP32-01',
        temperature: 29,
        humidity: 78,
        nitrogen: 40,
        phosphorus: 20,
        potassium: 30,
        light: 65,
        lightPercent: 65,
        uvIndex: 3.2,
        ultrasonic: 14,
        waterLevel: 64,
        createdAt: now,
      ),
      fan: const FanState(status: 'ON', mode: 'AUTO'),
      alerts: const [],
      recommendation: const Recommendation(
        status: 'NORMAL',
        cause: 'Kondisi nursery normal.',
        message: 'Lanjutkan pemantauan berkala.',
      ),
      systemStatus: 'NORMAL',
      unreadAlerts: 0,
    );
  }
}
