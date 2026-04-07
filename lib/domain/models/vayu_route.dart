import 'package:latlong2/latlong.dart';

/// Raw computed routing response from ORS parsing
class RouteCandidate {
  final List<LatLng> polyline;
  final double distanceMeters;
  final double durationSeconds;
  final List<RouteStep> steps;

  RouteCandidate({
    required this.polyline,
    required this.distanceMeters,
    required this.durationSeconds,
    this.steps = const [],
  });
}

/// Individual Turn-By-Turn step
class RouteStep {
  final String instruction;
  final double distanceMeters;
  final double durationSeconds;

  RouteStep({
    required this.instruction,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}

/// Represents a route with air quality and health metrics.
class VayuRoute {
  final List<LatLng> polyline;
  final double distanceKm;
  final Duration duration;
  final List<AqiPoint> samples;
  final String summary;
  final List<RouteStep> navigationSteps;

  VayuRoute({
    required this.polyline,
    required this.distanceKm,
    required this.duration,
    required this.samples,
    required this.summary,
    this.navigationSteps = const [],
  });

  /// The average AQI along the route.
  double get averageAqi {
    if (samples.isEmpty) return 0.0;
    return samples.map((s) => s.aqi).reduce((a, b) => a + b) / samples.length;
  }

  /// Total health impact score.
  /// Score = Σ (AQI * segment_distance)
  double get totalExposure {
    if (samples.isEmpty) return 0.0;
    // For simplicity with point sampling: averageAqi * distance
    return averageAqi * distanceKm;
  }

  /// Categorical health assessment.
  String get healthAssessment {
    final aqi = averageAqi;
    if (aqi <= 50) return 'Clean Air Corridor';
    if (aqi <= 100) return 'Moderate Exposure';
    return 'High Pollution Risk';
  }
}

/// A point along a route with associated AQI data.
class AqiPoint {
  final LatLng location;
  final int aqi;
  final DateTime timestamp;

  AqiPoint({
    required this.location,
    required this.aqi,
    required this.timestamp,
  });
}
