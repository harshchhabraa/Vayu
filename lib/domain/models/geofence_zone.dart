import 'package:equatable/equatable.dart';

/// A geofence zone around a known location.
class GeofenceZone extends Equatable {
  const GeofenceZone({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.zoneType,
    this.isAutoDetected = false,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final GeofenceZoneType zoneType;
  final bool isAutoDetected;

  /// Distance from a point in meters (Haversine approximation).
  double distanceFromMeters(double lat, double lng) {
    const double earthRadius = 6371000; // meters
    final double dLat = _toRadians(lat - latitude);
    final double dLng = _toRadians(lng - longitude);
    final double a =
        _sin2(dLat / 2) +
        _cos(latitude) * _cos(lat) * _sin2(dLng / 2);
    final double c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return earthRadius * c;
  }

  bool containsPoint(double lat, double lng) {
    return distanceFromMeters(lat, lng) <= radiusMeters;
  }

  // Math helpers to avoid dart:math import in domain
  static double _toRadians(double deg) => deg * 3.14159265359 / 180.0;
  static double _sin2(double x) {
    final s = _sinApprox(x);
    return s * s;
  }
  static double _cos(double deg) => _sinApprox(_toRadians(deg) + 1.5707963);
  static double _sinApprox(double x) {
    // Taylor series approximation — sufficient for distance calc
    double x3 = x * x * x;
    double x5 = x3 * x * x;
    return x - x3 / 6.0 + x5 / 120.0;
  }
  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
  static double _atan2(double y, double x) {
    if (x > 0) return _atanApprox(y / x);
    if (x < 0 && y >= 0) return _atanApprox(y / x) + 3.14159265359;
    if (x < 0 && y < 0) return _atanApprox(y / x) - 3.14159265359;
    if (y > 0) return 1.5707963;
    if (y < 0) return -1.5707963;
    return 0;
  }
  static double _atanApprox(double x) {
    // Fast atan approximation
    return x - (x * x * x) / 3 + (x * x * x * x * x) / 5;
  }

  @override
  List<Object?> get props => [id, name, latitude, longitude, radiusMeters, zoneType];
}

enum GeofenceZoneType {
  indoor(label: 'Indoor'),
  outdoor(label: 'Outdoor'),
  transit(label: 'Transit'),
  vehicle(label: 'Vehicle');

  const GeofenceZoneType({required this.label});
  final String label;
}

/// Represents the current geofence state.
class GeofenceState extends Equatable {
  const GeofenceState({
    required this.currentZone,
    required this.isInsideAnyZone,
    required this.speed,
    this.activity,
    this.dwellStartTime,
  });

  final GeofenceZone? currentZone;
  final bool isInsideAnyZone;
  final double speed; // km/h
  final ActivityType? activity;
  final DateTime? dwellStartTime;

  static const GeofenceState unknown = GeofenceState(
    currentZone: null,
    isInsideAnyZone: false,
    speed: 0,
  );

  @override
  List<Object?> get props => [currentZone, isInsideAnyZone, speed, activity];
}

enum ActivityType {
  still,
  walking,
  running,
  cycling,
  driving,
  unknown,
}
