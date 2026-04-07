import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vayu/domain/models/health_profile.dart';
import 'package:vayu/providers/storage/storage_provider.dart';
import 'package:vayu/providers/auth/auth_provider.dart';
import 'package:vayu/providers/exposure/exposure_provider.dart';
import 'package:vayu/presentation/widgets/vayu_background.dart';
import 'package:vayu/presentation/widgets/vayu_card.dart';
import 'package:vayu/presentation/widgets/vayu_button.dart';
import 'package:vayu/presentation/widgets/vayu_text_field.dart';

class QuestionnaireScreen extends ConsumerStatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  ConsumerState<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends ConsumerState<QuestionnaireScreen> {
  final _formKey = GlobalKey<FormState>();
  
  AgeGroup _ageGroup = AgeGroup.adult;
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  
  bool _hasAsthma = false;
  bool _hasLungProblems = false;
  bool _hasShortnessOfBreath = false;

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);

    final conditions = <HealthCondition>[];
    if (_hasAsthma) conditions.add(HealthCondition.asthma);
    if (!_hasAsthma && !_hasLungProblems) conditions.add(HealthCondition.healthy);

    final profile = HealthProfile(
      age: 30, // Default numeric age, ageGroup is more granular now
      ageGroup: _ageGroup,
      height: height,
      weight: weight,
      hasLungProblems: _hasLungProblems,
      hasShortnessOfBreath: _hasShortnessOfBreath,
      conditions: conditions,
    );

    await ref.read(storageRepositoryProvider).saveHealthProfile(profile);
    ref.invalidate(healthProfileProvider);
    
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: VayuBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 80.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.favorite, size: 64, color: Colors.white),
                const SizedBox(height: 24),
                const Text(
                  'Personalize Your Vayu',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'A few questions to help us calculate your air health sensitivity.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 48),

                _buildSectionTitle('What is your age group?'),
                const SizedBox(height: 16),
                _buildAgeGroupSelector(),
                const SizedBox(height: 32),

                _buildSectionTitle('Body Metrics (Optional)'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: VayuTextField(
                        controller: _heightController,
                        hintText: 'Height (cm)',
                        prefixIcon: Icons.height,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: VayuTextField(
                        controller: _weightController,
                        hintText: 'Weight (kg)',
                        prefixIcon: Icons.monitor_weight_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                _buildSectionTitle('Respiratory Health'),
                const SizedBox(height: 16),
                _buildConditionToggle(
                  'Do you have Asthma?',
                  _hasAsthma,
                  (val) => setState(() => _hasAsthma = val),
                  Icons.air,
                ),
                const SizedBox(height: 12),
                _buildConditionToggle(
                  'Any other lung related problems?',
                  _hasLungProblems,
                  (val) => setState(() => _hasLungProblems = val),
                  Icons.medical_services_outlined,
                ),
                const SizedBox(height: 12),
                _buildConditionToggle(
                  'Do you experience shortness of breath?',
                  _hasShortnessOfBreath,
                  (val) => setState(() => _hasShortnessOfBreath = val),
                  Icons.speed,
                ),
                const SizedBox(height: 48),

                VayuButton(
                  label: 'Finish Setup',
                  onPressed: _save,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5),
    );
  }

  Widget _buildAgeGroupSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: AgeGroup.values.map((group) {
        final isSelected = _ageGroup == group;
        return InkWell(
          onTap: () => setState(() => _ageGroup = group),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Text(
              group.label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF00796B) : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConditionToggle(String label, bool value, ValueChanged<bool> onChanged, IconData icon) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: VayuCard(
        padding: const EdgeInsets.all(16),
        showShadow: false,
        color: value ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.1),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.tealAccent,
            ),
          ],
        ),
      ),
    );
  }
}
