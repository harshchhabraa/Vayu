import 'package:equatable/equatable.dart';

/// A route scored by air quality exposure.
class ScoredRoute extends Equatable {
  const ScoredRoute({
    required this.routeIndex,
    required this.encodedPolyline,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.avgAqi,
    required this.exposureScore,
    required this.overallScore,
    required this.aqiSamples,
    this.summary,
    this.exposurePercentage = 0.0,
    this.greeneryLevel = 0.0,
    this.trafficLevel = 0.0,
    this.steps = const [],
    this.mode,
  });

  final int routeIndex;
  final String encodedPolyline;
  final int distanceMeters;
  final int durationSeconds;
  final double avgAqi;
  final double exposureScore;
  final double overallScore;
  final List<RouteAqiSample> aqiSamples;
  final String? summary;
  final TravelMode? mode;
  
  /// Percentage better/worse than the standard route
  final double exposurePercentage;
  final double greeneryLevel; // 0.0 - 1.0
  final double trafficLevel;  // 0.0 - 1.0
  final List<RouteStep> steps;

  String get formattedDistance {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '$distanceMeters m';
  }

  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}m';
    }
    return '$minutes min';
  }

  String get formattedPercentage {
    if (exposurePercentage == 0) return 'Standard';
    final sign = exposurePercentage < 0 ? '-' : '+';
    return '$sign${exposurePercentage.abs().toStringAsFixed(0)}%';
  }

  @override
  List<Object?> get props => [
        routeIndex, encodedPolyline, distanceMeters,
        durationSeconds, exposureScore, overallScore,
        exposurePercentage, greeneryLevel, trafficLevel,
        mode,
      ];

  ScoredRoute copyWith({
    int? routeIndex,
    String? encodedPolyline,
    int? distanceMeters,
    int? durationSeconds,
    double? avgAqi,
    double? exposureScore,
    double? overallScore,
    List<RouteAqiSample>? aqiSamples,
    String? summary,
    double? exposurePercentage,
    double? greeneryLevel,
    double? trafficLevel,
    List<RouteStep>? steps,
    TravelMode? mode,
  }) {
    return ScoredRoute(
      routeIndex: routeIndex ?? this.routeIndex,
      encodedPolyline: encodedPolyline ?? this.encodedPolyline,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      avgAqi: avgAqi ?? this.avgAqi,
      exposureScore: exposureScore ?? this.exposureScore,
      overallScore: overallScore ?? this.overallScore,
      aqiSamples: aqiSamples ?? this.aqiSamples,
      summary: summary ?? this.summary,
      exposurePercentage: exposurePercentage ?? this.exposurePercentage,
      greeneryLevel: greeneryLevel ?? this.greeneryLevel,
      trafficLevel: trafficLevel ?? this.trafficLevel,
      steps: steps ?? this.steps,
      mode: mode ?? this.mode,
    );
  }
}

/// A single step in a route (e.g., "Turn left onto Greenway Dr")
class RouteStep extends Equatable {
  const RouteStep({
    required this.instruction,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.latitude,
    required this.longitude,
  });

  final String instruction;
  final int distanceMeters;
  final int durationSeconds;
  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [instruction, distanceMeters, durationSeconds, latitude, longitude];
}

/// AQI sample at a specific point along a route.
class RouteAqiSample extends Equatable {
  const RouteAqiSample({
    required this.latitude,
    required this.longitude,
    required this.aqi,
    required this.distanceAlongRoute,
  });

  final double latitude;
  final double longitude;
  final int aqi;
  final double distanceAlongRoute; // meters from route start

  @override
  List<Object?> get props => [latitude, longitude, aqi, distanceAlongRoute];
}

/// Travel mode for route calculation
enum TravelMode {
  drive,
  walk,
  bicycle,
  transit,
}
