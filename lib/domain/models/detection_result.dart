import 'package:equatable/equatable.dart';

/// Result from a single frame of Netra Vision camera detection.
class DetectionResult extends Equatable {
  const DetectionResult({
    required this.detections,
    required this.frameTimestamp,
    required this.inferenceTimeMs,
    required this.modelName,
  });

  final List<Detection> detections;
  final DateTime frameTimestamp;
  final int inferenceTimeMs;
  final String modelName;

  bool get hasSmoke => detections.any((d) => d.label == 'smoke' || d.label == 'industrial_emission' || d.label == 'fire_smoke');
  bool get hasHaze => detections.any((d) => d.label == 'haze');
  bool get hasTraffic => detections.any((d) => d.label == 'heavy_traffic');

  Detection? get highestConfidence {
    if (detections.isEmpty) return null;
    return detections.reduce((a, b) => a.confidence > b.confidence ? a : b);
  }

  /// Calculates a multiplier for exposure based on visual pollution sources.
  double get visionFactor {
    double factor = 1.0;
    
    if (hasSmoke) factor += 0.8; // Heavy smoke observed
    if (hasHaze) factor += 0.3;  // General haze
    if (hasTraffic) factor += 0.4; // High density of vehicles
    
    // Cap it at a reasonable level
    return factor;
  }

  @override
  List<Object?> get props => [detections, frameTimestamp, inferenceTimeMs];
}

/// A single detected object/region.
class Detection extends Equatable {
  const Detection({
    required this.label,
    required this.confidence,
    required this.boundingBox,
  });

  final String label;
  final double confidence; // 0.0 – 1.0
  final BoundingBox boundingBox;

  bool get isHighConfidence => confidence >= 0.8;
  bool get isDisplayable => confidence >= 0.6;

  String get inferredGasLabel {
    switch (label.toLowerCase()) {
      case 'smoke':
      case 'fire_smoke':
        return 'CO / CO2 (Carbon Monoxide)';
      case 'industrial_emission':
        return 'SO2 (Sulfur Dioxide)';
      case 'heavy_traffic':
        return 'NO2 (Nitrogen Dioxide)';
      case 'haze':
        return 'PM2.5 (Fine Particulates)';
      default:
        return 'AIR POLLUTANT';
    }
  }

  int get gasColor {
    switch (label.toLowerCase()) {
      case 'smoke':
      case 'fire_smoke':
        return 0xFFFF3D00; // Deep Orange/Fire
      case 'industrial_emission':
        return 0xFF76FF03; // Neon Green/Toxic
      case 'heavy_traffic':
        return 0xFFFFD600; // Yellow/Exhaust
      case 'haze':
        return 0xFF00E5FF; // Neon Cyan/Dust
      default:
        return 0xFFFFFFFF; // White
    }
  }

  @override
  List<Object?> get props => [label, confidence, boundingBox];
}

/// Bounding box for a detected region, normalized 0.0–1.0.
class BoundingBox extends Equatable {
  const BoundingBox({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get height => bottom - top;
  double get centerX => (left + right) / 2;
  double get centerY => (top + bottom) / 2;

  @override
  List<Object?> get props => [left, top, right, bottom];
}

/// Severity classification of camera-observed pollution.
enum PollutionSeverity {
  clear(label: 'Clear', colorValue: 0xFF4CAF50),
  light(label: 'Light Pollution', colorValue: 0xFFFFEB3B),
  moderate(label: 'Moderate Pollution', colorValue: 0xFFFF9800),
  heavy(label: 'Heavy Pollution', colorValue: 0xFFF44336),
  severe(label: 'Severe Pollution', colorValue: 0xFF9C27B0);

  const PollutionSeverity({required this.label, required this.colorValue});
  final String label;
  final int colorValue;
}
