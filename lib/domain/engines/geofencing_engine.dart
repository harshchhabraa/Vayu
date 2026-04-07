import 'package:vayu/domain/models/geofence_zone.dart';

class GeofencingEngine {
  /// Classifies the environment based on position, speed, zones, and activity.
  EnvironmentType classifyEnvironment({
    required double latitude,
    required double longitude,
    required List<GeofenceZone> activeZones,
    required double speedKmH,
    required ActivityType? activity,
  }) {
    // 1. Check speed (highest priority override)
    if (speedKmH > 30 || activity == ActivityType.driving) {
      return EnvironmentType.vehicle;
    }
    if (speedKmH > 5 || activity == ActivityType.cycling) {
      return EnvironmentType.transit;
    }

    // 2. Check geofences (if stationary or walking)
    for (final zone in activeZones) {
      if (zone.containsPoint(latitude, longitude)) {
        // Map zone type to environment type
        switch (zone.zoneType) {
          case GeofenceZoneType.indoor:
            return EnvironmentType.indoor;
          case GeofenceZoneType.outdoor:
            return EnvironmentType.outdoor;
          case GeofenceZoneType.transit:
            return EnvironmentType.transit;
          case GeofenceZoneType.vehicle:
            return EnvironmentType.vehicle;
        }
      }
    }

    // 3. Default fallback
    return EnvironmentType.outdoor;
  }

  /// Prioritizes and limits the active zones to respect OS limits.
  List<GeofenceZone> prioritizeZones({
    required double currentLat,
    required double currentLng,
    required List<GeofenceZone> allZones,
    int maxActive = 20,
  }) {
    if (allZones.length <= maxActive) {
      return List.unmodifiable(allZones);
    }

    // Sort by distance
    final sorted = List<GeofenceZone>.from(allZones)
      ..sort((a, b) {
        final distA = a.distanceFromMeters(currentLat, currentLng);
        final distB = b.distanceFromMeters(currentLat, currentLng);
        return distA.compareTo(distB);
      });

    return sorted.sublist(0, maxActive);
  }
}
