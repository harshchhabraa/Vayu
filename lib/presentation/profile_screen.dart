import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vayu/domain/models/health_profile.dart';
import 'package:vayu/providers/exposure/exposure_provider.dart';
import 'package:vayu/providers/storage/storage_provider.dart';
import 'package:vayu/presentation/widgets/vayu_background.dart';
import 'package:vayu/presentation/widgets/vayu_card.dart';
import 'package:vayu/presentation/widgets/vayu_button.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late int _age;
  late bool _isPregnant;
  late List<HealthCondition> _selectedConditions;
  late ProtectionMode _protection;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(healthProfileProvider).value ?? HealthProfile.defaultProfile;
    _age = profile.age;
    _isPregnant = profile.isPregnant;
    _selectedConditions = List.from(profile.conditions);
    _protection = profile.protection;
  }

  void _saveProfile() async {
    final newProfile = HealthProfile(
      age: _age,
      isPregnant: _isPregnant,
      conditions: _selectedConditions,
      protection: _protection,
    );
    
    await ref.read(storageRepositoryProvider).saveHealthProfile(newProfile);
    ref.invalidate(healthProfileProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile updated! Health sensitivity adjusted.'),
        backgroundColor: const Color(0xFF4DB6AC),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: VayuBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 100.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Personalize Your Health',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Help Vayu calculate your personal exposure risk accurately.',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 32),

              VayuCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Age Group', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00695C))),
                    const SizedBox(height: 12),
                    Slider(
                      value: _age.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 10,
                      activeColor: const Color(0xFF009688),
                      label: '$_age years',
                      onChanged: (val) => setState(() => _age = val.toInt()),
                    ),
                    
                    const SizedBox(height: 24),
                    const Text('Specific Conditions', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00695C))),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: HealthCondition.values.map((condition) {
                        final isSelected = _selectedConditions.contains(condition);
                        return FilterChip(
                          label: Text(condition.name.toUpperCase()),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedConditions.add(condition);
                              } else {
                                _selectedConditions.remove(condition);
                              }
                            });
                          },
                          selectedColor: const Color(0xFF009688).withOpacity(0.2),
                          checkmarkColor: const Color(0xFF009688),
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFF00695C) : Colors.black54,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),

                    SwitchListTile(
                      title: const Text('Currently Pregnant', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00695C))),
                      value: _isPregnant,
                      activeColor: const Color(0xFF009688),
                      onChanged: (val) => setState(() => _isPregnant = val),
                    ),

                    const SizedBox(height: 24),
                    const Text('Respiratory Protection', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00695C))),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ProtectionMode>(
                      value: _protection,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFE8F5E9).withOpacity(0.5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: ProtectionMode.values.map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.label),
                      )).toList(),
                      onChanged: (val) => setState(() => _protection = val!),
                    ),

                    const SizedBox(height: 32),
                    VayuButton(
                      label: 'Update My Profile',
                      onPressed: _saveProfile,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              const Text(
                'Sensitivity Factor',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              VayuCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.speed, color: Color(0xFF00695C), size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your vulnerability multiplier is ${HealthProfile(age: _age, isPregnant: _isPregnant, conditions: _selectedConditions, protection: _protection).sensitivityFactor.toStringAsFixed(2)}x',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00695C)),
                          ),
                          Text(
                            'Protection factor active: ${HealthProfile(age: _age, isPregnant: _isPregnant, conditions: _selectedConditions, protection: _protection).protectionFactor.toStringAsFixed(2)}x',
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
