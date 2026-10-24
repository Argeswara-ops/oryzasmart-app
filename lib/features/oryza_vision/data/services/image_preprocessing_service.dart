import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../domain/entities/vision_models.dart';

class ImagePreprocessingService {
  const ImagePreprocessingService();

  Future<Float32List> preprocess(Uint8List bytes, VisionModelConfig config) {
    return Isolate.run(
      () => preprocessImage(<String, Object>{
        'bytes': bytes,
        'resize': config.resizeShorterSide,
        'width': config.cropWidth,
        'height': config.cropHeight,
        'mean': config.mean,
        'std': config.std,
      }),
    );
  }
}

// Top-level and public so the exact preprocessing can be unit tested.
Float32List preprocessImage(Map<String, Object> arguments) {
  final bytes = arguments['bytes']! as Uint8List;
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('File bukan gambar yang dapat dibaca.');
  }

  final oriented = img.bakeOrientation(decoded);
  final shorter = arguments['resize']! as int;
  final portrait = oriented.width < oriented.height;
  final resized = img.copyResize(
    oriented,
    // Sama dengan torchvision Resize(int): sisi pendek tepat pada nilai
    // metadata dan sisi panjang menggunakan pembulatan ke bawah.
    width: portrait
        ? shorter
        : (oriented.width * shorter / oriented.height).floor(),
    height: portrait
        ? (oriented.height * shorter / oriented.width).floor()
        : shorter,
    interpolation: img.Interpolation.linear,
  );
  final cropWidth = arguments['width']! as int;
  final cropHeight = arguments['height']! as int;
  if (resized.width < cropWidth || resized.height < cropHeight) {
    throw const FormatException(
      'Resolusi gambar terlalu kecil untuk diproses.',
    );
  }
  final cropped = img.copyCrop(
    resized,
    x: (resized.width - cropWidth) ~/ 2,
    y: (resized.height - cropHeight) ~/ 2,
    width: cropWidth,
    height: cropHeight,
  );
  final mean = (arguments['mean']! as List).cast<double>();
  final std = (arguments['std']! as List).cast<double>();
  final tensor = Float32List(cropWidth * cropHeight * 3);
  var offset = 0;
  for (var y = 0; y < cropHeight; y++) {
    for (var x = 0; x < cropWidth; x++) {
      final pixel = cropped.getPixel(x, y);
      tensor[offset++] = (pixel.r / 255.0 - mean[0]) / std[0];
      tensor[offset++] = (pixel.g / 255.0 - mean[1]) / std[1];
      tensor[offset++] = (pixel.b / 255.0 - mean[2]) / std[2];
    }
  }
  return tensor;
}
