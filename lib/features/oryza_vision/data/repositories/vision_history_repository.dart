import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/api/api_client.dart';
import '../../domain/entities/vision_models.dart';

enum ScanSyncStatus { pending, synced, failed }

class VisionScanRecord {
  const VisionScanRecord({
    required this.localId,
    required this.task,
    required this.label,
    required this.displayName,
    required this.confidence,
    required this.scannedAt,
    required this.syncStatus,
    this.localImagePath,
    this.remoteId,
    this.remoteImageUrl,
    this.syncError,
  });

  final String localId;
  final VisionTask task;
  final String label;
  final String displayName;
  final double confidence;
  final DateTime scannedAt;
  final ScanSyncStatus syncStatus;
  final String? localImagePath;
  final int? remoteId;
  final String? remoteImageUrl;
  final String? syncError;

  VisionScanRecord copyWith({
    ScanSyncStatus? syncStatus,
    int? remoteId,
    String? remoteImageUrl,
    String? syncError,
  }) => VisionScanRecord(
    localId: localId,
    task: task,
    label: label,
    displayName: displayName,
    confidence: confidence,
    scannedAt: scannedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    localImagePath: localImagePath,
    remoteId: remoteId ?? this.remoteId,
    remoteImageUrl: remoteImageUrl ?? this.remoteImageUrl,
    syncError: syncError,
  );

  Map<String, dynamic> toJson() => {
    'local_id': localId,
    'scan_type': task.name,
    'class_name': label,
    'display_name': displayName,
    'confidence': confidence,
    'scanned_at': scannedAt.toUtc().toIso8601String(),
    'sync_status': syncStatus.name,
    'local_image_path': localImagePath,
    'remote_id': remoteId,
    'remote_image_url': remoteImageUrl,
    'sync_error': syncError,
  };

  factory VisionScanRecord.fromJson(Map<String, dynamic> json) {
    final type = '${json['scan_type'] ?? json['type']}'.toLowerCase();
    final status = '${json['sync_status'] ?? 'synced'}';
    return VisionScanRecord(
      localId:
          '${json['local_id'] ?? json['client_id'] ?? 'remote-${json['id']}'}',
      task: type == 'pest' ? VisionTask.pest : VisionTask.disease,
      label: '${json['class_name'] ?? json['label'] ?? 'unknown'}',
      displayName:
          '${json['display_name'] ?? json['class_name'] ?? 'Tidak diketahui'}',
      confidence: _toDouble(json['confidence']),
      scannedAt:
          DateTime.tryParse(
            '${json['scanned_at'] ?? json['created_at']}',
          )?.toLocal() ??
          DateTime.now(),
      syncStatus: ScanSyncStatus.values.firstWhere(
        (value) => value.name == status,
        orElse: () => ScanSyncStatus.synced,
      ),
      localImagePath: json['local_image_path'] as String?,
      remoteId: _toInt(json['remote_id'] ?? json['id']),
      remoteImageUrl:
          (json['image_url'] ?? json['remote_image_url']) as String?,
      syncError: json['sync_error'] as String?,
    );
  }
}

class VisionHistoryRepository {
  VisionHistoryRepository(this._client);

  static const _storageKey = 'oryza_vision_scan_history_v1';
  final ApiClient _client;

  Future<List<VisionScanRecord>> loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .whereType<Map<String, dynamic>>()
          .map(VisionScanRecord.fromJson)
          .toList()
        ..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    } catch (_) {
      return [];
    }
  }

  Future<VisionScanRecord> saveLocal(
    VisionPrediction prediction,
    Uint8List imageBytes,
  ) async {
    final now = DateTime.now();
    final id = '${now.microsecondsSinceEpoch}-${prediction.task.name}';
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${root.path}${Platform.pathSeparator}oryza_vision_scans',
    );
    await directory.create(recursive: true);
    final extension = _imageExtension(imageBytes);
    final file = File(
      '${directory.path}${Platform.pathSeparator}$id.$extension',
    );
    await file.writeAsBytes(imageBytes, flush: true);
    final record = VisionScanRecord(
      localId: id,
      task: prediction.task,
      label: prediction.label,
      displayName: _displayName(prediction.label),
      confidence: prediction.probability,
      scannedAt: now,
      syncStatus: ScanSyncStatus.pending,
      localImagePath: file.path,
    );
    final records = await loadLocal();
    await saveAll([record, ...records]);
    return record;
  }

  Future<void> saveAll(List<VisionScanRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(records.map((record) => record.toJson()).toList()),
    );
  }

  Future<bool> isOnline() async {
    try {
      await _client.dio.get<dynamic>(
        '/user',
        options: Options(receiveTimeout: const Duration(seconds: 4)),
      );
      return true;
    } on DioException catch (error) {
      // HTTP response berarti jaringan dan server dapat dijangkau, termasuk 401.
      return error.response != null;
    }
  }

  Future<VisionScanRecord> upload(VisionScanRecord record) async {
    final imagePath = record.localImagePath;
    if (imagePath == null || !await File(imagePath).exists()) {
      throw StateError('File foto lokal tidak ditemukan.');
    }
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/vision/scans',
      data: FormData.fromMap({
        'client_id': record.localId,
        'scan_type': record.task.name,
        'class_name': record.label,
        'display_name': record.displayName,
        'confidence': record.confidence,
        'scanned_at': record.scannedAt.toUtc().toIso8601String(),
        'image': await MultipartFile.fromFile(
          imagePath,
          filename: File(imagePath).uri.pathSegments.last,
        ),
      }),
      options: Options(contentType: Headers.multipartFormDataContentType),
    );
    final data = _client.dataEnvelope(response);
    return record.copyWith(
      syncStatus: ScanSyncStatus.synced,
      remoteId: _toInt(data['id']),
      remoteImageUrl: data['image_url'] as String?,
    );
  }

  Future<List<VisionScanRecord>> fetchRemote() async {
    final response = await _client.dio.get<dynamic>('/vision/scans');
    return _client
        .listEnvelope(response)
        .whereType<Map<String, dynamic>>()
        .map(VisionScanRecord.fromJson)
        .toList();
  }
}

double _toDouble(Object? value) {
  final parsed = value is num
      ? value.toDouble()
      : double.tryParse('$value') ?? 0;
  return parsed > 1 ? parsed / 100 : parsed;
}

int? _toInt(Object? value) => value is int ? value : int.tryParse('$value');

String _imageExtension(Uint8List bytes) {
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return 'png';
  }
  if (bytes.length >= 12 &&
      ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'RIFF' &&
      ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP') {
    return 'webp';
  }
  return 'jpg';
}

String _displayName(String label) => label
    .split('_')
    .map(
      (word) => word.isEmpty
          ? word
          : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
    )
    .join(' ');
