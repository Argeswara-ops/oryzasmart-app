import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_providers.dart';
import '../../shared/models/nursery_models.dart';

const _dashboardRefreshInterval = Duration(seconds: 5);
const _historyRefreshInterval = Duration(seconds: 12);

final dashboardProvider = StreamProvider<DashboardSnapshot>((ref) {
  final repository = ref.watch(nurseryRepositoryProvider);
  return _poll(repository.getDashboard, _dashboardRefreshInterval);
});

final sensorHistoryProvider =
    StreamProvider.family<List<SensorReading>, String>((ref, range) {
      final repository = ref.watch(nurseryRepositoryProvider);
      return _poll(
        () => repository.getSensorHistory(range: _apiRange(range)),
        _historyRefreshInterval,
      );
    });

final detectionsProvider = StreamProvider<List<Detection>>((ref) {
  final repository = ref.watch(nurseryRepositoryProvider);
  return _poll(repository.getDetections, _historyRefreshInterval);
});

final visionFocusAlertProvider =
    NotifierProvider<VisionFocusAlertController, SystemAlert?>(
      VisionFocusAlertController.new,
    );

final visionSelectedDetectionProvider =
    NotifierProvider<VisionSelectedDetectionController, Detection?>(
      VisionSelectedDetectionController.new,
    );

final fanControllerProvider = AsyncNotifierProvider<FanController, FanState>(
  FanController.new,
);

final fanControlBusyProvider = NotifierProvider<FanControlBusyController, bool>(
  FanControlBusyController.new,
);
final fanControlErrorProvider =
    NotifierProvider<FanControlErrorController, Object?>(
      FanControlErrorController.new,
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
          mode: 'MANUAL',
        );
    ref.read(fanControlErrorProvider.notifier).setError(null);
    ref.read(fanControlBusyProvider.notifier).setBusy(true);
    state = AsyncData(optimistic);

    final result = await AsyncValue.guard(
      () => ref.read(nurseryRepositoryProvider).setFanStatus(status),
    );
    state = result.hasError && previous != null ? AsyncData(previous) : result;
    ref.read(fanControlBusyProvider.notifier).setBusy(false);
    if (!result.hasError) {
      ref.invalidate(dashboardProvider);
    } else {
      ref.read(fanControlErrorProvider.notifier).setError(result.error);
    }
  }

  Future<void> setMode(String mode) async {
    final previous = state.hasValue ? state.value : null;
    final optimistic = (previous ?? const FanState(status: 'OFF', mode: 'AUTO'))
        .copyWith(mode: mode);
    ref.read(fanControlErrorProvider.notifier).setError(null);
    ref.read(fanControlBusyProvider.notifier).setBusy(true);
    state = AsyncData(optimistic);

    final result = await AsyncValue.guard(
      () => ref.read(nurseryRepositoryProvider).setFanMode(mode),
    );
    state = result.hasError && previous != null ? AsyncData(previous) : result;
    ref.read(fanControlBusyProvider.notifier).setBusy(false);
    if (!result.hasError) {
      ref.invalidate(dashboardProvider);
    } else {
      ref.read(fanControlErrorProvider.notifier).setError(result.error);
    }
  }
}

class FanControlBusyController extends Notifier<bool> {
  @override
  bool build() => false;

  void setBusy(bool value) {
    state = value;
  }
}

class FanControlErrorController extends Notifier<Object?> {
  @override
  Object? build() => null;

  void setError(Object? error) {
    state = error;
  }
}

class VisionFocusAlertController extends Notifier<SystemAlert?> {
  @override
  SystemAlert? build() => null;

  void setAlert(SystemAlert? alert) {
    state = alert;
  }
}

class VisionSelectedDetectionController extends Notifier<Detection?> {
  @override
  Detection? build() => null;

  void select(Detection? detection) {
    state = detection;
  }
}

String _apiRange(String value) {
  return switch (value) {
    '7d' => '7days',
    '30d' => '30days',
    _ => value,
  };
}

Stream<T> _poll<T>(Future<T> Function() fetch, Duration interval) {
  return Stream<T>.multi((controller) {
    Timer? timer;
    var isFetching = false;

    Future<void> tick() async {
      if (isFetching || controller.isClosed) return;
      isFetching = true;
      try {
        final value = await fetch();
        if (!controller.isClosed) controller.add(value);
      } catch (error, stackTrace) {
        if (!controller.isClosed) controller.addError(error, stackTrace);
      } finally {
        isFetching = false;
      }
    }

    tick();
    timer = Timer.periodic(interval, (_) => tick());
    controller.onCancel = () => timer?.cancel();
  });
}
