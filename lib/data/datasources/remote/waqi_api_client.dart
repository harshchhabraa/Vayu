import 'dart:async';
import 'package:dio/dio.dart';
import 'package:vayu/data/dto/waqi_response_dto.dart';

class WaqiApiClient {
  final Dio _dio;
  final String _token;
  static const String _baseUrl = 'https://api.waqi.info';

  // Simple in-memory cache
  static final Map<String, _CacheEntry> _cache = {};
  static const Duration _cacheTtl = Duration(minutes: 10);

  WaqiApiClient(this._dio, this._token);

  Future<WaqiResponseDto> getFeedByGeo(double lat, double lng) async {
    final cacheKey = '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}';
    
    // 1. Check Cache
    if (_cache.containsKey(cacheKey)) {
      final entry = _cache[cacheKey]!;
      if (DateTime.now().isBefore(entry.expiry)) {
        return entry.data;
      }
    }

    // 2. Fetch with Retries
    int attempt = 0;
    const int maxAttempts = 3;

    while (attempt < maxAttempts) {
      try {
        final response = await _dio.get(
          '$_baseUrl/feed/geo:$lat;$lng/',
          queryParameters: {'token': _token},
          options: Options(
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );

        if (response.statusCode == 200) {
          final data = WaqiResponseDto.fromJson(response.data as Map<String, dynamic>);
          _cache[cacheKey] = _CacheEntry(data, DateTime.now().add(_cacheTtl));
          return data;
        }
        throw Exception('Server returned ${response.statusCode}');
      } catch (e) {
        attempt++;
        if (attempt >= maxAttempts) rethrow;
        // Exponential backoff: 1s, 2s, 4s...
        await Future.delayed(Duration(seconds: 1 << (attempt - 1)));
      }
    }
    throw Exception('Failed after $maxAttempts attempts');
  }
}

class _CacheEntry {
  final WaqiResponseDto data;
  final DateTime expiry;
  _CacheEntry(this.data, this.expiry);
}
