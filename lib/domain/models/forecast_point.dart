import 'package:equatable/equatable.dart';

/// A single point in an AQI forecast.
class ForecastPoint extends Equatable {
  const ForecastPoint({
    required this.timestamp,
    required this.predictedAqi,
    required this.lowerBound,
    required this.upperBound,
    this.dominantPollutant,
  });

  final DateTime timestamp;
  final double predictedAqi;

  /// 80% confidence interval
  final double lowerBound;
  final double upperBound;

  final String? dominantPollutant;

  double get confidenceWidth => upperBound - lowerBound;

  @override
  List<Object?> get props => [timestamp, predictedAqi, lowerBound, upperBound];
}

/// A recommended time window for outdoor activity.
class OptimalWindow extends Equatable {
  const OptimalWindow({
    required this.start,
    required this.end,
    required this.avgPredictedAqi,
  });

  final DateTime start;
  final DateTime end;
  final double avgPredictedAqi;

  Duration get duration => end.difference(start);

  @override
  List<Object?> get props => [start, end, avgPredictedAqi];
}

/// Confidence level for a forecast series.
enum ForecastConfidence {
  high(label: 'High Confidence', maxHoursAhead: 24),
  medium(label: 'Medium Confidence', maxHoursAhead: 48),
  low(label: 'Low Confidence', maxHoursAhead: 96);

  const ForecastConfidence({required this.label, required this.maxHoursAhead});
  final String label;
  final int maxHoursAhead;
}
