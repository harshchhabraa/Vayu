import 'package:equatable/equatable.dart';

/// User's health profile for personalized exposure calculation.
class HealthProfile extends Equatable {
  const HealthProfile({
    required this.age,
    this.conditions = const [HealthCondition.healthy],
    this.isPregnant = false,
    this.protection = ProtectionMode.none,
    this.customSensitivityOverride,
    this.homeLatitude,
    this.homeLongitude,
    this.height,
    this.weight,
    this.hasShortnessOfBreath = false,
    this.hasLungProblems = false,
    this.ageGroup = AgeGroup.adult,
  });

  final int age;
  final List<HealthCondition> conditions;
  final bool isPregnant;
  final ProtectionMode protection;
  final double? customSensitivityOverride;
  final double? homeLatitude;
  final double? homeLongitude;
  
  // New health data fields
  final double? height;
  final double? weight;
  final bool hasShortnessOfBreath;
  final bool hasLungProblems;
  final AgeGroup ageGroup;

  /// Whether a safe zone is configured.
  bool get hasHome => homeLatitude != null && homeLongitude != null;

  /// Computes the health sensitivity multiplier (vulnerability factor).
  double get sensitivityFactor {
    if (customSensitivityOverride != null) return customSensitivityOverride!;

    double baseValue = 1.0;
    if (ageGroup == AgeGroup.child) baseValue = 1.4;
    if (ageGroup == AgeGroup.senior) baseValue = 1.3;

    double conditionMax = 1.0;
    for (final condition in conditions) {
      if (condition.multiplier > conditionMax) conditionMax = condition.multiplier;
    }

    if (hasLungProblems && 1.6 > conditionMax) conditionMax = 1.6;
    if (hasShortnessOfBreath && 1.2 > conditionMax) conditionMax = 1.2;
    if (isPregnant && 1.5 > conditionMax) conditionMax = 1.5;

    return baseValue > conditionMax ? baseValue : conditionMax;
  }

  /// Protection factor (mask usage).
  double get protectionFactor => protection.multiplier;

  HealthProfile copyWith({
    int? age,
    List<HealthCondition>? conditions,
    bool? isPregnant,
    ProtectionMode? protection,
    double? customSensitivityOverride,
    double? homeLatitude,
    double? homeLongitude,
    double? height,
    double? weight,
    bool? hasShortnessOfBreath,
    bool? hasLungProblems,
    AgeGroup? ageGroup,
  }) {
    return HealthProfile(
      age: age ?? this.age,
      conditions: conditions ?? this.conditions,
      isPregnant: isPregnant ?? this.isPregnant,
      protection: protection ?? this.protection,
      customSensitivityOverride: customSensitivityOverride ?? this.customSensitivityOverride,
      homeLatitude: homeLatitude ?? this.homeLatitude,
      homeLongitude: homeLongitude ?? this.homeLongitude,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      hasShortnessOfBreath: hasShortnessOfBreath ?? this.hasShortnessOfBreath,
      hasLungProblems: hasLungProblems ?? this.hasLungProblems,
      ageGroup: ageGroup ?? this.ageGroup,
    );
  }

  static const HealthProfile defaultProfile = HealthProfile(age: 30);

  @override
  List<Object?> get props => [
        age, 
        conditions, 
        isPregnant, 
        protection, 
        customSensitivityOverride,
        homeLatitude,
        homeLongitude,
        height,
        weight,
        hasShortnessOfBreath,
        hasLungProblems,
        ageGroup,
      ];
}

enum AgeGroup {
  child(label: 'Child (<12)'),
  teen(label: 'Teen (12-18)'),
  adult(label: 'Adult (18-65)'),
  senior(label: 'Senior (>65)');

  const AgeGroup({required this.label});
  final String label;
}

enum HealthCondition {
  asthma(multiplier: 1.6, label: 'Asthma'),
  smoker(multiplier: 1.3, label: 'Smoker'),
  copd(multiplier: 1.6, label: 'COPD'),
  cardiovascular(multiplier: 1.4, label: 'Cardiovascular Disease'),
  allergicRhinitis(multiplier: 1.2, label: 'Allergic Rhinitis'),
  lungDisease(multiplier: 1.5, label: 'Chronic Lung Disease'),
  healthy(multiplier: 1.0, label: 'Healthy');

  const HealthCondition({required this.multiplier, required this.label});
  final double multiplier;
  final String label;
}

enum ProtectionMode {
  none(multiplier: 1.0, label: 'None'),
  surgical(multiplier: 0.4, label: 'Surgical Mask'),
  n95(multiplier: 0.05, label: 'N95 Respirator');

  const ProtectionMode({required this.multiplier, required this.label});
  final double multiplier;
  final String label;
}
