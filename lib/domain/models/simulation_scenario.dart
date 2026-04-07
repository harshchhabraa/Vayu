import 'package:equatable/equatable.dart';

/// Defines a "what-if" simulation scenario.
class SimulationScenario extends Equatable {
  const SimulationScenario({
    this.outdoorHoursOverride,
    this.commuteModeOverride,
    this.maskUsage = false,
    this.indoorAirQualityFactor,
    this.timeOfDayShift,
  });

  /// Override daily outdoor hours (default from actual data)
  final double? outdoorHoursOverride;

  /// Override commute mode
  final String? commuteModeOverride;

  /// Whether user wears a mask outdoors (reduces exposure by ~60%)
  final bool maskUsage;

  /// Indoor air quality improvement factor (0.1 = great filter, 0.5 = poor)
  final double? indoorAirQualityFactor;

  /// Shift outdoor activity time by N hours (e.g., -2 = 2 hours earlier)
  final int? timeOfDayShift;

  /// Mask reduces inhaled pollutants by ~60%
  double get maskFactor => maskUsage ? 0.4 : 1.0;

  @override
  List<Object?> get props => [
        outdoorHoursOverride, commuteModeOverride,
        maskUsage, indoorAirQualityFactor, timeOfDayShift,
      ];
}

/// Result of running a simulation.
class SimulationResult extends Equatable {
  const SimulationResult({
    required this.baselineScore,
    required this.projectedScore,
    required this.deltaPercent,
    required this.insights,
  });

  final double baselineScore;
  final double projectedScore;
  final double deltaPercent;
  final List<String> insights;

  bool get isImprovement => projectedScore < baselineScore;

  @override
  List<Object?> get props => [baselineScore, projectedScore, deltaPercent];
}
