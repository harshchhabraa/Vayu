import 'package:vayu/domain/models/scored_route.dart';

abstract class IRouteRepository {
  /// Compute routes between origin and destination.
  Future<List<ScoredRoute>> computeRoutes({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required TravelMode mode,
  });
}
