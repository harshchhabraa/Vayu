import 'package:vayu/domain/models/forecast_point.dart';

class PredictionEngine {
  ForecastConfidence assessConfidence(List<ForecastPoint> forecast) {
    if (forecast.isEmpty) return ForecastConfidence.low;

    // Calculate average gap between upper and lower bound
    double totalGap = 0;
    for (final point in forecast) {
      totalGap += point.confidenceWidth;
    }
    final avgGap = totalGap / forecast.length;

    // Simple heuristic
    if (avgGap < 20) return ForecastConfidence.high;
    if (avgGap < 50) return ForecastConfidence.medium;
    return ForecastConfidence.low;
  }

  List<OptimalWindow> findLowExposureWindows(
    List<ForecastPoint> forecast,
    Duration activityDuration,
  ) {
    if (forecast.isEmpty) return [];

    final List<OptimalWindow> windows = [];
    final int neededPoints = max(1, activityDuration.inHours);
    
    // Simple sliding window
    for (int i = 0; i <= forecast.length - neededPoints; i++) {
      double windowSum = 0;
      for (int j = 0; j < neededPoints; j++) {
        windowSum += forecast[i + j].predictedAqi;
      }
      
      final double avg = windowSum / neededPoints;
      final start = forecast[i].timestamp;
      final end = forecast[i + neededPoints - 1].timestamp.add(const Duration(hours: 1)); // End of last hour
      
      windows.add(OptimalWindow(start: start, end: end, avgPredictedAqi: avg));
    }

    // Sort by best AQI
    windows.sort((a, b) => a.avgPredictedAqi.compareTo(b.avgPredictedAqi));
    
    return windows;
  }
  
  int max(int a, int b) => a > b ? a : b;
}
