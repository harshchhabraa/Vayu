import 'package:latlong2/latlong.dart';
import 'package:vayu/data/services/aqi_service.dart';
import 'package:vayu/domain/models/vayu_route.dart';

class RouteExposureEngine {
  final AqiService _aqiService;
  static const Distance _distance = Distance();

  RouteExposureEngine(this._aqiService);

  /// Analyzes a raw candidate and converts it into a health-scored VayuRoute.
  Future<VayuRoute> analyzeRoute(RouteCandidate candidate, String summary) async {
    final double totalDistanceMeters = candidate.distanceMeters > 0 
        ? candidate.distanceMeters 
        : _calculateTotalDistance(candidate.polyline);
        
    final List<AqiPoint> samples = await _samplePoints(candidate.polyline);
    
    final Duration duration = candidate.durationSeconds > 0
        ? Duration(seconds: candidate.durationSeconds.round())
        : Duration(minutes: (totalDistanceMeters / 83).ceil());

    return VayuRoute(
      polyline: candidate.polyline,
      distanceKm: totalDistanceMeters / 1000,
      duration: duration,
      samples: samples,
      summary: summary,
      navigationSteps: candidate.steps,
    );
  }

  /// Samples AQI along the route every ~500 meters.
  Future<List<AqiPoint>> _samplePoints(List<LatLng> polyline) async {
    final List<AqiPoint> aqiSamples = [];
    if (polyline.isEmpty) return aqiSamples;

    double accumulatedDistance = 0;
    LatLng? lastPoint;

    for (int i = 0; i < polyline.length; i++) {
       final currentPoint = polyline[i];
       
       if (lastPoint != null) {
         accumulatedDistance += _distance.as(LengthUnit.Meter, lastPoint, currentPoint);
       }

       // Sample at start, then every 500m, and then at end
       if (i == 0 || accumulatedDistance >= 500 || i == polyline.length - 1) {
         final aqi = await _aqiService.getAqiForCoordinate(currentPoint);
         aqiSamples.add(AqiPoint(
           location: currentPoint,
           aqi: aqi,
           timestamp: DateTime.now(),
         ));
         accumulatedDistance = 0; // Reset after sampling
       }
       lastPoint = currentPoint;
    }
    return aqiSamples;
  }

  double _calculateTotalDistance(List<LatLng> polyline) {
    double total = 0;
    for (int i = 0; i < polyline.length - 1; i++) {
      total += _distance.as(LengthUnit.Meter, polyline[i], polyline[i+1]);
    }
    return total;
  }

  /// Compares multiple routes and calculates the percentage improvement.
  Map<String, dynamic> compareRoutes(List<VayuRoute> routes) {
    if (routes.isEmpty) return {};
    
    // Sort by total exposure (health optimization)
    final sorted = List<VayuRoute>.from(routes)
      ..sort((a, b) => a.totalExposure.compareTo(b.totalExposure));
    
    final VayuRoute bestRoute = sorted.first;
    // Assume the last route (often the longest/most exposed) is the neutral baseline
    final VayuRoute baseline = sorted.last;
    
    double improvement = 0;
    if (baseline.totalExposure > 0) {
      improvement = ((baseline.totalExposure - bestRoute.totalExposure) / baseline.totalExposure) * 100;
    }

    return {
      'optimal_route': bestRoute,
      'improvement_pct': improvement.round(),
      'ranked_routes': sorted,
    };
  }
}
