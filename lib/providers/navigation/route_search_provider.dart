import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:vayu/domain/models/scored_route.dart';
import 'package:vayu/providers/navigation/route_provider.dart';
import 'package:vayu/providers/location/location_provider.dart';
import 'package:vayu/core/config/vayu_config.dart';
import 'package:vayu/providers/aqi/aqi_provider.dart';
import 'package:vayu/domain/interfaces/i_route_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class RouteSearchState {
  final String origin;
  final String destination;
  final (double, double)? originCoords;
  final (double, double)? destCoords;
  final bool isLoading;
  final String? error;
  final List<ScoredRoute> routes;
  final ScoredRoute? selectedRoute;
  final List<Map<String, dynamic>> suggestions;
  final TravelMode selectedMode;

  RouteSearchState({
    this.origin = '',
    this.destination = '',
    this.originCoords,
    this.destCoords,
    this.isLoading = false,
    this.error,
    this.routes = const [],
    this.selectedRoute,
    this.suggestions = const [],
    this.selectedMode = TravelMode.drive,
  });

  RouteSearchState copyWith({
    String? origin,
    String? destination,
    (double, double)? originCoords,
    (double, double)? destCoords,
    bool? isLoading,
    String? error,
    List<ScoredRoute>? routes,
    ScoredRoute? selectedRoute,
    List<Map<String, dynamic>>? suggestions,
    TravelMode? selectedMode,
  }) {
    return RouteSearchState(
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      originCoords: originCoords ?? this.originCoords,
      destCoords: destCoords ?? this.destCoords,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      routes: routes ?? this.routes,
      selectedRoute: selectedRoute ?? this.selectedRoute,
      suggestions: suggestions ?? this.suggestions,
      selectedMode: selectedMode ?? this.selectedMode,
    );
  }
}

class RouteSearchNotifier extends StateNotifier<RouteSearchState> {
  final Ref _ref;

  RouteSearchNotifier(this._ref) : super(RouteSearchState());

  void updateOrigin(String value) {
    state = state.copyWith(origin: value);
    if (value.length > 2) fetchSuggestions(value);
  }

  void updateDestination(String value) {
    state = state.copyWith(destination: value);
    if (value.length > 2) fetchSuggestions(value);
  }
  
  void clearSuggestions() => state = state.copyWith(suggestions: []);

  void setTravelMode(TravelMode mode) {
    state = state.copyWith(selectedMode: mode);
    if (state.originCoords != null && state.destCoords != null) {
      searchRoutes();
    }
  }

  void selectRoute(ScoredRoute route) => state = state.copyWith(selectedRoute: route);

  Future<void> fetchSuggestions(String text) async {
    try {
      final dio = _ref.read(dioProvider);
      final apiKey = VayuConfig.orsKey;
      final res = await dio.get(
        'https://api.openrouteservice.org/geocode/autocomplete',
        queryParameters: {'api_key': apiKey, 'text': text, 'size': 5},
      );
      if (res.data['features'] != null) {
        final List<Map<String, dynamic>> suggestions = (res.data['features'] as List).map((f) {
          final props = f['properties'];
          final coords = f['geometry']['coordinates'];
          return {
            'label': props['label'] ?? props['name'],
            'lat': (coords[1] as num).toDouble(),
            'lon': (coords[0] as num).toDouble(),
          };
        }).toList();
        state = state.copyWith(suggestions: suggestions);
      }
    } catch (_) {
      // Silent fail
    }
  }

  void selectLocation(Map<String, dynamic> loc, bool isOrigin) {
    if (isOrigin) {
      state = state.copyWith(
        origin: loc['label'],
        originCoords: (loc['lat'], loc['lon']),
        suggestions: [],
      );
    } else {
      state = state.copyWith(
        destination: loc['label'],
        destCoords: (loc['lat'], loc['lon']),
        suggestions: [],
      );
    }
  }

  Future<void> useCurrentLocation() async {
    state = state.copyWith(isLoading: true);
    try {
      final pos = _ref.read(currentLocationProvider).value;
      if (pos == null) throw Exception('Location not available');
      
      final String apiKey = VayuConfig.orsKey;
      final dio = _ref.read(dioProvider);

      final response = await dio.get(
        'https://api.openrouteservice.org/geocode/reverse',
        queryParameters: {
          'api_key': apiKey,
          'point.lat': pos.latitude,
          'point.lon': pos.longitude,
          'size': 1,
        },
      );

      String label = 'Current Location';
      if (response.statusCode == 200 && response.data['features'].isNotEmpty) {
        label = response.data['features'][0]['properties']['label'] ?? 'Current Location';
      }

      state = state.copyWith(
        origin: label, 
        originCoords: (pos.latitude, pos.longitude),
        isLoading: false
      );
    } catch (e) {
      state = state.copyWith(error: 'Could not get name for current location', isLoading: false);
    }
  }

  Future<void> searchRoutes() async {
    if (state.origin.isEmpty || state.destination.isEmpty) {
      state = state.copyWith(error: 'Please enter both origin and destination');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final String apiKey = VayuConfig.orsKey;
      final dio = _ref.read(dioProvider);

      double startLat = state.originCoords?.$1 ?? 0;
      double startLng = state.originCoords?.$2 ?? 0;
      double endLat = state.destCoords?.$1 ?? 0;
      double endLng = state.destCoords?.$2 ?? 0;

      // 1. Resolve Coords
      if (state.originCoords == null) {
        final originRes = await dio.get(
          'https://api.openrouteservice.org/geocode/search',
          queryParameters: {'api_key': apiKey, 'text': state.origin, 'size': 1},
        );
        if (originRes.data['features'].isEmpty) throw Exception('Origin not found');
        startLng = (originRes.data['features'][0]['geometry']['coordinates'][0] as num).toDouble();
        startLat = (originRes.data['features'][0]['geometry']['coordinates'][1] as num).toDouble();
      }

      if (state.destCoords == null) {
        final destRes = await dio.get(
          'https://api.openrouteservice.org/geocode/search',
          queryParameters: {'api_key': apiKey, 'text': state.destination, 'size': 1},
        );
        if (destRes.data['features'].isEmpty) throw Exception('Destination not found');
        endLng = (destRes.data['features'][0]['geometry']['coordinates'][0] as num).toDouble();
        endLat = (destRes.data['features'][0]['geometry']['coordinates'][1] as num).toDouble();
      }

      final repo = _ref.read(routeRepositoryProvider);
      final engine = _ref.read(navigationEngineProvider);
      final aqiRepo = _ref.read(aqiRepositoryProvider);

      // 2. Fetch routes for MULTIPLE MODES in parallel
      final List<TravelMode> modes = [TravelMode.drive, TravelMode.bicycle, TravelMode.walk];
      final List<Future<List<ScoredRoute>>> routeFutures = modes.map((m) => repo.computeRoutes(
        originLat: startLat,
        originLng: startLng,
        destLat: endLat,
        destLng: endLng,
        mode: m,
      )).toList();

      final List<List<ScoredRoute>> resultsPerMode = await Future.wait(routeFutures);
      
      List<ScoredRoute> allRoutes = [];
      for (int i = 0; i < modes.length; i++) {
        final modeRoutes = resultsPerMode[i].map((r) => r.copyWith(mode: modes[i])).toList();
        allRoutes.addAll(modeRoutes);
      }

      // 3. Correlate and Rank ALL routes together
      final correlated = await engine.correlateAqi(allRoutes, aqiRepo);
      final ranked = engine.rankRoutes(correlated);

      if (ranked.isEmpty) {
        state = state.copyWith(error: 'No routes found for these points.', isLoading: false);
        return;
      }

      state = state.copyWith(
        originCoords: (startLat, startLng),
        destCoords: (endLat, endLng),
        routes: ranked, 
        selectedRoute: ranked.first,
        isLoading: false
      );
    } catch (e) {
      state = state.copyWith(error: 'Search error: $e', isLoading: false);
    }
  }
}

final routeSearchProvider = StateNotifierProvider<RouteSearchNotifier, RouteSearchState>((ref) {
  return RouteSearchNotifier(ref);
});
