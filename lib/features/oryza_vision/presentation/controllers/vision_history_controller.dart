import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_providers.dart';
import '../../data/repositories/vision_history_repository.dart';

enum VisionNetworkStatus { checking, online, offline }

class VisionHistoryState {
  const VisionHistoryState({
    required this.records,
    this.networkStatus = VisionNetworkStatus.checking,
    this.isSyncing = false,
    this.syncMessage,
  });

  final List<VisionScanRecord> records;
  final VisionNetworkStatus networkStatus;
  final bool isSyncing;
  final String? syncMessage;

  int get pendingCount => records
      .where((record) => record.syncStatus != ScanSyncStatus.synced)
      .length;

  VisionHistoryState copyWith({
    List<VisionScanRecord>? records,
    VisionNetworkStatus? networkStatus,
    bool? isSyncing,
    String? syncMessage,
    bool clearMessage = false,
  }) => VisionHistoryState(
    records: records ?? this.records,
    networkStatus: networkStatus ?? this.networkStatus,
    isSyncing: isSyncing ?? this.isSyncing,
    syncMessage: clearMessage ? null : syncMessage ?? this.syncMessage,
  );
}

final visionHistoryRepositoryProvider = Provider<VisionHistoryRepository>((
  ref,
) {
  return VisionHistoryRepository(ref.watch(apiClientProvider));
});

final visionHistoryProvider =
    AsyncNotifierProvider<VisionHistoryController, VisionHistoryState>(
      VisionHistoryController.new,
    );

class VisionHistoryController extends AsyncNotifier<VisionHistoryState> {
  Timer? _timer;
  Timer? _initialSyncTimer;
  bool _syncRunning = false;

  VisionHistoryRepository get _repository =>
      ref.read(visionHistoryRepositoryProvider);

  @override
  Future<VisionHistoryState> build() async {
    ref.onDispose(() {
      _timer?.cancel();
      _initialSyncTimer?.cancel();
    });
    final records = await _repository.loadLocal();
    _timer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => unawaited(sync()),
    );
    _initialSyncTimer = Timer(
      const Duration(milliseconds: 150),
      () => unawaited(sync()),
    );
    return VisionHistoryState(records: records);
  }

  Future<void> addLocal(VisionScanRecord record) async {
    var current = state.value;
    if (current == null) {
      final local = await _repository.loadLocal();
      if (!ref.mounted) return;
      current = VisionHistoryState(records: local);
    }
    final withoutDuplicate = current.records
        .where((item) => item.localId != record.localId)
        .toList();
    state = AsyncData(current.copyWith(records: [record, ...withoutDuplicate]));
    unawaited(sync());
  }

  Future<void> refresh() async {
    final local = await _repository.loadLocal();
    final current = state.value ?? VisionHistoryState(records: local);
    state = AsyncData(current.copyWith(records: local, clearMessage: true));
    await sync();
  }

  Future<void> sync() async {
    if (_syncRunning || !state.hasValue) return;
    _syncRunning = true;
    var current = state.requireValue;
    state = AsyncData(
      current.copyWith(
        isSyncing: true,
        networkStatus: VisionNetworkStatus.checking,
        clearMessage: true,
      ),
    );
    try {
      final online = await _repository.isOnline();
      if (!ref.mounted) return;
      current = state.requireValue;
      if (!online) {
        state = AsyncData(
          current.copyWith(
            isSyncing: false,
            networkStatus: VisionNetworkStatus.offline,
            syncMessage:
                'Anda offline. Hasil scan aman tersimpan di perangkat.',
          ),
        );
        return;
      }

      if (!_repository.isAuthenticated) {
        state = AsyncData(
          current.copyWith(
            isSyncing: false,
            networkStatus: VisionNetworkStatus.online,
            syncMessage:
                'Anda online. Mode tamu menyimpan riwayat scan di perangkat.',
          ),
        );
        return;
      }

      final updated = <VisionScanRecord>[];
      var failures = 0;
      for (final record in current.records) {
        if (record.syncStatus == ScanSyncStatus.synced) {
          updated.add(record);
          continue;
        }
        try {
          updated.add(await _repository.upload(record));
          if (!ref.mounted) return;
        } catch (error) {
          failures++;
          updated.add(
            record.copyWith(
              syncStatus: ScanSyncStatus.failed,
              syncError: _message(error),
            ),
          );
        }
      }
      await _repository.saveAll(updated);
      if (!ref.mounted) return;

      var merged = updated;
      try {
        final remote = await _repository.fetchRemote();
        if (!ref.mounted) return;
        final byId = <String, VisionScanRecord>{};
        for (final record in remote) {
          byId[record.localId] = record;
        }
        for (final record in state.requireValue.records) {
          final existing = byId[record.localId];
          if (existing != null) {
            byId[record.localId] = record.copyWith(
              remoteId: record.remoteId ?? existing.remoteId,
              remoteImageUrl: existing.remoteImageUrl ?? record.remoteImageUrl,
            );
          } else {
            byId[record.localId] = record;
          }
        }
        for (final record in updated) {
          final existing = byId[record.localId];
          if (existing != null) {
            byId[record.localId] = record.copyWith(
              remoteId: record.remoteId ?? existing.remoteId,
              remoteImageUrl: record.remoteImageUrl ?? existing.remoteImageUrl,
            );
          } else {
            byId[record.localId] = record;
          }
        }
        merged = byId.values.toList()
          ..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
      } catch (_) {
        // Upload yang berhasil tetap dicatat meski GET history belum tersedia.
      }
      await _repository.saveAll(merged);
      if (!ref.mounted) return;

      state = AsyncData(
        current.copyWith(
          records: merged,
          isSyncing: false,
          networkStatus: VisionNetworkStatus.online,
          syncMessage: failures == 0
              ? 'Anda online. Riwayat sudah tersinkron.'
              : '$failures riwayat belum dapat disinkronkan ke server.',
        ),
      );
    } finally {
      _syncRunning = false;
      if (ref.mounted && state.hasValue && state.requireValue.isSyncing) {
        state = AsyncData(state.requireValue.copyWith(isSyncing: false));
      }
    }
  }
}

String _message(Object error) =>
    error.toString().replaceFirst('Bad state: ', '');
