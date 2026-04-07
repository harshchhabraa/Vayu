import 'dart:math';
import 'package:vayu/domain/models/health_profile.dart';
import 'package:vayu/domain/models/exposure_snapshot.dart';

/// Pure logic for calculating personalized air quality exposure.
/// 
/// Formula: Exposure = AQI × time × activity × vulnerability × protection × vision_factor
class ExposureCalculator {
  /// Deterministically calculates an exposure score based on specific health and environment factors.
  static double calculate({
    required double aqi,
    required Duration interval,
    required ActivityMode activity,
    required HealthProfile profile,
    double visionFactor = 1.0,
  }) {
    if (interval.inSeconds <= 0) return 0.0;

    // 1. Time in hours (exposure is cumulative over time)
    final double timeInHours = interval.inSeconds / 3600.0;

    // 2. Multipliers from the domain models
    final double activityMultiplier = _mapActivityToFactor(activity);
    final double vulnerabilityMultiplier = profile.sensitivityFactor;
    final double protectionMultiplier = profile.protectionFactor;

    // 3. The Enterprise Formula
    final double results = 
        aqi * 
        timeInHours * 
        activityMultiplier * 
        vulnerabilityMultiplier * 
        protectionMultiplier * 
        visionFactor;

    // 4. Normalization for UI readability (100 AQI × 1 Hour = 1.0 Units)
    const double normalizationConstant = 0.01;
    return max(0.0, results * normalizationConstant);
  }

  static double _mapActivityToFactor(ActivityMode mode) {
    switch (mode) {
      case ActivityMode.walking: return 1.5;
      case ActivityMode.driving: return 1.0;
      case ActivityMode.running: return 2.5;
      case ActivityMode.indoor: return 0.7;
    }
  }
}
