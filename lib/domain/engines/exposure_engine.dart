import 'package:vayu/domain/models/exposure_entry.dart';
import 'package:vayu/domain/models/exposure_snapshot.dart';
import 'package:vayu/domain/models/health_profile.dart';
import 'package:vayu/domain/engines/exposure_calculator.dart';

class ExposureEngine {
  /// Legacy wrapper for existing providers (refactoring in progress)
  double calculateInstantExposure({
    required double aqi,
    required Duration interval,
    required ActivityMode activity,
    required HealthProfile profile,
    double visionFactor = 1.0,
  }) {
    return ExposureCalculator.calculate(
      aqi: aqi, 
      interval: interval, 
      activity: activity, 
      profile: profile,
      visionFactor: visionFactor,
    );
  }
  
  /// Computes a daily summary from a list of entries for that day.
  ExposureSummary computeDailySummary(List<ExposureEntry> entries, DateTime date) {
    if (entries.isEmpty) {
      return ExposureSummary(
        date: date,
        totalScore: 0,
        totalOutdoorMinutes: 0,
        totalIndoorMinutes: 0,
        totalTransitMinutes: 0,
        avgAqi: 0,
        peakAqi: 0,
        entryCount: 0,
        entries: const [],
      );
    }

    double totalScore = 0;
    int outdoorSeconds = 0;
    int indoorSeconds = 0;
    int transitSeconds = 0;
    double sumAqi = 0;
    int peakAqi = 0;

    for (final entry in entries) {
      totalScore += entry.score;
      sumAqi += entry.aqi;
      
      if (entry.aqi > peakAqi) {
        peakAqi = entry.aqi;
      }

      switch (entry.activity) {
        case ActivityMode.walking:
        case ActivityMode.running:
          outdoorSeconds += entry.durationSeconds;
          break;
        case ActivityMode.indoor:
          indoorSeconds += entry.durationSeconds;
          break;
        case ActivityMode.driving:
          transitSeconds += entry.durationSeconds;
          break;
      }
    }

    return ExposureSummary(
      date: date,
      totalScore: totalScore,
      totalOutdoorMinutes: outdoorSeconds ~/ 60,
      totalIndoorMinutes: indoorSeconds ~/ 60,
      totalTransitMinutes: transitSeconds ~/ 60,
      avgAqi: sumAqi / entries.length,
      peakAqi: peakAqi,
      entryCount: entries.length,
      entries: List.from(entries),
    );
  }

  /// Analyzes the trend over the provided daily summaries.
  ExposureTrend analyzeTrend(List<ExposureSummary> dailySummaries) {
    if (dailySummaries.isEmpty) {
      return const ExposureTrend(
        periodDays: 0,
        averageDailyScore: 0,
        direction: TrendDirection.stable,
        percentChange: 0,
        summaries: [],
      );
    }
    
    // Ensure chronological order
    final sorted = List<ExposureSummary>.from(dailySummaries)
      ..sort((a, b) => a.date.compareTo(b.date));
      
    final int count = sorted.length;
    double totalScore = sorted.fold(0, (sum, item) => sum + item.totalScore);
    double avg = totalScore / count;
    
    TrendDirection direction = TrendDirection.stable;
    double percentChange = 0;
    
    if (count > 1) {
      // Split into two halves for trend
      final mid = count ~/ 2;
      final recent = sorted.sublist(mid);
      final older = sorted.sublist(0, mid);
      
      double recentAvg = recent.fold(0.0, (sum, item) => sum + item.totalScore) / recent.length;
      double olderAvg = older.fold(0.0, (sum, item) => sum + item.totalScore) / older.length;
      
      if (olderAvg > 0) {
        percentChange = ((recentAvg - olderAvg) / olderAvg) * 100;
        if (percentChange > 5) {
          direction = TrendDirection.worsening;
        } else if (percentChange < -5) {
          direction = TrendDirection.improving;
        }
      }
    }
    
    return ExposureTrend(
      periodDays: count,
      averageDailyScore: avg,
      direction: direction,
      percentChange: percentChange,
      summaries: sorted,
    );
  }
}
