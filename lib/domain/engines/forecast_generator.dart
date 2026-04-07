import 'dart:math';
import 'package:vayu/domain/models/forecast_point.dart';

class SyntheticForecastGenerator {
  final Random _random = Random();

  /// Generates a realistic 4-hour forecast based on a starting AQI.
  List<ForecastPoint> generate(double currentAqi) {
    final List<ForecastPoint> points = [];
    final now = DateTime.now();
    double runningAqi = currentAqi;

    for (int i = 0; i < 4; i++) {
      final hourOffset = i + 1;
      final time = now.add(Duration(hours: hourOffset));
      
      // Atmospheric Drift Logic:
      // AQI fluctuates by ±2-5% per hour.
      // Afternoons (12 PM - 4 PM) tend to peak higher due to heat/ozone.
      double drift = (0.5 - _random.nextDouble()) * (currentAqi * 0.08);
      
      // Hourly multiplier based on time of day (simulated traffic/atmospheric mixing)
      if (time.hour >= 8 && time.hour <= 10) drift += 5; // Morning rush
      if (time.hour >= 17 && time.hour <= 19) drift += 8; // Evening rush
      
      runningAqi = (runningAqi + drift).clamp(10, 400);

      points.add(ForecastPoint(
        timestamp: time,
        predictedAqi: runningAqi,
        lowerBound: runningAqi * 0.9,
        upperBound: runningAqi * 1.1,
      ));
    }

    return points;
  }
}
