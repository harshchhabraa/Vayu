import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:geocoding/geocoding.dart';
import 'package:vayu/domain/models/aqi_reading.dart';
import 'package:vayu/domain/interfaces/i_aqi_repository.dart';
import 'package:vayu/domain/interfaces/i_location_repository.dart';
import 'package:vayu/data/datasources/remote/waqi_api_client.dart';
import 'package:vayu/data/repositories/waqi_aqi_repository.dart';
import 'package:vayu/providers/location/location_provider.dart';
import 'package:vayu/core/config/vayu_config.dart';

// Provides the HTTP client
final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(connectTimeout: const Duration(seconds: 5)));
});

// Provides the WAQI API Client
final waqiApiClientProvider = Provider<WaqiApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return WaqiApiClient(dio, VayuConfig.waqiToken);
});

// Provides the Repository interface
final aqiRepositoryProvider = Provider<IAqiRepository>((ref) {
  final client = ref.watch(waqiApiClientProvider);
  return WaqiAqiRepository(client);
});

// Provides a human-readable name for the current location
final currentLocationNameProvider = FutureProvider<String>((ref) async {
  final locationAsync = ref.watch(currentLocationProvider);
  final aqiAsync = ref.watch(currentAqiProvider);
  
  if (kIsWeb) {
    // Geocoding package doesn't support Web. Use Station Name from AQI.
    return aqiAsync.when(
      data: (reading) => reading.stationName ?? "Detected Location",
      loading: () => "Detecting...",
      error: (_, __) => "Location Found",
    );
  }

  return locationAsync.when(
    data: (pos) async {
      if (pos == null) return "Location Required";
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          return "${p.locality ?? p.subAdministrativeArea ?? 'Unknown'}, ${p.country ?? ''}";
        }
      } catch (e) {
        return aqiAsync.valueOrNull?.stationName ?? "Unknown Location";
      }
      return "Detecting...";
    },
    loading: () => "Detecting...",
    error: (_, __) => "Location Error",
  );
});

// Stream of real-time AQI based on current location
final currentAqiProvider = StreamProvider<AqiReading>((ref) async* {
  final locationAsync = ref.watch(currentLocationProvider);
  
  yield* locationAsync.when(
    data: (loc) {
      if (loc == null) {
        return Stream.value(AqiReading(
          aqi: 0, 
          dominantPollutant: 'none', 
          timestamp: DateTime.now(), 
          latitude: 0.0, 
          longitude: 0.0, 
          source: AqiSource.cache,
          stationName: "Location Required"
        ));
      }
      final repo = ref.watch(aqiRepositoryProvider);
      return repo.watchCurrentAqi(loc.latitude, loc.longitude);
    },
    loading: () => Stream.value(AqiReading(
      aqi: -1, 
      dominantPollutant: 'loading', 
      timestamp: DateTime.now(), 
      latitude: 0, 
      longitude: 0, 
      source: AqiSource.cache,
      stationName: "Detecting..."
    )),
    error: (e, s) => Stream.error(e, s),
  );
});
