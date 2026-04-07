import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vayu/domain/interfaces/i_location_repository.dart';
import 'package:vayu/data/repositories/fused_location_repository.dart';

final locationRepositoryProvider = Provider<ILocationRepository>((ref) {
  return FusedLocationRepository();
});

final locationPermissionProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(locationRepositoryProvider);
  return await repo.requestPermissions();
});

final currentLocationProvider = StreamProvider<PositionData?>((ref) async* {
  final hasPermissionAsync = ref.watch(locationPermissionProvider);
  
  if (hasPermissionAsync.hasValue) {
    if (hasPermissionAsync.value!) {
      final repo = ref.watch(locationRepositoryProvider);
      yield* repo.watchPosition().map((p) => p as PositionData?);
    } else {
      // Permission denied - return null instead of throwing
      yield null;
    }
  } else {
    yield null;
  }
});
