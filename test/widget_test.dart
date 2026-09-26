import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:padiapps/core/api/api_client.dart';
import 'package:padiapps/core/api/api_providers.dart';
import 'package:padiapps/main.dart';
import 'package:padiapps/shared/models/nursery_models.dart';
import 'package:padiapps/shared/repositories/nursery_repository.dart';

void main() {
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
  Future<DashboardSnapshot> getDashboard() async {
    final now = DateTime.now();
    return DashboardSnapshot(
      device: DeviceStatus(
        code: 'ESP32-01',
        name: 'Nursery Controller',
        status: 'ONLINE',
        lastSeen: now,
      ),
      camera: DeviceStatus(
        code: 'CAM-01',
        name: 'Camera 01',
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
        light: 700,
        ultrasonic: 14,
        createdAt: now,
      ),
      detection: Detection(
        cameraId: 'CAM-01',
        type: 'healthy',
        className: 'Healthy',
        confidence: 0.95,
        image: '',
        detectedAt: now,
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
