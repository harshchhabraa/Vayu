import 'package:equatable/equatable.dart';

/// Represents a single AQI reading from a monitoring station or grid point.
class AqiReading extends Equatable {
  const AqiReading({
    required this.aqi,
    required this.dominantPollutant,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.stationName,
    this.pm25,
    this.pm10,
    this.o3,
    this.no2,
    this.so2,
    this.co,
    this.source = AqiSource.waqi,
  });

  /// Overall AQI value (0–500 scale)
  final int aqi;

  /// The dominant pollutant driving the AQI value
  final String dominantPollutant;

  /// When this reading was recorded
  final DateTime timestamp;

  /// Station/grid latitude
  final double latitude;

  /// Station/grid longitude
  final double longitude;

  /// Name of the monitoring station (if from WAQI)
  final String? stationName;

  // Individual pollutant concentrations (µg/m³)
  final double? pm25;
  final double? pm10;
  final double? o3;
  final double? no2;
  final double? so2;
  final double? co;

  /// Data source
  final AqiSource source;

  /// Returns a human-readable category for the AQI value
  AqiCategory get category {
    if (aqi <= 50) return AqiCategory.good;
    if (aqi <= 100) return AqiCategory.moderate;
    if (aqi <= 150) return AqiCategory.unhealthySensitive;
    if (aqi <= 200) return AqiCategory.unhealthy;
    if (aqi <= 300) return AqiCategory.veryUnhealthy;
    return AqiCategory.hazardous;
  }

  /// Whether this reading is still considered fresh
  bool get isFresh =>
      DateTime.now().difference(timestamp).inMinutes < 10;

  /// Whether this reading is stale but still usable
  bool get isStale =>
      DateTime.now().difference(timestamp).inHours < 2;

  @override
  List<Object?> get props => [
        aqi, dominantPollutant, timestamp, latitude, longitude,
        stationName, pm25, pm10, o3, no2, so2, co, source,
      ];
}

enum AqiCategory {
  good,
  moderate,
  unhealthySensitive,
  unhealthy,
  veryUnhealthy,
  hazardous;

  String get label {
    switch (this) {
      case AqiCategory.good:
        return 'Good';
      case AqiCategory.moderate:
        return 'Moderate';
      case AqiCategory.unhealthySensitive:
        return 'Unhealthy for Sensitive Groups';
      case AqiCategory.unhealthy:
        return 'Unhealthy';
      case AqiCategory.veryUnhealthy:
        return 'Very Unhealthy';
      case AqiCategory.hazardous:
        return 'Hazardous';
    }
  }

  int get colorValue {
    switch (this) {
      case AqiCategory.good:
        return 0xFF4CAF50;
      case AqiCategory.moderate:
        return 0xFFFFEB3B;
      case AqiCategory.unhealthySensitive:
        return 0xFFFF9800;
      case AqiCategory.unhealthy:
        return 0xFFF44336;
      case AqiCategory.veryUnhealthy:
        return 0xFF9C27B0;
      case AqiCategory.hazardous:
        return 0xFF7B1FA2;
    }
  }
}

enum AqiSource {
  waqi,
  googleAirQuality,
  cache,
}
