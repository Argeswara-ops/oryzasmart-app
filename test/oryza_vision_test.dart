import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:padiapps/features/oryza_vision/data/services/image_preprocessing_service.dart';
import 'package:padiapps/features/oryza_vision/data/services/vision_model_service.dart';
import 'package:padiapps/features/oryza_vision/data/repositories/vision_history_repository.dart';
import 'package:padiapps/features/oryza_vision/domain/entities/vision_models.dart';
import 'package:padiapps/features/oryza_vision/presentation/controllers/vision_history_controller.dart';
import 'package:padiapps/features/oryza_vision/presentation/screens/scan_screen.dart';
import 'package:padiapps/features/oryza_vision/presentation/screens/vision_screen.dart';
import 'package:padiapps/core/api/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const config = VisionModelConfig(
    task: VisionTask.disease,
    inputShape: [1, 224, 224, 3],
    resizeShorterSide: 256,
    cropWidth: 224,
    cropHeight: 224,
    mean: [0.485, 0.456, 0.406],
    std: [0.229, 0.224, 0.225],
    labels: ['a', 'b'],
  );

  test('preprocessing menghasilkan tensor NHWC RGB ternormalisasi', () {
    final source = img.Image(width: 300, height: 256);
    img.fill(source, color: img.ColorRgb8(255, 0, 0));
    final result = preprocessImage(<String, Object>{
      'bytes': Uint8List.fromList(img.encodePng(source)),
      'resize': config.resizeShorterSide,
      'width': config.cropWidth,
      'height': config.cropHeight,
      'mean': config.mean,
      'std': config.std,
    });
    expect(result, hasLength(224 * 224 * 3));
    expect(result[0], closeTo((1 - 0.485) / 0.229, 0.0001));
    expect(result[1], closeTo((0 - 0.456) / 0.224, 0.0001));
    expect(result[2], closeTo((0 - 0.406) / 0.225, 0.0001));
  });

  test('preprocessing menolak input yang bukan gambar', () {
    expect(
      () => preprocessImage(<String, Object>{
        'bytes': Uint8List.fromList([1, 2, 3]),
        'resize': 256,
        'width': 224,
        'height': 224,
        'mean': config.mean,
        'std': config.std,
      }),
      throwsFormatException,
    );
  });

  test('softmax stabil dan berjumlah satu', () {
    final probabilities = softmax([1001, 1002, 1003]);
    expect(probabilities.reduce((a, b) => a + b), closeTo(1, 1e-9));
    expect(
      probabilities.indexOf(probabilities.reduce((a, b) => a > b ? a : b)),
      2,
    );
  });

  test('metadata dan label kedua model konsisten', () async {
    for (final task in VisionTask.values) {
      final metadata =
          jsonDecode(
                await rootBundle.loadString(
                  '${task.assetPrefix}_preprocessing.json',
                ),
              )
              as Map<String, dynamic>;
      final labels =
          (jsonDecode(
                    await rootBundle.loadString(
                      '${task.assetPrefix}_labels.json',
                    ),
                  )
                  as List)
              .cast<String>();
      final parsed = VisionModelConfig.fromJson(task, metadata, labels);
      expect(parsed.inputShape, [1, 224, 224, 3]);
      expect(
        parsed.labels,
        task == VisionTask.disease ? hasLength(5) : hasLength(3),
      );
      expect(metadata['labels'], labels);
    }
  });

  test(
    'kedua model dapat dimuat dan menjalankan inference',
    () async {
      final source = img.Image(width: 320, height: 256);
      img.fill(source, color: img.ColorRgb8(90, 150, 70));
      final bytes = Uint8List.fromList(img.encodeJpg(source));
      final service = VisionModelService();
      try {
        for (final task in VisionTask.values) {
          final result = await service.classify(bytes, task);
          final expectedLabels = task == VisionTask.disease
              ? const [
                  'Bacterial_Blight',
                  'Brown_Spot',
                  'Healthy',
                  'Leaf_Blast',
                  'Leaf_Scald',
                ]
              : const [
                  'Brown_Planthopper',
                  'Rice_Leaf_Roller',
                  'Rice_Leafhopper',
                ];
          expect(result.label, isIn(expectedLabels));
          expect(result.probabilities, hasLength(expectedLabels.length));
          expect(result.probability, inInclusiveRange(0, 1));
        }
      } finally {
        await service.dispose();
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
    skip: Platform.isWindows
        ? 'TensorFlow Lite DLL tidak tersedia pada runner unit-test Windows; jalankan pada Android.'
        : false,
  );

  testWidgets('alur scan menawarkan kamera dan galeri', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ScanScreen(task: VisionTask.disease)),
      ),
    );
    expect(find.text('Buka Kamera'), findsOneWidget);
    expect(find.text('Pilih dari Galeri'), findsOneWidget);
    expect(find.text('Scan Penyakit Padi'), findsWidgets);
  });

  test('riwayat pending tetap lokal lalu sinkron saat online', () async {
    final pending = VisionScanRecord(
      localId: 'local-1',
      task: VisionTask.pest,
      label: 'Brown_Planthopper',
      displayName: 'Wereng Batang Cokelat',
      confidence: .88,
      scannedAt: DateTime(2026, 10, 24),
      syncStatus: ScanSyncStatus.pending,
      localImagePath: 'fake.jpg',
    );
    final repository = _FakeVisionHistoryRepository([pending]);
    final container = ProviderContainer(
      overrides: [
        visionHistoryRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(visionHistoryProvider.future);

    await container.read(visionHistoryProvider.notifier).sync();
    expect(
      container.read(visionHistoryProvider).requireValue.networkStatus,
      VisionNetworkStatus.offline,
    );
    expect(container.read(visionHistoryProvider).requireValue.pendingCount, 1);

    final disease = VisionScanRecord(
      localId: 'local-2',
      task: VisionTask.disease,
      label: 'Leaf_Blast',
      displayName: 'Blas Daun',
      confidence: .91,
      scannedAt: DateTime(2026, 10, 24, 1),
      syncStatus: ScanSyncStatus.pending,
      localImagePath: 'disease.jpg',
    );
    await container.read(visionHistoryProvider.notifier).addLocal(disease);
    final localState = container.read(visionHistoryProvider).requireValue;
    expect(
      localState.records.map((item) => item.task),
      containsAll(VisionTask.values),
    );
    expect(localState.pendingCount, 2);

    repository.online = true;
    await container.read(visionHistoryProvider.notifier).sync();
    final state = container.read(visionHistoryProvider).requireValue;
    expect(state.networkStatus, VisionNetworkStatus.online);
    expect(state.pendingCount, 0);
    expect(state.records, hasLength(2));
    expect(state.records.every((record) => record.remoteId == 99), isTrue);
  });

  testWidgets('notifikasi koneksi dapat ditutup dan hilang otomatis', (
    tester,
  ) async {
    const online = VisionHistoryState(
      records: [],
      networkStatus: VisionNetworkStatus.online,
      syncMessage: 'Riwayat sudah tersinkron.',
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VisionConnectionNotice(
            state: online,
            visibleDuration: Duration(seconds: 5),
          ),
        ),
      ),
    );
    expect(find.text('Anda online'), findsOneWidget);
    await tester.tap(find.byTooltip('Tutup notifikasi'));
    await tester.pumpAndSettle();
    expect(find.text('Anda online'), findsNothing);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VisionConnectionNotice(
            key: ValueKey('offline-notice'),
            state: VisionHistoryState(
              records: [],
              networkStatus: VisionNetworkStatus.offline,
            ),
            visibleDuration: Duration(milliseconds: 100),
          ),
        ),
      ),
    );
    expect(find.text('Anda sedang offline'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 110));
    await tester.pumpAndSettle();
    expect(find.text('Anda sedang offline'), findsNothing);
  });

  testWidgets('detail history scan tidak menampilkan identitas kamera', (
    tester,
  ) async {
    final record = VisionScanRecord(
      localId: 'local-2',
      task: VisionTask.disease,
      label: 'Leaf_Blast',
      displayName: 'Blas Daun',
      confidence: .91,
      scannedAt: DateTime(2026, 10, 24, 8, 30),
      syncStatus: ScanSyncStatus.synced,
      remoteId: 7,
    );
    await tester.pumpWidget(
      MaterialApp(home: VisionHistoryDetailScreen(record: record)),
    );
    await tester.scrollUntilVisible(
      find.text('Penyimpanan'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Detail Riwayat Scan'), findsOneWidget);
    expect(find.text('Scan Penyakit'), findsOneWidget);
    expect(find.textContaining('CAM-'), findsNothing);
    expect(find.text('Lokal & database'), findsOneWidget);
  });
}

class _FakeVisionHistoryRepository extends VisionHistoryRepository {
  _FakeVisionHistoryRepository(this.records) : super(ApiClient());

  List<VisionScanRecord> records;
  bool online = false;

  @override
  Future<List<VisionScanRecord>> loadLocal() async => records;

  @override
  Future<bool> isOnline() async => online;

  @override
  Future<VisionScanRecord> upload(VisionScanRecord record) async =>
      record.copyWith(
        syncStatus: ScanSyncStatus.synced,
        remoteId: 99,
        remoteImageUrl: 'https://example.test/scan.jpg',
      );

  @override
  Future<List<VisionScanRecord>> fetchRemote() async => const [];

  @override
  Future<void> saveAll(List<VisionScanRecord> records) async {
    this.records = records;
  }
}
