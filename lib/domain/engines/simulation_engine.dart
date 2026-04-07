import 'package:vayu/domain/models/simulation_scenario.dart';
import 'package:vayu/domain/models/exposure_entry.dart';
import 'package:vayu/domain/models/exposure_snapshot.dart';
import 'package:vayu/domain/models/forecast_point.dart';
import 'package:vayu/domain/models/health_profile.dart';
import 'package:vayu/domain/engines/exposure_engine.dart';

class HealthProtocol {
  final String title;
  final String description;
  final String action;
  final List<String> items;
  final String category; // 'Hardware' or 'Dietary'

  HealthProtocol({
    required this.title, 
    required this.description, 
    required this.action, 
    required this.items,
    this.category = 'Hardware',
  });
}

enum HazardLevel { optimal, unhealthy, critical }

class HourNarrative {
  final int hour;
  final String time;
  final String headline;
  final String impact;
  final bool isRisk;
  final double aqiValue;
  final HazardLevel hazardLevel;
  final String status;

  HourNarrative({
    required this.hour,
    required this.time,
    required this.headline,
    required this.impact,
    required this.aqiValue,
    required this.hazardLevel,
    required this.status,
    this.isRisk = false,
  });
}

class SimulationSeriesResult {
  final List<double> baselinePoints;
  final List<double> projectedPoints;
  final double deltaPercent;
  final List<String> insights;
  final List<HealthProtocol> protocols;
  final List<double> lungStressIndex; 
  final List<HourNarrative> narratives;

  SimulationSeriesResult({
    required this.baselinePoints,
    required this.projectedPoints,
    required this.deltaPercent,
    required this.insights,
    required this.protocols,
    required this.lungStressIndex,
    required this.narratives,
  });
}

class SimulationEngine {
  final ExposureEngine _exposureEngine;

  SimulationEngine(this._exposureEngine);

  SimulationSeriesResult simulateSeries({
    required SimulationScenario scenario,
    required ExposureSummary baseline,
    required List<ForecastPoint> todaysForecast,
    required HealthProfile profile,
  }) {
    if (todaysForecast.isEmpty) {
      return SimulationSeriesResult(
        baselinePoints: [],
        projectedPoints: [],
        deltaPercent: 0,
        insights: const ['Forecast data unavailable.'],
        protocols: [],
        lungStressIndex: [],
        narratives: [],
      );
    }

    final List<double> baselinePoints = [];
    final List<double> projectedPoints = [];
    final List<double> lungStressPoints = [];
    final List<HourNarrative> narratives = [];
    
    double totalBaseline = 0;
    double totalProjected = 0;
    double currentStress = 0;
    int hourCount = 1;

    for (final point in todaysForecast) {
      final double aqi = point.predictedAqi;
      final timeStr = '${point.timestamp.hour}:${point.timestamp.minute.toString().padLeft(2, '0')}';
      
      // Calculate Baseline
      final bScore = _exposureEngine.calculateInstantExposure(
        aqi: aqi * 0.3,
        interval: const Duration(hours: 1),
        activity: ActivityMode.indoor,
        profile: profile,
      );
      totalBaseline += bScore;
      baselinePoints.add(totalBaseline);

      // Scenario Logic
      double sAqi = aqi;
      EnvironmentType env = EnvironmentType.indoor;
      if ((scenario.outdoorHoursOverride ?? 0) > 0) env = EnvironmentType.outdoor;
      if (scenario.commuteModeOverride != null) env = EnvironmentType.transit;

      if (env == EnvironmentType.indoor) {
        sAqi *= (scenario.indoorAirQualityFactor ?? 0.3);
      } else if (env == EnvironmentType.outdoor && scenario.maskUsage) {
        sAqi *= scenario.maskFactor;
      }

      final sScore = _exposureEngine.calculateInstantExposure(
        aqi: sAqi,
        interval: const Duration(hours: 1),
        activity: env == EnvironmentType.outdoor ? ActivityMode.walking : ActivityMode.indoor,
        profile: profile,
      );

      // Deterioration
      double stressFactor = (sScore / (profile.sensitivityFactor * 1.5)) * 12;
      if (aqi > 150) stressFactor *= 1.4; 
      
      currentStress += stressFactor;
      lungStressPoints.add(currentStress.clamp(0.0, 100.0));

      totalProjected += sScore;
      projectedPoints.add(totalProjected);

      // HOUR NARRATIVE GENERATION
      narratives.add(_generateHourNarrative(hourCount++, timeStr, aqi, sScore, env, profile));
    }

    double delta = 0;
    if (totalBaseline > 0) {
      delta = ((totalProjected - totalBaseline) / totalBaseline) * 100;
    }

    return SimulationSeriesResult(
      baselinePoints: baselinePoints,
      projectedPoints: projectedPoints,
      deltaPercent: delta,
      insights: [
        delta < -20 
          ? 'Protective shielding successful. Your long-term vitality profile is preserved.'
          : 'Hazardous behavior detected. Inflammatory markers will likely elevate within 24 hours.'
      ],
      protocols: _generateProtocols(todaysForecast, delta),
      lungStressIndex: lungStressPoints,
      narratives: narratives,
    );
  }

  HourNarrative _generateHourNarrative(int hour, String time, double aqi, double sScore, EnvironmentType env, HealthProfile profile) {
    String headline;
    String impact;
    HazardLevel hazard;
    String status;
    bool isRisk = false;

    if (aqi > 150) {
      headline = 'CRITICAL SPIKE';
      status = 'HAZARDOUS';
      impact = 'N95 shielding mandatory.';
      hazard = HazardLevel.critical;
      isRisk = true;
    } else if (aqi > 100) {
      headline = 'UNHEALTHY ZONE';
      status = 'UNHEALTHY';
      impact = 'PM2.5 exceeding safety threshold.';
      hazard = HazardLevel.unhealthy;
      isRisk = true;
    } else if (env == EnvironmentType.outdoor) {
      headline = 'ACTIVE OUTDOOR';
      status = 'EXPOSED';
      impact = 'Ambient air quality moderate.';
      hazard = HazardLevel.unhealthy;
    } else {
      headline = 'STABLE SHIELD';
      status = 'OPTIMIZED';
      impact = 'Filtered environment is success.';
      hazard = HazardLevel.optimal;
    }

    return HourNarrative(
      hour: hour,
      time: time,
      headline: headline,
      impact: impact,
      aqiValue: aqi,
      hazardLevel: hazard,
      status: status,
      isRisk: isRisk,
    );
  }

  List<HealthProtocol> _generateProtocols(List<ForecastPoint> forecast, double delta) {
    final maxAqi = forecast.map((e) => e.predictedAqi).reduce((a, b) => a > b ? a : b);
    final List<HealthProtocol> list = [];

    list.add(HealthProtocol(
      category: 'Hardware',
      title: 'AIR FILTRATION PROTOCOL',
      description: maxAqi > 100 
          ? 'N95 Respirator required for ${maxAqi.toInt()} AQI peak.'
          : 'High CADR Air Purifier setting recommended.',
      action: maxAqi > 100 ? 'Deploy N95/N99 Mask' : 'HEPA Level: High',
      items: maxAqi > 100 ? ['N95 Mask', 'HEPA Purifier'] : ['Surgical Mask', 'Ionizer (Eco Mode)'],
    ));

    list.add(HealthProtocol(
      category: 'Dietary',
      title: 'MOLECULAR RECOVERY DIET',
      description: 'Combat cellular inflammation triggered by PM2.5.',
      action: 'Target Inflammation',
      items: ['Vitamin C (1000mg)', 'Curcumin/Turmeric', 'Omega-3', 'Sulforaphane (Broccoli)'],
    ));

    return list;
  }
}
