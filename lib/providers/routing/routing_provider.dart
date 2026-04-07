import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:vayu/data/services/ors_service.dart';
import 'package:vayu/data/services/aqi_service.dart';
import 'package:vayu/domain/engines/route_exposure_engine.dart';
import 'package:vayu/domain/models/vayu_route.dart';

// Service/Engine Dependency Injection
final orsServiceProvider = Provider((ref) => OrsService());
final aqiServiceProvider = Provider((ref) => AqiService());
final routeExposureEngineProvider = Provider((ref) {
  final aqiService = ref.watch(aqiServiceProvider);
  return RouteExposureEngine(aqiService);
});

/// State for the Routing Screen
class RoutingState {
  final List<VayuRoute> routes;
  final VayuRoute? selectedRoute;
  final bool isLoading;
  final String? errorMessage;
  final int improvementPct;
  final String? startAddress;
  final String? endAddress;
  final String travelMode;

  RoutingState({
    required this.routes,
    this.selectedRoute,
    this.isLoading = false,
    this.errorMessage,
    this.improvementPct = 0,
    this.startAddress,
    this.endAddress,
    this.travelMode = 'foot-walking',
  });

  RoutingState copyWith({
    List<VayuRoute>? routes,
    VayuRoute? selectedRoute,
    bool? isLoading,
    String? errorMessage,
    int? improvementPct,
    String? startAddress,
    String? endAddress,
    String? travelMode,
  }) {
    return RoutingState(
      routes: routes ?? this.routes,
      selectedRoute: selectedRoute ?? this.selectedRoute,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      improvementPct: improvementPct ?? this.improvementPct,
      startAddress: startAddress ?? this.startAddress,
      endAddress: endAddress ?? this.endAddress,
      travelMode: travelMode ?? this.travelMode,
    );
  }
}

/// Managing the routing logic for the UI.
class RoutingNotifier extends StateNotifier<RoutingState> {
  final OrsService _orsService;
  final RouteExposureEngine _engine;

  RoutingNotifier(this._orsService, this._engine) : super(RoutingState(routes: []));

  void setTravelMode(String mode) {
    state = state.copyWith(travelMode: mode);
    if (state.startAddress != null && state.endAddress != null && 
        state.startAddress!.isNotEmpty && state.endAddress!.isNotEmpty) {
      findRoutesByAddress(state.startAddress!, state.endAddress!);
    }
  }

  Future<void> findOptimalRoutes(LatLng start, LatLng end) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      // 1. Fetch raw candidates from ORS using current profile
      final List<RouteCandidate> candidates = await _orsService.fetchRoutes(start, end, profile: state.travelMode);
      
      // 2. Perform exposure analysis for each candidate
      final List<VayuRoute> analyzedRoutes = [];
      for (int i = 0; i < candidates.length; i++) {
        final analyzed = await _engine.analyzeRoute(candidates[i], 'Route Option ${i + 1}');
        analyzedRoutes.add(analyzed);
      }

      // 3. Rank and score them
      final results = _engine.compareRoutes(analyzedRoutes);
      
      state = state.copyWith(
        isLoading: false,
        routes: results['ranked_routes'],
        selectedRoute: results['optimal_route'],
        improvementPct: results['improvement_pct'],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to compute health routing: $e');
    }
  }

  void selectRoute(VayuRoute route) {
    state = state.copyWith(selectedRoute: route);
  }

  /// High-level method to handle address strings provided by the user.
  Future<void> findRoutesByAddress(String startAddr, String endAddr) async {
    state = state.copyWith(isLoading: true, startAddress: startAddr, endAddress: endAddr, errorMessage: null);
    
    final startLatLng = await _orsService.searchLocation(startAddr);
    final endLatLng = await _orsService.searchLocation(endAddr);

    if (startLatLng != null && endLatLng != null) {
      await findOptimalRoutes(startLatLng, endLatLng);
    } else {
      state = state.copyWith(
        isLoading: false, 
        errorMessage: 'Could not find one or more locations. Please check your spelling.'
      );
    }
  }
}

final routingProvider = StateNotifierProvider<RoutingNotifier, RoutingState>((ref) {
  final orsService = ref.watch(orsServiceProvider);
  final engine = ref.watch(routeExposureEngineProvider);
  return RoutingNotifier(orsService, engine);
});
