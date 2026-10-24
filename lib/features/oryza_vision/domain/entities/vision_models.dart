enum VisionTask { disease, pest }

extension VisionTaskX on VisionTask {
  String get title => this == VisionTask.disease ? 'Penyakit' : 'Hama';
  String get scanTitle => 'Scan $title Padi';
  String get assetPrefix =>
      'assets/models/oryza-vision/${this == VisionTask.disease ? 'disease' : 'pest'}';
}

class VisionModelConfig {
  const VisionModelConfig({
    required this.task,
    required this.inputShape,
    required this.resizeShorterSide,
    required this.cropWidth,
    required this.cropHeight,
    required this.mean,
    required this.std,
    required this.labels,
  });

  final VisionTask task;
  final List<int> inputShape;
  final int resizeShorterSide;
  final int cropWidth;
  final int cropHeight;
  final List<double> mean;
  final List<double> std;
  final List<String> labels;

  factory VisionModelConfig.fromJson(
    VisionTask task,
    Map<String, dynamic> json,
    List<String> labels,
  ) {
    final preprocessing = json['image_preprocessing'] as Map<String, dynamic>;
    final crop = (preprocessing['center_crop'] as List).cast<num>();
    return VisionModelConfig(
      task: task,
      inputShape: (json['input_shape'] as List)
          .cast<num>()
          .map((e) => e.toInt())
          .toList(),
      resizeShorterSide: (preprocessing['resize_shorter_side'] as num).toInt(),
      cropWidth: crop[0].toInt(),
      cropHeight: crop[1].toInt(),
      mean: (preprocessing['normalize_mean'] as List)
          .cast<num>()
          .map((e) => e.toDouble())
          .toList(),
      std: (preprocessing['normalize_std'] as List)
          .cast<num>()
          .map((e) => e.toDouble())
          .toList(),
      labels: List.unmodifiable(labels),
    );
  }
}

class VisionPrediction {
  const VisionPrediction({
    required this.task,
    required this.label,
    required this.probability,
    required this.probabilities,
  });

  final VisionTask task;
  final String label;
  final double probability;
  final Map<String, double> probabilities;
}

class VisionKnowledge {
  const VisionKnowledge({
    required this.name,
    required this.description,
    required this.recommendation,
    this.source = 'IRRI Rice Knowledge Bank',
  });

  final String name;
  final String description;
  final String recommendation;
  final String source;
}
