import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vayu/domain/models/health_profile.dart';
import 'package:vayu/domain/models/exposure_snapshot.dart';
import 'package:vayu/domain/models/coach_message.dart';
import 'package:vayu/domain/engines/coach_engine.dart';
import 'package:vayu/providers/exposure/exposure_provider.dart';

final coachEngineProvider = Provider((ref) => CoachEngine());

/// Stores the latest user message to provide context for the recovery plan.
final latestUserMessageProvider = StateProvider<String?>((ref) => null);

/// State notifier for the coach's chat interactions.
class CoachChatNotifier extends Notifier<List<CoachMessage>> {
  @override
  List<CoachMessage> build() {
    return [
      const CoachMessage(
        text: "I've analyzed your exposure for today. How are you feeling physically right now?",
        isFromCoach: true,
      ),
    ];
  }

  void sendMessage(String text) async {
    // 1. Update context provider
    ref.read(latestUserMessageProvider.notifier).state = text;

    // 2. Add user message
    state = [...state, CoachMessage(text: text, isFromCoach: false)];
    
    // 3. Add temporary "Typing..." message
    final typingMessage = const CoachMessage(text: "Vayu is checking medical-grade protocols...", isFromCoach: true);
    state = [...state, typingMessage];
    
    // 4. Generate response with history context
    final summary = ref.read(dailyExposureProvider);
    final response = ref.read(coachEngineProvider).generateResponse(
      text, 
      summary, 
      state // Pass the history
    );
    
    await Future.delayed(Duration(milliseconds: 600 + (text.length * 8))); 
    
    // 5. Replace typing message with real response
    state = [
      ...state.where((m) => m != typingMessage),
      CoachMessage(text: response, isFromCoach: true)
    ];
  }
}

final coachChatProvider = NotifierProvider<CoachChatNotifier, List<CoachMessage>>(() {
  return CoachChatNotifier();
});

/// Provides the current active recovery plan, now listening to chat context.
final recoveryPlanProvider = Provider((ref) {
  final summary = ref.watch(dailyExposureProvider);
  final engine = ref.watch(coachEngineProvider);
  final latestMsg = ref.watch(latestUserMessageProvider);
  final profile = ref.watch(healthProfileProvider).valueOrNull ?? 
                  const HealthProfile(age: 25, isPregnant: false, conditions: []);
                  
  return engine.generateRecoveryPlan(
    summary: summary, 
    profile: profile, 
    latestUserMessage: latestMsg
  );
});
