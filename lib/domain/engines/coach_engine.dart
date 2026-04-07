import 'package:vayu/domain/models/exposure_entry.dart';
import 'package:vayu/domain/models/health_profile.dart';
import 'package:vayu/domain/models/coach_message.dart';
import 'dart:math';

/// A recommendation from the AI Coach.
class CoachRecommendation {
  const CoachRecommendation({
    required this.title,
    required this.description,
    required this.icon,
    required this.priority,
    required this.tags,
  });

  final String title;
  final String description;
  final String icon;
  final int priority; 
  final Set<String> tags;
}

class CoachEngine {
  final Random _random = Random();

  /// A massive library of high-fidelity health recommendations.
  static const List<CoachRecommendation> _library = [
    // 1. Environmental Control
    CoachRecommendation(
      title: 'HEPA Turbo Flush',
      description: 'Run your indoor air purifier on the highest setting for 90 minutes to clear PM2.5 residue.',
      icon: '🌪️',
      priority: 5,
      tags: {'high_aqi', 'indoor', 'peak_spike'},
    ),
    CoachRecommendation(
      title: 'Seal Transitions',
      description: 'Check window seals and door sweeps. Small gaps can allow particulate matter to bypass filters.',
      icon: '🚪',
      priority: 2,
      tags: {'high_aqi', 'indoor'},
    ),

    // 2. Symptoms (Granular Advice & Follow-ups)
    CoachRecommendation(
      title: 'Throat Soother',
      description: 'Gargle with warm salt water. Particulates often lodge in the oropharynx, causing that scratchy feeling.',
      icon: '🍯',
      priority: 5,
      tags: {'symptom', 'throat'},
    ),
    CoachRecommendation(
      title: 'Dark Room Recovery',
      description: 'Headaches from NO2/CO can be severe. Dim all lights, stay hydrated with electrolytes, and rest with eyes closed.',
      icon: '🌑',
      priority: 5,
      tags: {'symptom', 'headache', 'indoor', 'night'},
    ),
    CoachRecommendation(
      title: 'Peppermint Oil',
      description: 'Applying peppermint oil to the temples can help relieve tension headaches caused by inflammatory air quality.',
      icon: '🌿',
      priority: 3,
      tags: {'symptom', 'headache', 'recovery'},
    ),
    CoachRecommendation(
      title: 'Oxygen Prioritization',
      description: 'Shortness of breath detected. Sit upright, perform pursed-lip breathing, and avoid all physical exertion.',
      icon: '🫁',
      priority: 5,
      tags: {'symptom', 'breath', 'high_aqi'},
    ),

    // 3. Activity & Environment
    CoachRecommendation(
      title: 'Low-Impact Pivot',
      description: 'Swap your outdoor run for restorative yoga or indoor bodyweight training while AQI settles.',
      icon: '🧘',
      priority: 5,
      tags: {'high_aqi', 'active', 'outdoor_risk'},
    ),
    CoachRecommendation(
      title: 'Cross-Ventilation',
      description: 'If you can safely open windows, create a cross-breeze to flush out stale indoor pollutants (CO2/VOCs).',
      icon: '🪟',
      priority: 3,
      tags: {'indoor', 'good_aqi'},
    ),

    // ... More items as previously defined
    CoachRecommendation(
      title: 'Vitamin C Boost',
      description: 'Consume 2g of Vitamin C to help neutralize oxidative stress from ozone.',
      icon: '🍊',
      priority: 4,
      tags: {'high_aqi', 'chemical', 'recovery', 'throat'},
    ),
  ];

  /// Generates a set of health recommendations based on current context.
  List<CoachRecommendation> generateRecoveryPlan({
    required ExposureSummary summary,
    required HealthProfile profile,
    String? latestUserMessage,
  }) {
    final Set<String> activeTags = {};
    if (summary.peakAqi > 100) activeTags.add('high_aqi');
    if (summary.peakAqi > 150) activeTags.add('peak_spike');
    if (summary.avgAqi < 50) activeTags.add('good_aqi');
    if (summary.totalOutdoorMinutes > 30) activeTags.add('outdoor_risk');
    if (summary.totalScore > 50) activeTags.add('recovery');
    if (profile.isPregnant) activeTags.add('pregnancy');
    if (profile.conditions.contains('asthma')) activeTags.add('asthma');

    if (latestUserMessage != null) {
      final msg = latestUserMessage.toLowerCase();
      if (msg.contains('throat') || msg.contains('cough')) activeTags.add('throat');
      if (msg.contains('breath') || msg.contains('chest')) activeTags.add('breath');
      if (msg.contains('eye')) activeTags.add('eyes');
      if (msg.contains('head')) activeTags.add('headache');
      if (msg.contains('night') || msg.contains('late')) activeTags.add('night');
    }

    final scoredList = _library.where((rec) {
      return rec.tags.intersection(activeTags).isNotEmpty;
    }).toList();

    scoredList.sort((a, b) {
      final aSymp = a.tags.contains('symptom') ? 10 : 0;
      final bSymp = b.tags.contains('symptom') ? 10 : 0;
      final bNight = b.tags.contains('night') ? 5 : 0;
      final aNight = a.tags.contains('night') ? 5 : 0;
      final scoreA = a.priority + aSymp + aNight + _random.nextInt(3);
      final scoreB = b.priority + bSymp + bNight + _random.nextInt(3);
      return scoreB.compareTo(scoreA);
    });

    return scoredList.take(3).toList();
  }

  /// Assembles a response based on current query and historical context.
  String generateResponse(String query, ExposureSummary summary, List<CoachMessage> history) {
    final msg = query.toLowerCase();

    // 1. Detect Active Topic from History
    String? activeTopic;
    for (var m in history.reversed) {
      if (!m.isFromCoach) {
        final t = m.text.toLowerCase();
        if (t.contains('head')) { activeTopic = 'headache'; break; }
        if (t.contains('throat')) { activeTopic = 'throat'; break; }
        if (t.contains('breath')) { activeTopic = 'breath'; break; }
      }
    }

    // 2. Handle constraints (Home, Night, Can't move)
    final isStuckIndoors = msg.contains('home') || msg.contains('inside') || msg.contains('cannot') || msg.contains('can\'t');
    final isNight = msg.contains('night') || msg.contains('late') || msg.contains('dark');

    // 3. Intent Logic with Conversational Memory
    if (activeTopic == 'headache' && (isStuckIndoors || isNight)) {
      return "I understand you're stuck at home right now. For that headache, skip the park. Dim your lights immediately, drink electrolyte-rich water, and focus on slow, deep nasal breathing. I've updated your recovery plan above with a 'Dark Room' protocol.";
    }

    if (msg.contains('throat') || msg.contains('scratchy') || msg.contains('cough')) {
      return "I hear you. That throat irritation is likely due to the ozone/particle spike I'm seeing in your data. Warm saline gargles and antioxidant-rich foods are your best path right now.";
    }

    if (msg.contains('breath') || msg.contains('chest') || msg.contains('tight')) {
      return "Shortness of breath is a serious marker. Stay indoors in a filtered zone, use your preventative inhaler if prescribed, and keep your body at rest.";
    }

    if (msg.contains('eye') || msg.contains('itch') || msg.contains('sting')) {
      return "Your data shows high particulate density. Irritated eyes are common; please use artificial tears and avoid all transition zones until the plume clears.";
    }

    if (msg.contains('head') || msg.contains('aches') || msg.contains('headache')) {
      return "Headaches can be triggered by sudden spikes in NO2 or CO. Open a cross-ventilation window if you are indoors, or move to a park with high foliage density.";
    }

    // Default template logic
    final String dataInsight = _buildDataInsight(summary);
    if (msg.contains('air') || msg.contains('aqi') || msg.contains('score')) {
      return "Health Coach Update: Today's peak AQI reached ${summary.peakAqi}. $dataInsight Focus on your recovery plan for now.";
    }

    if (msg.contains('ok') || msg.contains('thanks') || msg.contains('good')) {
       final options = ["Glad I could help. I'm still monitoring your trends.", "Monitoring continues. How does your breathing feel now?", "Taking it slow is the right move today."];
       return options[_random.nextInt(options.length)];
    }

    return "Coach Analysis: I'm tracking your environmental markers. $dataInsight Tell me more about any physical symptoms you're noticing.";
  }

  String _buildDataInsight(ExposureSummary summary) {
    if (summary.totalScore > 100) {
      return "Your cumulative exposure is high (${summary.totalScore.toStringAsFixed(1)} units). Respiratory recovery via hydration and filtration is recommended.";
    }
    if (summary.totalOutdoorMinutes > 45) {
      return "You had a significant outdoor session today. Even at moderate levels, your particle intake increases with duration.";
    }
    return "Your exposure profile is within a healthy baseline. Maintaining this consistency is great for long-term health.";
  }
}
