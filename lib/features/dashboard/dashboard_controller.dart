import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_providers.dart';
import '../../shared/models/nursery_models.dart';

final dashboardProvider = FutureProvider<DashboardSnapshot>((ref) async {
  return ref.watch(nurseryRepositoryProvider).getDashboard();
});

final sensorHistoryProvider =
    FutureProvider.family<List<SensorReading>, String>((ref, range) async {
      return ref
          .watch(nurseryRepositoryProvider)
          .getSensorHistory(range: _apiRange(range));
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
    final previous = state.hasValue ? state.value : null;
    final optimistic =
        (previous ?? const FanState(status: 'OFF', mode: 'MANUAL')).copyWith(
          status: status,
        );
    state = AsyncData(optimistic);

    final result = await AsyncValue.guard(
      () => ref.read(nurseryRepositoryProvider).setFanStatus(status),
    );
    state = result.hasError && previous != null ? AsyncData(previous) : result;
  }

  Future<void> setMode(String mode) async {
    final previous = state.hasValue ? state.value : null;
    final optimistic = (previous ?? const FanState(status: 'OFF', mode: 'AUTO'))
        .copyWith(mode: mode);
    state = AsyncData(optimistic);

    final result = await AsyncValue.guard(
      () => ref.read(nurseryRepositoryProvider).setFanMode(mode),
    );
    state = result.hasError && previous != null ? AsyncData(previous) : result;
  }
}

String _apiRange(String value) {
  return switch (value) {
    '7d' => '7days',
    '30d' => '30days',
    _ => value,
  };
}
