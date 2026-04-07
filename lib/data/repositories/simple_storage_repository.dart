import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vayu/domain/interfaces/i_storage_repository.dart';
import 'package:vayu/domain/models/exposure_entry.dart';
import 'package:vayu/domain/models/health_profile.dart';
import 'package:vayu/domain/models/exposure_snapshot.dart';

class SimpleStorageRepository implements IStorageRepository {
  final SharedPreferences _prefs;
  static const String _storageKey = 'exposure_ticks_v2';

  SimpleStorageRepository(this._prefs);

  @override
  Future<void> saveExposureEntry(ExposureEntry entry) async {
    final raw = _prefs.getString(_storageKey) ?? '[]';
    final List<dynamic> list = jsonDecode(raw);
    
    list.add({
      'timestamp': entry.timestamp.toIso8601String(),
      'durationSeconds': entry.durationSeconds,
      'aqi': entry.aqi,
      'latitude': entry.latitude,
      'longitude': entry.longitude,
      'activity': entry.activity.name,
      'protectionFactor': entry.protectionFactor,
      'vulnerabilityFactor': entry.vulnerabilityFactor,
      'visionFactor': entry.visionFactor,
      'score': entry.score,
    });

    // Clean up: Keep only last 7 days of history
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final filteredList = list.where((e) {
      final ts = DateTime.parse(e['timestamp'] as String);
      return ts.isAfter(sevenDaysAgo);
    }).toList();
    
    await _prefs.setString(_storageKey, jsonEncode(filteredList));
  }

  @override
  Future<List<ExposureEntry>> getExposureEntries(DateTime date) async {
    final raw = _prefs.getString(_storageKey) ?? '[]';
    final List<dynamic> list = jsonDecode(raw);
    
    return list.map((e) => ExposureEntry(
      timestamp: DateTime.parse(e['timestamp']),
      durationSeconds: e['durationSeconds'],
      aqi: e['aqi'],
      latitude: e['latitude'],
      longitude: e['longitude'],
      activity: ActivityMode.values.byName(e['activity']),
      protectionFactor: e['protectionFactor'],
      vulnerabilityFactor: e['vulnerabilityFactor'],
      visionFactor: e['visionFactor'],
      score: e['score'],
    )).where((e) => 
      e.timestamp.year == date.year && 
      e.timestamp.month == date.month && 
      e.timestamp.day == date.day
    ).toList();
  }

  @override
  Future<List<ExposureSummary>> getExposureSummaries(DateTime start, DateTime end) async {
    // Collect all unique days between start and end
    final raw = _prefs.getString(_storageKey) ?? '[]';
    final List<dynamic> list = jsonDecode(raw);
    
    // Group and return (simplified for this repo)
    return [];
  }

  @override
  Future<void> saveExposureSummary(ExposureSummary summary) async => {};

  @override
  Future<void> saveHealthProfile(HealthProfile profile) async {
    final data = {
      'age': profile.age,
      'isPregnant': profile.isPregnant,
      'conditions': profile.conditions.map((c) => c.name).toList(),
      'protection': profile.protection.name,
      'customSensitivityOverride': profile.customSensitivityOverride,
      'homeLatitude': profile.homeLatitude,
      'homeLongitude': profile.homeLongitude,
      'height': profile.height,
      'weight': profile.weight,
      'hasShortnessOfBreath': profile.hasShortnessOfBreath,
      'hasLungProblems': profile.hasLungProblems,
      'ageGroup': profile.ageGroup.name,
    };
    await _prefs.setString('health_profile_v2', jsonEncode(data));
  }

  @override
  Future<HealthProfile?> getHealthProfile() async {
    final str = _prefs.getString('health_profile_v2');
    if (str == null) return null;
    
    try {
      final data = jsonDecode(str) as Map<String, dynamic>;
      return HealthProfile(
        age: data['age'] as int,
        isPregnant: data['isPregnant'] as bool? ?? false,
        conditions: ((data['conditions'] as List<dynamic>?) ?? [])
            .map((e) => HealthCondition.values.firstWhere(
                  (c) => c.name == e,
                  orElse: () => HealthCondition.healthy,
                ))
            .toList(),
        protection: ProtectionMode.values.firstWhere(
          (p) => p.name == data['protection'],
          orElse: () => ProtectionMode.none,
        ),
        customSensitivityOverride: data['customSensitivityOverride'] as double?,
        homeLatitude: data['homeLatitude'] as double?,
        homeLongitude: data['homeLongitude'] as double?,
        height: data['height'] as double?,
        weight: data['weight'] as double?,
        hasShortnessOfBreath: data['hasShortnessOfBreath'] as bool? ?? false,
        hasLungProblems: data['hasLungProblems'] as bool? ?? false,
        ageGroup: AgeGroup.values.firstWhere(
          (a) => a.name == data['ageGroup'],
          orElse: () => AgeGroup.adult,
        ),
      );
    } catch (e) {
      return null;
    }
  }
}
