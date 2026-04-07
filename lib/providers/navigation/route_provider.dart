import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vayu/domain/engines/navigation_engine.dart';
import 'package:vayu/domain/models/scored_route.dart';
import 'package:vayu/domain/interfaces/i_route_repository.dart';
import 'package:vayu/data/repositories/ors_route_repository.dart';
import 'package:vayu/core/config/vayu_config.dart';
import 'package:vayu/providers/aqi/aqi_provider.dart';

// A mock repository to provide sample routes since we don't have a real API key yet
class MockRouteRepository implements IRouteRepository {
  @override
  Future<List<ScoredRoute>> computeRoutes({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required TravelMode mode,
  }) async {
    return [
      const ScoredRoute(
        routeIndex: 0,
        encodedPolyline: '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
        distanceMeters: 2400,
        durationSeconds: 1440,
        avgAqi: 42,
        exposureScore: 15,
        overallScore: 0.4,
        aqiSamples: [],
        summary: 'via Greenway Drive',
      ),
      const ScoredRoute(
        routeIndex: 1,
        encodedPolyline: 'a~lFnav|U_ulLnnqC_mqNvxq`@',
        distanceMeters: 3100,
        durationSeconds: 1080,
        avgAqi: 22,
        exposureScore: 12,
        overallScore: 0.35,
        aqiSamples: [],
        summary: 'Health Optimized Path',
      ),
    ];
  }
}

final navigationEngineProvider = Provider((ref) => NavigationEngine());

final routeRepositoryProvider = Provider<IRouteRepository>((ref) {
  if (VayuConfig.useMockData) {
    return MockRouteRepository();
  }
  final dio = ref.watch(dioProvider);
  return OrsRouteRepository(dio, VayuConfig.orsKey);
});

// Provides a list of routes ranked by their health score
final rankedRoutesProvider = FutureProvider.family<List<ScoredRoute>, ({double lat, double lng})>((ref, coords) async {
  final repo = ref.watch(routeRepositoryProvider);
  final engine = ref.watch(navigationEngineProvider);
  
  // In a real app, destination is selected by user. Using mock destination for now.
  final routes = await repo.computeRoutes(
    originLat: coords.lat, 
    originLng: coords.lng, 
    destLat: coords.lat + 0.05, 
    destLng: coords.lng + 0.05,
    mode: TravelMode.drive,
  );
  
  return engine.rankRoutes(routes);
});
