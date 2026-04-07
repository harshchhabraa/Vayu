import 'package:dio/dio.dart';
import 'package:vayu/domain/models/vayu_route.dart';
import 'package:latlong2/latlong.dart';
import 'package:vayu/core/config/vayu_config.dart';

class AqiService {
  final Dio _dio = Dio();
  static const String _waqiToken = VayuConfig.waqiToken;
  
  // In-memory cache to avoid redundant API hits for overlapping routes
  final Map<String, int> _cache = {};

  Future<int> getAqiForCoordinate(LatLng location) async {
    // Round to 4 decimals to normalize coordinates for caching (~11m precision)
    final String cacheKey = '${location.latitude.toStringAsFixed(4)}:${location.longitude.toStringAsFixed(4)}';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    final String url = 'https://api.waqi.info/feed/geo:${location.latitude};${location.longitude}/?token=$_waqiToken';
    
    try {
      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data['status'] == 'ok') {
        final aqi = int.tryParse(response.data['data']['aqi'].toString()) ?? 0;
        _cache[cacheKey] = aqi;
        return aqi;
      }
    } catch (e) {
      // In case of failure, return a safe default (e.g., 50 - moderate/average)
      return 50;
    }
    return 50;
  }
}
