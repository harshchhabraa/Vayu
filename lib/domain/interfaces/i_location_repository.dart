import 'package:equatable/equatable.dart';

abstract class ILocationRepository {
  /// Stream of user's current position.
  Stream<PositionData> watchPosition();

  /// Get the last known position immediately.
  Future<PositionData?> getLastKnownPosition();

  /// Check and request location permissions.
  Future<bool> requestPermissions();
}

class PositionData extends Equatable {
  final double latitude;
  final double longitude;
  final double speed;
  final DateTime timestamp;

  PositionData({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
        latitude.toStringAsFixed(4), // About 11m precision
        longitude.toStringAsFixed(4),
      ];
}
