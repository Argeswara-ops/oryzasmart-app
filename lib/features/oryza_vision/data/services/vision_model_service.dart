import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../domain/entities/vision_models.dart';
import 'image_preprocessing_service.dart';

class VisionModelService {
  VisionModelService({ImagePreprocessingService? preprocessor})
    : _preprocessor = preprocessor ?? const ImagePreprocessingService();

  final ImagePreprocessingService _preprocessor;
  Interpreter? _interpreter;
  IsolateInterpreter? _isolateInterpreter;
  VisionModelConfig? _config;

  Future<VisionPrediction> classify(
    Uint8List imageBytes,
    VisionTask task,
  ) async {
    await _ensureLoaded(task);
    final config = _config!;
    final input = await _preprocessor.preprocess(imageBytes, config);
    final shapedInput = input.toList().reshape<double>(config.inputShape);
    final output = List<double>.filled(
      config.labels.length,
      0,
    ).reshape<double>([1, config.labels.length]);
    await _isolateInterpreter!.run(shapedInput, output);
    final logits = output.first as List<double>;
    final probabilities = softmax(logits);
    var best = 0;
    for (var i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > probabilities[best]) best = i;
    }
    return VisionPrediction(
      task: task,
      label: config.labels[best],
      probability: probabilities[best],
      probabilities: {
        for (var i = 0; i < config.labels.length; i++)
          config.labels[i]: probabilities[i],
      },
    );
  }

  Future<void> _ensureLoaded(VisionTask task) async {
    if (_config?.task == task && _interpreter != null) return;
    await dispose();
    final report =
        jsonDecode(
              await rootBundle.loadString(
                'assets/models/oryza-vision/conversion_report.json',
              ),
            )
            as Map<String, dynamic>;
    final key = task == VisionTask.disease ? 'disease' : 'pest';
    final validation = report[key] as Map<String, dynamic>?;
    final details = validation?['validation'] as Map<String, dynamic>?;
    if (validation?['status'] != 'validated' || details?['passed'] != true) {
      throw StateError(
        'Model ${task.title.toLowerCase()} belum lolos validasi konversi.',
      );
    }
    final labels =
        (jsonDecode(
                  await rootBundle.loadString(
                    '${task.assetPrefix}_labels.json',
                  ),
                )
                as List)
            .cast<String>();
    final metadata =
        jsonDecode(
              await rootBundle.loadString(
                '${task.assetPrefix}_preprocessing.json',
              ),
            )
            as Map<String, dynamic>;
    final config = VisionModelConfig.fromJson(task, metadata, labels);
    final interpreter = await Interpreter.fromAsset(
      '${task.assetPrefix}_model.tflite',
    );
    try {
      _validateInterpreter(interpreter, config);
      _interpreter = interpreter;
      _isolateInterpreter = await IsolateInterpreter.create(
        address: interpreter.address,
        debugName: 'OryzaVision-${task.name}',
      );
      _config = config;
    } catch (_) {
      interpreter.close();
      rethrow;
    }
  }

  void _validateInterpreter(Interpreter interpreter, VisionModelConfig config) {
    final inputs = interpreter.getInputTensors();
    final outputs = interpreter.getOutputTensors();
    if (inputs.length != 1 || outputs.length != 1) {
      throw StateError(
        'Model harus memiliki tepat satu input dan satu output.',
      );
    }
    if (inputs.single.type != TensorType.float32 ||
        outputs.single.type != TensorType.float32) {
      throw StateError('Model harus menggunakan tensor Float32.');
    }
    if (!_sameShape(inputs.single.shape, config.inputShape)) {
      throw StateError(
        'Input model ${inputs.single.shape} tidak sesuai metadata ${config.inputShape}.',
      );
    }
    final outputShape = outputs.single.shape;
    if (outputShape.isEmpty || outputShape.last != config.labels.length) {
      throw StateError('Jumlah output model tidak sesuai dengan urutan label.');
    }
  }

  Future<void> dispose() async {
    await _isolateInterpreter?.close();
    _isolateInterpreter = null;
    _interpreter?.close();
    _interpreter = null;
    _config = null;
  }
}

bool _sameShape(List<int> a, List<int> b) =>
    a.length == b.length &&
    List.generate(a.length, (i) => a[i] == b[i]).every((e) => e);

List<double> softmax(List<double> logits) {
  if (logits.isEmpty) {
    throw ArgumentError.value(logits, 'logits', 'Tidak boleh kosong');
  }
  final maximum = logits.reduce(math.max);
  final exponents = logits.map((value) => math.exp(value - maximum)).toList();
  final total = exponents.reduce((a, b) => a + b);
  return exponents.map((value) => value / total).toList(growable: false);
}
