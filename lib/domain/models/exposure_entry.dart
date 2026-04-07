import 'package:equatable/equatable.dart';
import 'package:vayu/domain/models/exposure_snapshot.dart';
import 'package:vayu/domain/models/health_profile.dart';

/// A single exposure measurement interval.
class ExposureEntry extends Equatable {
  const ExposureEntry({
    required this.timestamp,
    required this.durationSeconds,
    required this.aqi,
    required this.latitude,
    required this.longitude,
    required this.activity,
    required this.protectionFactor,
    required this.vulnerabilityFactor,
    required this.visionFactor,
    required this.score,
  });

  /// When this interval started
  final DateTime timestamp;

  final int durationSeconds;

  final int aqi;

  final double latitude;
  final double longitude;

  /// New factors for the senior-grade formula
  final ActivityMode activity;
  final double protectionFactor;
  final double vulnerabilityFactor;
  final double visionFactor;

  /// Calculated exposure score for this interval
  /// Formula: AQI × (duration_hours) × activity × vulnerability × protection × vision_factor
  final double score;

  @override
  List<Object?> get props => [
        timestamp, durationSeconds, aqi, latitude, longitude,
        activity, protectionFactor, vulnerabilityFactor, visionFactor, score,
      ];
}

/// Daily exposure summary, aggregated from individual intervals.
class ExposureSummary extends Equatable {
  const ExposureSummary({
    required this.date,
    required this.totalScore,
    required this.totalOutdoorMinutes,
    required this.totalIndoorMinutes,
    required this.totalTransitMinutes,
    required this.avgAqi,
    required this.peakAqi,
    required this.entryCount,
    this.entries = const [],
  });

  final DateTime date;
  final double totalScore;
  final int totalOutdoorMinutes;
  final int totalIndoorMinutes;
  final int totalTransitMinutes;
  final double avgAqi;
  final int peakAqi;
  final int entryCount;
  final List<ExposureEntry> entries;

  ExposureRiskLevel get riskLevel {
    if (totalScore <= 50) return ExposureRiskLevel.good;
    if (totalScore <= 100) return ExposureRiskLevel.moderate;
    if (totalScore <= 200) return ExposureRiskLevel.unhealthy;
    if (totalScore <= 300) return ExposureRiskLevel.veryUnhealthy;
    return ExposureRiskLevel.hazardous;
  }

  @override
  List<Object?> get props => [
        date, totalScore, totalOutdoorMinutes, totalIndoorMinutes,
        totalTransitMinutes, avgAqi, peakAqi, entryCount, entries,
      ];
}

/// Trend analysis over multiple days.
class ExposureTrend extends Equatable {
  const ExposureTrend({
    required this.periodDays,
    required this.averageDailyScore,
    required this.direction,
    required this.percentChange,
    required this.summaries,
  });

  final int periodDays;
  final double averageDailyScore;
  final TrendDirection direction;
  final double percentChange;
  final List<ExposureSummary> summaries;

  @override
  List<Object?> get props => [
        periodDays, averageDailyScore, direction, percentChange,
      ];
}

enum EnvironmentType {
  indoor(factor: 0.3, label: 'Indoor'),
  outdoor(factor: 1.0, label: 'Outdoor'),
  transit(factor: 0.6, label: 'Transit'),
  vehicle(factor: 0.5, label: 'In Vehicle');

  const EnvironmentType({required this.factor, required this.label});
  final double factor;
  final String label;
}

enum ExposureRiskLevel {
  good(label: 'Good', colorValue: 0xFF4CAF50),
  moderate(label: 'Moderate', colorValue: 0xFFFFEB3B),
  unhealthy(label: 'Unhealthy', colorValue: 0xFFFF9800),
  veryUnhealthy(label: 'Very Unhealthy', colorValue: 0xFFF44336),
  hazardous(label: 'Hazardous', colorValue: 0xFF9C27B0);

  const ExposureRiskLevel({required this.label, required this.colorValue});
  final String label;
  final int colorValue;
}

enum TrendDirection { improving, stable, worsening }
