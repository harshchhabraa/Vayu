import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vayu/providers/coach/coach_provider.dart';
import 'package:vayu/domain/models/coach_message.dart';
import 'package:vayu/presentation/widgets/vayu_background.dart';
import 'package:vayu/presentation/widgets/vayu_card.dart';
import 'package:vayu/presentation/widgets/vayu_text_field.dart';

class AiCoachScreen extends ConsumerStatefulWidget {
  const AiCoachScreen({super.key});

  @override
  ConsumerState<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends ConsumerState<AiCoachScreen> {
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();

  void _onSend() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    
    ref.read(coachChatProvider.notifier).sendMessage(text);
    _chatController.clear();
    
    // Auto scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(coachChatProvider);
    final recoveryPlan = ref.watch(recoveryPlanProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('AI Health Coach', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: VayuBackground(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Personal Recovery',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tailored insights based on today\'s exposure.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 32),

                    // Dynamic Recommendations
                    ...recoveryPlan.map((rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: VayuCard(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE8F5E9)),
                              child: Text(rec.icon, style: const TextStyle(fontSize: 20)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(rec.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF00695C))),
                                  const SizedBox(height: 4),
                                  Text(rec.description, style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.4)),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    )).toList(),

                    const SizedBox(height: 32),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 24),

                    // Chat History
                    ...messages.map((m) => _buildChatMessage(m)).toList(),
                  ],
                ),
              ),
            ),

            // Glassmorphic Chat Input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                border: const Border(top: BorderSide(color: Colors.white10)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: VayuTextField(
                        controller: _chatController,
                        hintText: 'Ask Vayu Health...',
                        prefixIcon: Icons.chat_bubble_outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _onSend,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: const BoxDecoration(color: Color(0xFF009688), shape: BoxShape.circle),
                        child: const Icon(Icons.send, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildChatMessage(CoachMessage message) {
    return Align(
      alignment: message.isFromCoach ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: message.isFromCoach ? Colors.white.withOpacity(0.15) : const Color(0xFF009688).withOpacity(0.8),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(message.isFromCoach ? 4 : 20),
            bottomRight: Radius.circular(message.isFromCoach ? 20 : 4),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(color: message.isFromCoach ? Colors.white : Colors.white, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
