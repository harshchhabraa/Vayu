import 'dart:async';
import 'package:vayu/domain/interfaces/i_aqi_repository.dart';
import 'package:vayu/domain/models/aqi_reading.dart';
import 'package:vayu/domain/models/forecast_point.dart';
import 'package:vayu/data/datasources/remote/waqi_api_client.dart';

class WaqiAqiRepository implements IAqiRepository {
  final WaqiApiClient _apiClient;
  
  // Minimal caching implementation for the repository
  AqiReading? _latestReading;
  DateTime? _lastFetchTime;

  WaqiAqiRepository(this._apiClient);

  @override
  Stream<AqiReading> watchCurrentAqi(double lat, double lng) async* {
    while (true) {
      final shouldFetch = _latestReading == null || 
                         _lastFetchTime == null || 
                         DateTime.now().difference(_lastFetchTime!).inMinutes >= 10;
          
      if (shouldFetch) {
        try {
          final dto = await _apiClient.getFeedByGeo(lat, lng);
          
          if (dto.status == 'ok' && dto.data != null) {
            final data = dto.data!;
            _latestReading = AqiReading(
              aqi: data.aqi,
              dominantPollutant: data.dominentpol,
              timestamp: data.time.iso,
              latitude: data.city.geo.isNotEmpty ? data.city.geo[0] : lat,
              longitude: data.city.geo.length > 1 ? data.city.geo[1] : lng,
              stationName: data.city.name,
              pm25: data.iaqi.pm25,
              pm10: data.iaqi.pm10,
              o3: data.iaqi.o3,
              no2: data.iaqi.no2,
              so2: data.iaqi.so2,
              co: data.iaqi.co,
              source: AqiSource.waqi,
            );
            _lastFetchTime = DateTime.now();
          }
        } catch (e) {
          // Log error but don't crash
        }
      }

      if (_latestReading != null) {
        yield _latestReading!;
        // Standard poll delay: 10 minutes
        await Future.delayed(const Duration(minutes: 10));
      } else {
        // High frequency retry (10s) until first data comes in
        await Future.delayed(const Duration(seconds: 10));
      }
    }
  }

  @override
  Future<AqiReading?> getAqi(double lat, double lng) async {
    try {
      final dto = await _apiClient.getFeedByGeo(lat, lng);
      if (dto.status == 'ok' && dto.data != null) {
        final data = dto.data!;
        return AqiReading(
          aqi: data.aqi,
          dominantPollutant: data.dominentpol,
          timestamp: data.time.iso,
          latitude: data.city.geo.isNotEmpty ? data.city.geo[0] : lat,
          longitude: data.city.geo.length > 1 ? data.city.geo[1] : lng,
          stationName: data.city.name,
          pm25: data.iaqi.pm25,
          pm10: data.iaqi.pm10,
          o3: data.iaqi.o3,
          no2: data.iaqi.no2,
          so2: data.iaqi.so2,
          co: data.iaqi.co,
          source: AqiSource.waqi,
        );
      }
    } catch (e) {
      print('WaqiAqiRepository Error: $e');
    }
    return null;
  }

  @override
  Future<List<AqiReading>> getHistory(double lat, double lng, DateTime start, DateTime end) async {
    // WAQI public API doesn't provide free history. This would require
    // combining with cached local database records from Drift.
    return []; 
  }

  @override
  Future<List<ForecastPoint>> getForecast(double lat, double lng) async {
    // WAQI returns some forecast data in their enterprise feed, or we
    // fetch this from the Google Air Quality API. Returning empty for now.
    return [];
  }
}
