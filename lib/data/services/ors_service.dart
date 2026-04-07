import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:vayu/core/config/vayu_config.dart';

import 'package:vayu/domain/models/vayu_route.dart';

class OrsService {
  final Dio _dio = Dio();
  static const String _orsApiKey = VayuConfig.orsKey;
  static const String _baseUrl = 'https://api.openrouteservice.org/v2/directions';

  /// Fetches multiple route candidates from OpenRouteService.
  Future<List<RouteCandidate>> fetchRoutes(LatLng start, LatLng end, {String profile = 'foot-walking'}) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/$profile/geojson',
        data: {
          "coordinates": [
            [start.longitude, start.latitude],
            [end.longitude, end.latitude]
          ],
          "alternative_routes": {"target_count": 2, "share_factor": 0.6},
          "preference": "shortest"
        },
        options: Options(headers: {"Authorization": _orsApiKey, "Content-Type": "application/json"}),
      );

      if (response.statusCode == 200) {
        final List features = response.data['features'];
        return features.map<RouteCandidate>((dynamic f) {
            final List coords = f['geometry']['coordinates'];
            final polyline = coords.map((c) => LatLng(c[1], c[0])).toList();
            
            final properties = f['properties'] ?? {};
            final summary = properties['summary'] ?? {};
            
            final List<RouteStep> steps = [];
            final segments = properties['segments'] as List?;
            if (segments != null && segments.isNotEmpty) {
              final segSteps = segments.first['steps'] as List?;
              if (segSteps != null) {
                for (var s in segSteps) {
                  steps.add(RouteStep(
                    instruction: s['instruction'] ?? '',
                    distanceMeters: (s['distance'] ?? 0).toDouble(),
                    durationSeconds: (s['duration'] ?? 0).toDouble(),
                  ));
                }
              }
            }
            
            return RouteCandidate(
              polyline: polyline,
              distanceMeters: (summary['distance'] ?? 0).toDouble(),
              durationSeconds: (summary['duration'] ?? 0).toDouble(),
              steps: steps,
            );
        }).toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        // Fallback to a single standard route if alternative routes generate a 400
        final fallbackResponse = await _dio.post(
          '$_baseUrl/$profile/geojson',
          data: {
            "coordinates": [
              [start.longitude, start.latitude],
              [end.longitude, end.latitude]
            ]
          },
          options: Options(headers: {"Authorization": _orsApiKey, "Content-Type": "application/json"}),
        );
        if (fallbackResponse.statusCode == 200) {
          final List features = fallbackResponse.data['features'];
          return features.map<RouteCandidate>((dynamic f) {
              final List coords = f['geometry']['coordinates'];
              final polyline = coords.map((c) => LatLng(c[1], c[0])).toList();
              
              final properties = f['properties'] ?? {};
              final summary = properties['summary'] ?? {};
              
              final List<RouteStep> steps = [];
              final segments = properties['segments'] as List?;
              if (segments != null && segments.isNotEmpty) {
                final segSteps = segments.first['steps'] as List?;
                if (segSteps != null) {
                  for (var s in segSteps) {
                    steps.add(RouteStep(
                      instruction: s['instruction'] ?? '',
                      distanceMeters: (s['distance'] ?? 0).toDouble(),
                      durationSeconds: (s['duration'] ?? 0).toDouble(),
                    ));
                  }
                }
              }
              
              return RouteCandidate(
                polyline: polyline,
                distanceMeters: (summary['distance'] ?? 0).toDouble(),
                durationSeconds: (summary['duration'] ?? 0).toDouble(),
                steps: steps,
              );
          }).toList();
        }
      }
      rethrow;
    }
  }

  /// Autocompletes a query to providing predicted location strings.
  Future<List<String>> autocompleteLocation(String query) async {
    if (query.length < 3) return [];
    try {
      final response = await _dio.get(
        'https://api.openrouteservice.org/geocode/autocomplete',
        queryParameters: {
          "api_key": _orsApiKey,
          "text": query,
        },
      );
      if (response.statusCode == 200) {
        final List features = response.data['features'];
        return features.map((f) => f['properties']['label'].toString()).toList();
      }
    } catch (e) {
      print('Autocomplete Error: $e');
    }
    return [];
  }

  /// Converts an address query string into LatLng coordinates using ORS Geocoding (Pelias).
  Future<LatLng?> searchLocation(String query) async {
    // Intercept literal GPS coordinate strings ("lat, lon")
    final parts = query.split(',');
    if (parts.length == 2) {
      final lat = double.tryParse(parts[0].trim());
      final lon = double.tryParse(parts[1].trim());
      if (lat != null && lon != null) {
        return LatLng(lat, lon);
      }
    }

    try {
      final response = await _dio.get(
        'https://api.openrouteservice.org/geocode/search',
        queryParameters: {
          "api_key": _orsApiKey,
          "text": query,
          "size": 1,
        },
      );

      if (response.statusCode == 200) {
        final List features = response.data['features'];
        if (features.isNotEmpty) {
          final List coords = features.first['geometry']['coordinates'];
          return LatLng(coords[1], coords[0]);
        }
      }
    } catch (e) {
      print('Geocoding Error: $e');
    }
    return null;
  }

  /// Helper to decode polyline strings into LatLng points.
  List<LatLng> decodePolyline(String encoded) {
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> result = polylinePoints.decodePolyline(encoded);
    return result.map((p) => LatLng(p.latitude, p.longitude)).toList();
  }
}
