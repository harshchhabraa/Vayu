import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vayu/providers/routing/routing_provider.dart';
import 'package:vayu/providers/location/location_provider.dart';
import 'package:vayu/domain/models/vayu_route.dart';

class RouteScreen extends ConsumerStatefulWidget {
  const RouteScreen({super.key});

  @override
  ConsumerState<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends ConsumerState<RouteScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(routingProvider);
    final locationAsync = ref.watch(currentLocationProvider);

    // Initial positioning based on user location
    locationAsync.whenData((pos) {
      if (!_initialized) {
        _initialized = true;
        _mapController.move(LatLng(pos.latitude, pos.longitude), 13);
      }
    });

    ref.listen<RoutingState>(routingProvider, (previous, next) {
      if (next.routes.isNotEmpty && (previous?.routes ?? []).isEmpty) {
        if (_initialized) {
          final bounds = LatLngBounds.fromPoints(next.routes.first.polyline);
          _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(80)));
        }
      } else if (next.selectedRoute != null && previous?.selectedRoute != next.selectedRoute) {
        final bounds = LatLngBounds.fromPoints(next.selectedRoute!.polyline);
        _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(80)));
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // 1. OpenStreetMap Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(40.7128, -74.0060),
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.vayu.app',
              ),
              
              // 2. AQI Corridor Zones (Heatmap effect)
              ...state.routes.map((route) {
                final isSelected = state.selectedRoute == route;
                if (!isSelected && state.selectedRoute != null) return const SizedBox.shrink();

                return CircleLayer(
                  circles: route.samples.map((s) => CircleMarker(
                    point: s.location,
                    radius: 120, // Large radius for "zone" effect
                    useRadiusInMeter: true,
                    color: _getHealthColor(s.aqi.toDouble()).withOpacity(0.15),
                    borderStrokeWidth: 0,
                  )).toList(),
                );
              }),

              // 3. Polyline Layers (Color-coded by Health)
              PolylineLayer(
                polylines: state.routes.map((route) {
                  final isSelected = state.selectedRoute == route;
                  return Polyline(
                    points: route.polyline,
                    strokeWidth: isSelected ? 6.0 : 3.5,
                    color: _getHealthColor(route.averageAqi).withOpacity(isSelected ? 1.0 : 0.4),
                  );
                }).toList(),
              ),

              // 4. Start/End Markers
              if (state.routes.isNotEmpty)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: state.routes.first.polyline.first,
                      child: const Icon(Icons.location_on, color: Colors.blue, size: 30),
                    ),
                    Marker(
                      point: state.routes.first.polyline.last,
                      child: const Icon(Icons.flag, color: Colors.red, size: 30),
                    ),
                  ],
                ),
            ],
          ),

          // 5. Glassmorphic Search Header
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: _buildSearchHeader(),
          ),

          // 6. Loading State Overlay
          if (state.isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF3CD3AD))),

          // 7. Bottom Route Comparison Tray
          if (state.routes.isNotEmpty)
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildRouteComparisonTray(state),
            ),
            
          // Error Message
          if (state.errorMessage != null)
             Positioned(
               bottom: 300,
               left: 20,
               right: 20,
               child: Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(color: Colors.red.withOpacity(0.9), borderRadius: BorderRadius.circular(12)),
                 child: Text(state.errorMessage!, style: const TextStyle(color: Colors.white, fontSize: 13), textAlign: TextAlign.center),
               ),
             ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    final travelMode = ref.watch(routingProvider).travelMode;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildSearchField(_startController, 'Starting Point', Icons.my_location)),
              IconButton(
                icon: const Icon(Icons.gps_fixed, color: Color(0xFF00695C)),
                onPressed: () async {
                  final loc = await ref.read(currentLocationProvider.future);
                  _startController.text = '${loc.latitude}, ${loc.longitude}';
                  setState(() {});
                },
              ),
            ]
          ),
          const SizedBox(height: 10),
          _buildSearchField(_endController, 'Where to?', Icons.search),
          const SizedBox(height: 12),
          ToggleButtons(
            borderRadius: BorderRadius.circular(12),
            isSelected: [
              travelMode == 'driving-car',
              travelMode == 'foot-walking',
              travelMode == 'cycling-regular'
            ],
            onPressed: (index) {
              final modes = ['driving-car', 'foot-walking', 'cycling-regular'];
              ref.read(routingProvider.notifier).setTravelMode(modes[index]);
            },
            children: const [
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Row(children: [Icon(Icons.directions_car), SizedBox(width: 4), Text('Drive')])),
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Row(children: [Icon(Icons.directions_walk), SizedBox(width: 4), Text('Walk')])),
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Row(children: [Icon(Icons.directions_bike), SizedBox(width: 4), Text('Cycle')])),
            ]
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              if (_startController.text.isNotEmpty && _endController.text.isNotEmpty) {
                 ref.read(routingProvider.notifier).findRoutesByAddress(
                   _startController.text, 
                   _endController.text
                 );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00695C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 45),
            ),
            child: const Text('SEARCH HEALTHY ROUTES'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(TextEditingController controller, String hint, IconData icon) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.length < 3) {
          return const Iterable<String>.empty();
        }
        final ors = ref.read(orsServiceProvider);
        return await ors.autocompleteLocation(textEditingValue.text);
      },
      onSelected: (String selection) {
        controller.text = selection;
      },
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        // Keep persistent controller synced
        if (textEditingController.text != controller.text && focusNode.hasFocus == false) {
           textEditingController.text = controller.text;
        }
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          onChanged: (val) => controller.text = val,
          onSubmitted: (String value) => onFieldSubmitted(),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.blueGrey, size: 20),
            filled: true,
            fillColor: Colors.grey.withOpacity(0.05),
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 250, 
                maxWidth: MediaQuery.of(context).size.width - 32
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: Colors.blueGrey, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text(option, style: const TextStyle(fontWeight: FontWeight.w500))),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRouteComparisonTray(RoutingState state) {
    return Container(
      height: 280,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'HEALTH OPTIMIZED ROUTES',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Color(0xFF004D40), fontSize: 13),
              ),
              if (state.improvementPct > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    '${state.improvementPct}% LESS POLLUTION',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: state.routes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final route = state.routes[index];
                final isSelected = state.selectedRoute == route;
                
                return GestureDetector(
                  onTap: () => ref.read(routingProvider.notifier).selectRoute(route),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF3CD3AD).withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? const Color(0xFF3CD3AD) : Colors.transparent),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(index == 0 ? Icons.eco : Icons.directions_walk, 
                               color: isSelected ? _getHealthColor(route.averageAqi) : Colors.grey),
                            const SizedBox(width: 16),
                            Expanded(child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(route.summary, style: const TextStyle(fontWeight: FontWeight.bold)),
                                 Text(route.healthAssessment, style: TextStyle(color: _getHealthColor(route.averageAqi), fontSize: 12)),
                               ],
                            )),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                 Text('${route.duration.inMinutes} MIN', style: const TextStyle(fontWeight: FontWeight.bold)),
                                 Text('${route.distanceKm.toStringAsFixed(1)} KM', style: const TextStyle(color: Colors.black45, fontSize: 11)),
                              ],
                            )
                          ],
                        ),
                        if (isSelected && route.navigationSteps.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => _startNavigation(route),
                            icon: const Icon(Icons.navigation),
                            label: const Text('START NAVIGATION'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _getHealthColor(route.averageAqi),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          )
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Color _getHealthColor(double aqi) {
    if (aqi <= 50) return const Color(0xFF3CD3AD); // Fresh Teal
    if (aqi <= 100) return const Color(0xFFFFA726); // Warning Orange
    return const Color(0xFFE53935); // Danger Red
  }

  void _startNavigation(VayuRoute route) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Turn-by-Turn Navigation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Divider(height: 30),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: route.navigationSteps.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, i) {
                        final step = route.navigationSteps[i];
                        return ListTile(
                          leading: const Icon(Icons.turn_right, color: Colors.blueGrey),
                          title: Text(step.instruction, style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text('${step.distanceMeters.toStringAsFixed(0)}m • ${(step.durationSeconds/60).ceil()} min'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
