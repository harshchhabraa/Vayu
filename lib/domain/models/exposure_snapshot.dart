import 'package:equatable/equatable.dart';
import 'package:vayu/domain/models/exposure_entry.dart';
import 'package:vayu/domain/models/health_profile.dart';

/// Defines the mode of transport or movement.
enum ActivityMode { walking, driving, running, indoor }

extension ActivityModeExtension on ActivityMode {
  String get label {
    switch (this) {
      case ActivityMode.walking: return 'Walking';
      case ActivityMode.driving: return 'Driving';
      case ActivityMode.running: return 'Running';
      case ActivityMode.indoor: return 'Indoor';
    }
  }
}

/// A granular record of an exposure event with all governing factors.
class ExposureSnapshot extends Equatable {
  const ExposureSnapshot({
    required this.timestamp,
    required this.aqi,
    required this.activity,
    required this.protectionFactor,
    required this.vulnerabilityFactor,
    required this.visionFactor,
    required this.calculatedScore,
  });

  final DateTime timestamp;
  final double aqi;
  final ActivityMode activity;
  final double protectionFactor;
  final double vulnerabilityFactor;
  final double visionFactor;
  final double calculatedScore;

  /// Multiplier for physical activity/breathing rate.
  double get activityFactor {
    switch (activity) {
      case ActivityMode.running: return 2.5;
      case ActivityMode.walking: return 1.5;
      case ActivityMode.driving: return 1.0;
      case ActivityMode.indoor: return 0.7; // Lowered because of indoor AQI typically being filtered
    }
  }

  @override
  List<Object?> get props => [
    timestamp, aqi, activity, protectionFactor, 
    vulnerabilityFactor, visionFactor, calculatedScore
  ];
}
