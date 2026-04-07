import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dio/dio.dart';
import 'package:vayu/domain/interfaces/i_route_repository.dart';
import 'package:vayu/domain/models/scored_route.dart';
import 'package:vayu/core/config/vayu_config.dart';

class OrsRouteRepository implements IRouteRepository {
  final Dio _dio;
  final String _apiKey;
  static const String _baseUrl = 'https://api.openrouteservice.org/v2/directions';

  OrsRouteRepository(this._dio, this._apiKey);

  @override
  Future<List<ScoredRoute>> computeRoutes({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required TravelMode mode,
  }) async {
    // OpenRouteService expects coordinates in [lng, lat] format
    final body = {
      "coordinates": [
        [originLng, originLat],
        [destLng, destLat]
      ],
      "alternative_routes": {
        "target_count": 3,
        "share_factor": 0.6,
        "weight_factor": 1.4
      },
      "units": "m",
      "geometry": true,
    };

    try {
      final String profile = _getProfileForMode(mode);
      final response = await _dio.post(
        '$_baseUrl/$profile/geojson',
        data: body,
        options: Options(headers: {'Authorization': _apiKey}),
      );

      if (response.statusCode == 200) {
        final dynamic data = response.data;
        if (data == null || data['features'] == null || (data['features'] as List).isEmpty) {
          print('ORS Error: No features found in response.');
          return [];
        }
        final features = data['features'] as List<dynamic>;
        print('ORS Success: Found ${features.length} routes.');
        
        return features.asMap().entries.map((entry) {
          final i = entry.key;
          final feature = entry.value as Map<String, dynamic>;
          final properties = feature['properties']?['summary'] as Map<String, dynamic>?;
          final geometry = feature['geometry']?['coordinates'] as List<dynamic>?;
          
          if (geometry == null || properties == null) {
            return ScoredRoute(
              routeIndex: i, 
              encodedPolyline: '', 
              distanceMeters: 0, 
              durationSeconds: 0, 
              avgAqi: 0, 
              exposureScore: 0, 
              overallScore: 99.0, 
              aqiSamples: const [],
              summary: 'Route Unavailable',
            );
          }

          final List<RouteAqiSample> samples = geometry.map((coord) {
            return RouteAqiSample(
              latitude: (coord[1] as num).toDouble(),
              longitude: (coord[0] as num).toDouble(),
              aqi: 0,
              distanceAlongRoute: 0,
            );
          }).toList();

          // Extract turn-by-turn directions
          final List<RouteStep> steps = [];
          final segments = feature['properties']?['segments'] as List<dynamic>?;
          if (segments != null && segments.isNotEmpty) {
            final rawSteps = segments[0]['steps'] as List<dynamic>?;
            if (rawSteps != null) {
              for (final s in rawSteps) {
                final stepCoordIdx = s['way_points'] != null ? (s['way_points'][0] as int) : 0;
                final lat = stepCoordIdx < geometry.length ? (geometry[stepCoordIdx][1] as num).toDouble() : 0.0;
                final lng = stepCoordIdx < geometry.length ? (geometry[stepCoordIdx][0] as num).toDouble() : 0.0;
                
                steps.add(RouteStep(
                  instruction: s['instruction'] ?? 'Continue',
                  distanceMeters: (s['distance'] as num?)?.toInt() ?? 0,
                  durationSeconds: (s['duration'] as num?)?.toInt() ?? 0,
                  latitude: lat,
                  longitude: lng,
                ));
              }
            }
          }

          return ScoredRoute(
            routeIndex: i,
            encodedPolyline: '',
            distanceMeters: (properties['distance'] as num?)?.toInt() ?? 0,
            durationSeconds: (properties['duration'] as num?)?.toInt() ?? 0,
            avgAqi: 0,
            exposureScore: 0,
            overallScore: 0,
            aqiSamples: samples,
            steps: steps,
            summary: feature['properties']?['segments']?[0]?['steps']?[0]?['instruction'] ?? 'Healthy Route $i',
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('ORS Repository Exception: $e');
      return [];
    }
  }

  String _getProfileForMode(TravelMode mode) {
    switch (mode) {
      case TravelMode.drive: return 'driving-car';
      case TravelMode.walk: return 'foot-walking';
      case TravelMode.bicycle: return 'cycling-regular';
      case TravelMode.transit: return 'driving-car'; // ORS doesn't have local transit public
    }
  }
}
