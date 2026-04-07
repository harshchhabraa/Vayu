import 'package:vayu/domain/models/scored_route.dart';
import 'package:vayu/domain/models/aqi_reading.dart';
import 'package:vayu/domain/interfaces/i_aqi_repository.dart';
import 'dart:math';

class NavigationEngine {
  /// Decodes a Google encoded polyline string.
  List<RouteAqiSample> decodeAndSamplePolyline(String encodedPolyline, int sampleCount) {
    if (encodedPolyline.isEmpty || sampleCount <= 0) return [];

    final points = _decodePolyline(encodedPolyline);
    if (points.isEmpty) return [];
    
    if (points.length <= sampleCount) {
      return points.map((p) => RouteAqiSample(latitude: p.latitude, longitude: p.longitude, aqi: 0, distanceAlongRoute: 0)).toList();
    }
    
    // Sample equidistantly
    final List<RouteAqiSample> samples = [];
    final double step = points.length / sampleCount;
    for (int i = 0; i < sampleCount; i++) {
      int index = (i * step).round();
      if (index >= points.length) index = points.length - 1;
      
      samples.add(RouteAqiSample(
        latitude: points[index].latitude,
        longitude: points[index].longitude,
        aqi: 0, // AQI will be fetched and updated later
        distanceAlongRoute: 0,
      ));
    }
    return samples;
  }

  /// Scores a route based on AQI samples, duration, and distance.
  double scoreRoute({
    required int durationSeconds,
    required int distanceMeters,
    required List<RouteAqiSample> aqiSamples,
    required double maxDurationInSet,
    required double maxDistanceInSet,
  }) {
    if (aqiSamples.isEmpty) return double.maxFinite;

    // Calculate average AQI for the route
    double totalAqi = 0;
    for (final sample in aqiSamples) {
      totalAqi += sample.aqi;
    }
    final double avgAqi = totalAqi / aqiSamples.length;

    // Base Exposure calculation
    final double durationHours = durationSeconds / 3600.0;
    final double rawExposure = avgAqi * durationHours;

    // Normalization (simple for scoring)
    final double normExposure = rawExposure / 500.0; // Max possible realistic exposure
    final double normDuration = maxDurationInSet > 0 ? durationSeconds / maxDurationInSet : 1.0;
    final double normDistance = maxDistanceInSet > 0 ? distanceMeters / maxDistanceInSet : 1.0;

    // Weights: 60% exposure, 30% duration, 10% distance
    final double finalScore = (0.6 * normExposure) + (0.3 * normDuration) + (0.1 * normDistance);
    return finalScore;
  }

  /// Fetches real AQI data for samples along each route and updates scores.
  Future<List<ScoredRoute>> correlateAqi(List<ScoredRoute> routes, IAqiRepository repo) async {
    if (routes.isEmpty) return [];

    final List<ScoredRoute> correlatedRoutes = [];

    for (final route in routes) {
      // 1. Identify 5 sample points (Start, 25%, 50%, 75%, End)
      final List<RouteAqiSample> rawSamples = route.aqiSamples;
      if (rawSamples.isEmpty) { correlatedRoutes.add(route); continue; }

      final List<int> sampleIndices = [
        0,
        (rawSamples.length * 0.25).toInt(),
        (rawSamples.length * 0.5).toInt(),
        (rawSamples.length * 0.75).toInt(),
        rawSamples.length - 1,
      ];

      // 2. Fetch AQI for these points in parallel
      final List<Future<RouteAqiSample>> sampleFutures = sampleIndices.map((idx) async {
        if (idx >= rawSamples.length) idx = rawSamples.length - 1;
        final s = rawSamples[idx];
        try {
          final reading = await repo.getAqi(s.latitude, s.longitude);
          return RouteAqiSample(
            latitude: s.latitude,
            longitude: s.longitude,
            aqi: reading?.aqi ?? 0,
            distanceAlongRoute: s.distanceAlongRoute,
          );
        } catch (_) {
          return s;
        }
      }).toList();

      final List<RouteAqiSample> updatedSamples = await Future.wait(sampleFutures);
      
      // 3. Calculate Average AQI
      final double avgAqi = updatedSamples.map((s) => s.aqi).reduce((a, b) => a + b) / updatedSamples.length;

      correlatedRoutes.add(route.copyWith(
        aqiSamples: updatedSamples,
        avgAqi: avgAqi,
      ));
    }

    return correlatedRoutes;
  }

  /// Ranks routes by their overall exposure and travel score.
  List<ScoredRoute> rankRoutes(List<ScoredRoute> routes) {
    if (routes.isEmpty) return [];

    // 1. Calculate base scores for each route
    final double maxDuration = routes.map((r) => r.durationSeconds).reduce(max).toDouble();
    final double maxDistance = routes.map((r) => r.distanceMeters).reduce(max).toDouble();

    final List<ScoredRoute> scored = routes.map((r) {
      final score = scoreRoute(
        durationSeconds: r.durationSeconds,
        distanceMeters: r.distanceMeters,
        aqiSamples: r.aqiSamples,
        maxDurationInSet: maxDuration,
        maxDistanceInSet: maxDistance,
      );
      return r.copyWith(overallScore: score);
    }).toList();
    
    // Sort by exposure score primarily (lower is better overall health impact)
    scored.sort((a, b) => a.overallScore.compareTo(b.overallScore));

    // 2. Identify the absolute best route for exposure (Cleanest)
    final cleanestRoute = scored.reduce((a, b) => 
      (a.avgAqi * a.durationSeconds) < (b.avgAqi * b.durationSeconds) ? a : b);

    // 3. Generate mode-aware insights
    return scored.map((r) {
      final currentExposure = r.avgAqi * (r.durationSeconds / 3600.0);
      
      // Compare to the average driving exposure if available
      final drivingRoutes = scored.where((s) => s.mode == TravelMode.drive).toList();
      final baseDrivingExposure = drivingRoutes.isNotEmpty 
        ? drivingRoutes.first.avgAqi * (drivingRoutes.first.durationSeconds / 3600.0)
        : currentExposure;

      final diffToDrive = baseDrivingExposure > 0 
        ? ((currentExposure - baseDrivingExposure) / baseDrivingExposure) * 100 
        : 0.0;
      
      String insight = 'Standard ${r.mode?.name ?? 'Route'}';
      
      if (r == cleanestRoute) {
        insight = 'VAYU BEST CHOICE 🏆 | Lowest total exposure across all modes.';
      } else if (r.mode == TravelMode.walk && diffToDrive < -20) {
        insight = 'Healthy alternative: Reduces exposure by ${diffToDrive.abs().toStringAsFixed(0)}% vs driving.';
      } else if (r.mode == TravelMode.bicycle && diffToDrive < -15) {
        insight = 'Green commuter: Faster than walking, cleaner than driving.';
      } else if (diffToDrive < -10) {
        insight = 'Air-optimized path for this travel mode.';
      } else if (diffToDrive > 10 && r.mode == TravelMode.drive) {
        insight = 'Fastest, but high smog exposure.';
      }

      return r.copyWith(
        exposurePercentage: diffToDrive,
        summary: insight,
        greeneryLevel: r.mode == TravelMode.walk ? 0.9 : (r.mode == TravelMode.bicycle ? 0.7 : 0.3),
        trafficLevel: r.mode == TravelMode.drive ? 0.8 : 0.1,
      );
    }).toList();
  }

  // Standard Polyline decoding algorithm
  List<_Coordinate> _decodePolyline(String encoded) {
    List<_Coordinate> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(_Coordinate(lat / 1E5, lng / 1E5));
    }
    return poly;
  }
}

class _Coordinate {
  final double latitude;
  final double longitude;
  _Coordinate(this.latitude, this.longitude);
}
