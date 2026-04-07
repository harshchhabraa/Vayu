import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:vayu/providers/navigation/route_search_provider.dart';
import 'package:vayu/domain/models/scored_route.dart';
import 'package:vayu/presentation/widgets/vayu_card.dart';

class MapRoutesScreen extends ConsumerStatefulWidget {
  const MapRoutesScreen({super.key});

  @override
  ConsumerState<MapRoutesScreen> createState() => _MapRoutesScreenState();
}

class _MapRoutesScreenState extends ConsumerState<MapRoutesScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destController = TextEditingController();

  final FocusNode _originFocus = FocusNode();
  final FocusNode _destFocus = FocusNode();

  @override
  void dispose() {
    _originController.dispose();
    _destController.dispose();
    _originFocus.dispose();
    _destFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(routeSearchProvider);
    final searchNotifier = ref.read(routeSearchProvider.notifier);

    // Sync controllers if changed from provider (e.g., GPS button)
    if (_originController.text != searchState.origin && !searchState.isLoading) {
      _originController.text = searchState.origin;
    }

    // Automatically fit bounds when route changes
    ref.listen(routeSearchProvider.select((s) => s.selectedRoute), (prev, next) {
      if (next != null && next.aqiSamples.isNotEmpty) {
        final points = next.aqiSamples.map((s) => LatLng(s.latitude, s.longitude)).toList();
        final bounds = LatLngBounds.fromPoints(points);
        _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(80)));
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Live Interactive Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(28.6139, 77.2090),
              initialZoom: 13.0,
              onTap: (_, __) => searchNotifier.clearSuggestions(),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.vayu.app',
              ),
              
              // Draw Routes
              if (searchState.selectedRoute != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: searchState.selectedRoute!.aqiSamples.map((s) => LatLng(s.latitude, s.longitude)).toList(),
                      strokeWidth: 6.0,
                      color: _getRouteColor(searchState.selectedRoute!.avgAqi),
                    ),
                  ],
                ),

              // Markers
              MarkerLayer(
                markers: [
                  if (searchState.originCoords != null)
                    Marker(
                      point: LatLng(searchState.originCoords!.$1, searchState.originCoords!.$2),
                      width: 40, height: 40,
                      child: const Icon(Icons.my_location, color: Color(0xFF00695C), size: 30),
                    ),
                  if (searchState.destCoords != null)
                    Marker(
                      point: LatLng(searchState.destCoords!.$1, searchState.destCoords!.$2),
                      width: 40, height: 40,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 35),
                    ),
                ],
              ),
            ],
          ),

          // 2. Dual Search Bars with Suggestions Overlay
          Positioned(
            top: 60, left: 16, right: 16,
            child: Column(
              children: [
                _buildSearchInput(
                  controller: _originController,
                  focusNode: _originFocus,
                  hint: 'Origin',
                  icon: Icons.circle_outlined,
                  onChanged: (val) => searchNotifier.updateOrigin(val),
                  onTrailingTap: searchNotifier.useCurrentLocation,
                ),
                const SizedBox(height: 8),
                _buildSearchInput(
                  controller: _destController,
                  focusNode: _destFocus,
                  hint: 'Enter Destination',
                  icon: Icons.place,
                  onChanged: (val) => searchNotifier.updateDestination(val),
                  onTrailingTap: () {
                    searchNotifier.clearSuggestions();
                    searchNotifier.searchRoutes();
                  },
                  isPrimary: true,
                ),
                
                // Suggestions List Overlay
                if (searchState.suggestions.isNotEmpty)
                  Material(
                    color: Colors.transparent,
                    elevation: 10,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      margin: const EdgeInsets.only(top: 4),
                      constraints: const BoxConstraints(maxHeight: 300),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: searchState.suggestions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final sug = searchState.suggestions[index];
                          return ListTile(
                            leading: const Icon(Icons.location_on_outlined, size: 20, color: Color(0xFF00695C)),
                            title: Text(sug['label'], style: const TextStyle(fontSize: 14)),
                            onTap: () {
                              final isOrigin = _originFocus.hasFocus;
                              searchNotifier.selectLocation(sug, isOrigin);
                              if (isOrigin) {
                                _originController.text = sug['label'];
                                _originFocus.unfocus();
                              } else {
                                _destController.text = sug['label'];
                                _destFocus.unfocus();
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 3. Back Button
          Positioned(
            top: 60, left: 24,
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.9),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF00695C)),
                onPressed: () => context.pop(),
              ),
            ),
          ),

          // 4. Route Comparison & Insights Panel
          if (searchState.routes.isNotEmpty)
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: DraggableScrollableSheet(
                  initialChildSize: 0.35,
                  minChildSize: 0.15,
                  maxChildSize: 0.6,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
                      ),
                      child: DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)))),
                            const TabBar(
                              labelColor: Color(0xFF00695C),
                              indicatorColor: Color(0xFF00695C),
                              tabs: [
                                Tab(text: 'Compare Routes'),
                                Tab(text: 'Directions'),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  // TAB 1: Route Comparison
                                  ListView(
                                    controller: scrollController,
                                    padding: const EdgeInsets.all(24),
                                    children: [
                                      ...searchState.routes.map((route) {
                                        final isSelected = searchState.selectedRoute == route;
                                        final isBest = route == searchState.routes.first;
                                        
                                        IconData modeIcon = Icons.directions_car;
                                        if (route.mode == TravelMode.walk) modeIcon = Icons.directions_walk;
                                        if (route.mode == TravelMode.bicycle) modeIcon = Icons.directions_bike;

                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          child: InkWell(
                                            onTap: () => searchNotifier.selectRoute(route),
                                            child: VayuCard(
                                              color: isSelected ? const Color(0xFFE0F2F1) : Colors.white,
                                              padding: const EdgeInsets.all(16),
                                              showShadow: !isSelected,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  if (isBest)
                                                    Container(
                                                      margin: const EdgeInsets.only(bottom: 8),
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF004D40),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: const Text(
                                                        '🏆 VAYU BEST CHOICE',
                                                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                      ),
                                                    ),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Icon(modeIcon, size: 20, color: const Color(0xFF00695C)),
                                                          const SizedBox(width: 8),
                                                          Text(
                                                            '${route.mode?.name.toUpperCase() ?? 'ROUTE'} - ${route.formattedDuration}', 
                                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
                                                          ),
                                                        ],
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: _getRouteColor(route.avgAqi).withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Text(
                                                          route.formattedPercentage,
                                                          style: TextStyle(
                                                            color: _getRouteColor(route.avgAqi),
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    route.summary ?? 'Standard healthy route',
                                                    style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Row(
                                                    children: [
                                                      _buildSmallStat(Icons.straighten, route.formattedDistance),
                                                      const SizedBox(width: 16),
                                                      _buildSmallStat(Icons.eco_outlined, 'Eco: ${(route.greeneryLevel * 100).toInt()}%'),
                                                      const SizedBox(width: 16),
                                                      _buildSmallStat(Icons.traffic_outlined, 'Traffic: ${(route.trafficLevel * 100).toInt()}%'),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                  // TAB 2: Directions
                                  if (searchState.selectedRoute != null)
                                    ListView.separated(
                                      controller: scrollController,
                                      padding: const EdgeInsets.all(24),
                                      itemCount: searchState.selectedRoute!.steps.length,
                                      separatorBuilder: (_, __) => const Divider(height: 24),
                                      itemBuilder: (context, index) {
                                        final step = searchState.selectedRoute!.steps[index];
                                        return Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 14,
                                              backgroundColor: const Color(0xFFE0F2F1),
                                              child: Text('${index + 1}', style: const TextStyle(fontSize: 12, color: Color(0xFF00695C))),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(step.instruction, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                  Text(
                                                    '${step.distanceMeters}m • ${step.durationSeconds}s',
                                                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    )
                                  else
                                    const Center(child: Text('Select a route to see directions')),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          if (searchState.isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF00695C))),
          
          if (searchState.error != null)
            Positioned(
              bottom: 100, left: 32, right: 32,
              child: VayuCard(
                color: Colors.red.shade50,
                child: Text(searchState.error!, style: TextStyle(color: Colors.red.shade900)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    required Function(String) onChanged,
    required VoidCallback onTrailingTap,
    bool isPrimary = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF00695C)),
          suffixIcon: IconButton(
            icon: Icon(isPrimary ? Icons.search : Icons.gps_fixed, color: const Color(0xFF00695C)),
            onPressed: onTrailingTap,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildSmallStat(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.black38),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
      ],
    );
  }

  Color _getRouteColor(double aqi) {
    if (aqi < 20) return Colors.green.withOpacity(0.7);
    if (aqi < 50) return Colors.orange.withOpacity(0.7);
    return Colors.red.withOpacity(0.7);
  }
}
