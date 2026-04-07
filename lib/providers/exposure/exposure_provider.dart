import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vayu/domain/engines/exposure_engine.dart';
import 'package:vayu/domain/models/exposure_entry.dart';
import 'package:vayu/domain/models/health_profile.dart';
import 'package:vayu/domain/models/exposure_snapshot.dart';
import 'package:vayu/domain/models/aqi_reading.dart';
import 'package:vayu/providers/aqi/aqi_provider.dart';
import 'package:vayu/providers/location/location_provider.dart';
import 'package:vayu/providers/storage/storage_provider.dart';
import 'package:vayu/providers/vision/vision_provider.dart'; 
import 'package:vayu/providers/exposure/activity_provider.dart';
import 'package:vayu/domain/interfaces/i_storage_repository.dart';

final exposureEngineProvider = Provider<ExposureEngine>((ref) {
  return ExposureEngine();
});

final healthProfileProvider = FutureProvider<HealthProfile>((ref) async {
  final repo = ref.watch(storageRepositoryProvider);
  final profile = await repo.getHealthProfile();
  return profile ?? HealthProfile.defaultProfile;
});

final dailyExposureProvider = NotifierProvider<DailyExposureNotifier, ExposureSummary>(() {
  return DailyExposureNotifier();
});

class DailyExposureNotifier extends Notifier<ExposureSummary> {
  final List<ExposureEntry> _todayEntries = [];
  DateTime? _lastUpdate;

  @override
  ExposureSummary build() {
    _init();
    
    return ExposureSummary(
      date: DateTime.now(),
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

  Future<void> _init() async {
    final repo = ref.read(storageRepositoryProvider);
    final history = await repo.getExposureEntries(DateTime.now());
    
    if (history.isNotEmpty) {
      _todayEntries.clear();
      _todayEntries.addAll(history);
      
      final engine = ref.read(exposureEngineProvider);
      state = engine.computeDailySummary(_todayEntries, DateTime.now());
    }

    _listenToEnvironment();
  }

  void _listenToEnvironment() {
    ref.listen<AsyncValue<AqiReading>>(currentAqiProvider, (previous, next) {
      if (next.hasValue) {
        _tick(next.value!);
      }
    });
  }

  void _tick(AqiReading aqiReading) {
    final now = DateTime.now();
    _lastUpdate ??= now;
    
    final elapsed = now.difference(_lastUpdate!);
    if (elapsed.inSeconds < 10) return; 

    final engine = ref.read(exposureEngineProvider);
    final profile = ref.read(healthProfileProvider).value ?? HealthProfile.defaultProfile;
    var activity = ref.read(activityProvider);
    final visionResult = ref.read(visionResultProvider);
    
    // HOME SAFE ZONE LOGIC
    if (profile.hasHome) {
      final distance = Geolocator.distanceBetween(
        aqiReading.latitude, 
        aqiReading.longitude, 
        profile.homeLatitude!, 
        profile.homeLongitude!,
      );
      if (distance <= 10.0) {
        activity = ActivityMode.indoor;
      }
    }

    final currentVisionFactor = visionResult?.visionFactor ?? 1.0;

    final score = engine.calculateInstantExposure(
      aqi: aqiReading.aqi.toDouble(), 
      interval: elapsed, 
      activity: activity, 
      profile: profile,
      visionFactor: currentVisionFactor,
    );

    final entry = ExposureEntry(
      timestamp: now,
      durationSeconds: elapsed.inSeconds,
      aqi: aqiReading.aqi,
      latitude: aqiReading.latitude,
      longitude: aqiReading.longitude,
      activity: activity,
      protectionFactor: profile.protectionFactor,
      vulnerabilityFactor: profile.sensitivityFactor,
      visionFactor: currentVisionFactor,
      score: score,
    );

    _todayEntries.add(entry);
    _lastUpdate = now;

    ref.read(storageRepositoryProvider).saveExposureEntry(entry);
    state = engine.computeDailySummary(_todayEntries, _todayEntries.isNotEmpty ? _todayEntries.first.timestamp : DateTime.now());
  }
}
