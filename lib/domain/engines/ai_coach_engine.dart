import 'package:vayu/domain/models/recovery_plan.dart';
import 'package:vayu/domain/models/exposure_entry.dart';
import 'package:vayu/domain/models/health_profile.dart';
import 'package:vayu/domain/models/forecast_point.dart';
import 'package:uuid/uuid.dart';

class AICoachEngine {
  /// Generates a local fallback recovery plan if the Vertex AI backend fails.
  RecoveryPlan generateFallbackPlan({
    required HealthProfile profile,
    required ExposureSummary recentSummary,
    required List<ForecastPoint> forecast,
  }) {
    final bool isHighlySensitive = profile.sensitivityFactor >= 1.4;
    final List<RecoveryActivity> activities = [];
    
    activities.add(const RecoveryActivity(
      title: 'Deep Hydration',
      description: 'Drink 2 liters of water. Hydration helps your body process toxins from pollution faster.',
      durationMinutes: 5,
      category: ActivityCategory.hydration,
      priority: 1,
    ));

    if (recentSummary.peakAqi > 150 || isHighlySensitive) {
      activities.add(const RecoveryActivity(
        title: 'Run Air Purifier',
        description: 'Ensure doors and windows are closed. Run the air purifier on high for at least 2 hours.',
        durationMinutes: 120,
        category: ActivityCategory.airPurification,
        priority: 1,
      ));
    }

    activities.add(const RecoveryActivity(
      title: 'Avoid Outdoor Exertion',
      description: 'Substitute any outdoor running or cycling with an indoor workout.',
      durationMinutes: 30,
      category: ActivityCategory.indoorExercise,
      priority: 2,
    ));

    return RecoveryPlan(
      id: const Uuid().v4(),
      generatedAt: DateTime.now(),
      triggerExposureScore: recentSummary.totalScore,
      activities: activities,
      summary: 'Your exposure levels are elevated today. Focus on minimizing outdoor time and prioritizing indoor recovery routines.',
      longTermRecommendations: [
        'Consider rescheduling outdoor activities to early morning or late evening.',
        'Ensure your indoor air circulation uses HEPA filtration.'
      ],
      expiresAt: DateTime.now().add(const Duration(days: 1)),
    );
  }

  String formatCoachMessage(RecoveryPlan plan) {
    if (plan.triggerExposureScore > 200) {
      return "⚠️ High exposure alert! I've created an emergency recovery plan for you. Priority: ${plan.activities.first.title}.";
    }
    return "Your personalized recovery plan is ready to help offset today's pollution exposure.";
  }
}
