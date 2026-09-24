import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_providers.dart';
import '../../shared/models/nursery_models.dart';

final dashboardProvider = FutureProvider<DashboardSnapshot>((ref) async {
  return ref.watch(nurseryRepositoryProvider).getDashboard();
});

final sensorHistoryProvider = FutureProvider<List<SensorReading>>((ref) async {
  return ref.watch(nurseryRepositoryProvider).getSensorHistory();
});

final detectionsProvider = FutureProvider<List<Detection>>((ref) async {
  return ref.watch(nurseryRepositoryProvider).getDetections();
});

final fanControllerProvider = AsyncNotifierProvider<FanController, FanState>(
  FanController.new,
);

class FanController extends AsyncNotifier<FanState> {
  @override
  Future<FanState> build() async {
    final dashboard = await ref.watch(dashboardProvider.future);
    return dashboard.fan;
  }

  Future<void> setStatus(String status) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(nurseryRepositoryProvider).setFanStatus(status),
    );
  }

  Future<void> setMode(String mode) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(nurseryRepositoryProvider).setFanMode(mode),
    );
  }
}
