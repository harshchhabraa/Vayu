import 'package:flutter_test/flutter_test.dart';
import '../lib/domain/engines/exposure_calculator.dart';
import '../lib/domain/models/health_profile.dart';
import '../lib/domain/models/exposure_snapshot.dart';

void main() {
  group('ExposureCalculator Tests', () {
    test('Standard Healthy Adult Exposure Calculation', () {
      final profile = HealthProfile.defaultProfile;
      final result = ExposureCalculator.calculate(
        aqi: 100.0,
        interval: const Duration(hours: 1),
        activity: ActivityMode.driving,
        profile: profile,
      );

      // (100 AQI * 1.0h * 1.0 Activity * 1.0 Vuln * 1.0 Prot * 1.0 Vision) * 0.01 = 1.0
      expect(result, closeTo(1.0, 0.01));
    });

    test('Asthma + N95 Mask Reductive Logic', () {
      final profile = HealthProfile(
        age: 30,
        conditions: const [HealthCondition.asthma],
        protection: ProtectionMode.n95,
      );
      
      final result = ExposureCalculator.calculate(
        aqi: 200.0, // High AQI
        interval: const Duration(hours: 1),
        activity: ActivityMode.walking, // 1.5x
        profile: profile,
      );

      // 200 * 1.0 * 1.5 (Walking) * 1.6 (Asthma) * 0.05 (N95) * 0.01 = 0.24
      expect(result, closeTo(0.24, 0.01));
    });
    
    test('Vision Factor Influence', () {
      final profile = HealthProfile.defaultProfile;
      final result = ExposureCalculator.calculate(
        aqi: 100.0,
        interval: const Duration(hours: 1),
        activity: ActivityMode.walking,
        profile: profile,
        visionFactor: 2.0, // Heavy smoke detected
      );

      // 100 * 1.0 * 1.5 * 1.0 * 1.0 * 2.0 * 0.01 = 3.0
      expect(result, closeTo(3.0, 0.01));
    });
  });
}
