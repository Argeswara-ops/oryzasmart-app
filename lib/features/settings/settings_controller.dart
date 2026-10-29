import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_providers.dart';
import '../../shared/models/nursery_models.dart';

final sensorThresholdsProvider =
    AsyncNotifierProvider<SensorThresholdsController, List<SensorThreshold>>(
      SensorThresholdsController.new,
    );

class SensorThresholdsController extends AsyncNotifier<List<SensorThreshold>> {
  @override
  Future<List<SensorThreshold>> build() {
    return ref.watch(nurseryRepositoryProvider).getThresholds();
  }

  Future<bool> saveThreshold(SensorThreshold threshold) async {
    final previous = state.value ?? const <SensorThreshold>[];
    try {
      final updated = await ref
          .read(nurseryRepositoryProvider)
          .updateThreshold(
            sensorType: threshold.sensorType,
            minValue: threshold.minValue,
            maxValue: threshold.maxValue,
          );
      state = AsyncData([
        for (final item in previous)
          if (item.sensorType == updated.sensorType) updated else item,
      ]);
      return true;
    } catch (_) {
      state = AsyncData(previous);
      return false;
    }
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(nurseryRepositoryProvider).getThresholds(),
    );
  }
}
