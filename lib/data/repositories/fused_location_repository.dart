import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:geolocator/geolocator.dart' as geo;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'package:vayu/domain/interfaces/i_location_repository.dart';

class FusedLocationRepository implements ILocationRepository {
  final StreamController<PositionData> _positionController = StreamController<PositionData>.broadcast();

  FusedLocationRepository() {
    if (!kIsWeb) {
      _initBackgroundGeolocation();
    } else {
      _initWebLocation();
    }
  }

  void _initWebLocation() {
    // 1. Kickstart with Current Position
    geo.Geolocator.getCurrentPosition().then((pos) {
      if (!_positionController.isClosed) {
        _positionController.add(PositionData(
          latitude: pos.latitude,
          longitude: pos.longitude,
          speed: pos.speed,
          timestamp: pos.timestamp,
        ));
      }
    });

    // 2. Continuous Monitoring
    geo.Geolocator.getPositionStream().listen((pos) {
      if (!_positionController.isClosed) {
        _positionController.add(PositionData(
          latitude: pos.latitude,
          longitude: pos.longitude,
          speed: pos.speed,
          timestamp: pos.timestamp,
        ));
      }
    });
  }

  void _initBackgroundGeolocation() {
    bg.BackgroundGeolocation.onLocation((bg.Location location) {
      _positionController.add(PositionData(
        latitude: location.coords.latitude,
        longitude: location.coords.longitude,
        speed: location.coords.speed,
        timestamp: DateTime.parse(location.timestamp),
      ));
    });

    bg.BackgroundGeolocation.ready(bg.Config(
      desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
      distanceFilter: 50.0,
      stopOnTerminate: false,
      startOnBoot: true,
      debug: false,
      logLevel: bg.Config.LOG_LEVEL_OFF,
    )).then((bg.State state) {
      if (!state.enabled) {
        bg.BackgroundGeolocation.start();
      }
    });
  }

  @override
  Stream<PositionData> watchPosition() {
    return _positionController.stream;
  }

  @override
  Future<PositionData?> getLastKnownPosition() async {
    if (kIsWeb) {
      try {
        final pos = await geo.Geolocator.getCurrentPosition(
          desiredAccuracy: geo.LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
        return PositionData(
          latitude: pos.latitude,
          longitude: pos.longitude,
          speed: pos.speed,
          timestamp: pos.timestamp,
        );
      } catch (e) {
        return null;
      }
    }

    try {
      final location = await bg.BackgroundGeolocation.getCurrentPosition(
        timeout: 5,
        samples: 1,
        desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
      );
      return PositionData(
        latitude: location.coords.latitude,
        longitude: location.coords.longitude,
        speed: location.coords.speed,
        timestamp: DateTime.parse(location.timestamp),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> requestPermissions() async {
    if (kIsWeb) {
      final status = await geo.Geolocator.requestPermission();
      return status == geo.LocationPermission.always || 
             status == geo.LocationPermission.whileInUse;
    }

    final status = await bg.BackgroundGeolocation.requestPermission();
    return status == bg.ProviderChangeEvent.AUTHORIZATION_STATUS_ALWAYS ||
           status == bg.ProviderChangeEvent.AUTHORIZATION_STATUS_WHEN_IN_USE;
  }
}
