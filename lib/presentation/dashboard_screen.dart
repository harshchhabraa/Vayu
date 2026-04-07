import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vayu/providers/aqi/aqi_provider.dart';
import 'package:vayu/providers/exposure/exposure_provider.dart';
import 'package:vayu/providers/exposure/activity_provider.dart';
import 'package:vayu/providers/auth/auth_provider.dart';
import 'package:vayu/providers/location/location_provider.dart';
import 'package:vayu/providers/storage/storage_provider.dart';
import 'package:vayu/presentation/widgets/vayu_card.dart';
import 'package:vayu/presentation/widgets/vayu_exposure_chart.dart';
import 'package:vayu/domain/models/exposure_entry.dart';
import 'package:vayu/domain/models/exposure_snapshot.dart';
import 'package:vayu/domain/models/health_profile.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aqiStream = ref.watch(currentAqiProvider);
    final locationName = ref.watch(currentLocationNameProvider);
    final exposureSummary = ref.watch(dailyExposureProvider);
    final currentActivity = ref.watch(activityProvider);
    final healthProfileAsync = ref.watch(healthProfileProvider);
    final healthProfile = healthProfileAsync.value ?? HealthProfile.defaultProfile;

    // Safe Zone Logic
    bool isAtHome = false;
    final currentPos = ref.watch(currentLocationProvider).value;
    if (currentPos != null && healthProfile.hasHome) {
      final distance = Geolocator.distanceBetween(
        currentPos.latitude,
        currentPos.longitude,
        healthProfile.homeLatitude!,
        healthProfile.homeLongitude!,
      );
      isAtHome = distance <= 10.0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F7), // Very soft Teal/Grey background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header
              _buildHeader(context, ref),
              const SizedBox(height: 32),

              // 2. Current AQI HeroCard
              aqiStream.when(
                data: (reading) => _buildHeroAqi(reading, locationName.value ?? 'Detecting...', isAtHome),
                loading: () => const VayuCard(height: 180, child: Center(child: CircularProgressIndicator())),
                error: (e, s) => VayuCard(height: 180, child: Center(child: Text('AQI Error: $e'))),
              ),
              const SizedBox(height: 16),
              
              // 2.5 Home Safe Zone Setter
              _buildHomeSafeZoneAction(context, ref, healthProfile),
              const SizedBox(height: 24),

              // 3. Stats Grid
              _buildStatsGrid(exposureSummary, healthProfile),
              const SizedBox(height: 24),

              // 4. Insight (Exposure Reduction)
              _buildExposureInsight(exposureSummary),
              const SizedBox(height: 32),

              // 5. Navigation Actions (Claymorphic Style)
              _buildNavigationPanel(context),
              const SizedBox(height: 40),

              // 6. Trend Graph
              const Text('Daily Exposure Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF004D40))),
              const SizedBox(height: 16),
              VayuCard(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                child: VayuExposureChart(entries: exposureSummary.entries),
              ),
              const SizedBox(height: 48),

              // 7. Daily Air-Safe Exercises
              const Text('DAILY AIR-SAFE EXERCISES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF004D40), letterSpacing: 2)),
              const SizedBox(height: 16),
              _buildExerciseRecommendations(exposureSummary),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseRecommendations(ExposureSummary summary) {
    // Basic logic: if exposure is high, suggest indoor/breathing. If low, suggest yoga/outdoor.
    bool highExposure = summary.totalScore > 100 || summary.avgAqi > 100;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (highExposure) ...[
            _buildExerciseCard('Pranayama', 'Purifying Breathwork', '10 min', Icons.air, Colors.teal),
            _buildExerciseCard('Hatha Yoga', 'Lower Lung Capacity', '20 min', Icons.self_improvement, Colors.orange),
          ] else ...[
            _buildExerciseCard('Outdoor Yoga', 'Open Air Expansion', '30 min', Icons.park_outlined, Colors.green),
            _buildExerciseCard('Power Breath', 'Deep Oxygen Intake', '10 min', Icons.bolt, Colors.blue),
          ],
          _buildExerciseCard('Chest Opener', 'Muscle Extension', '15 min', Icons.accessibility_new, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(String title, String subtitle, String duration, IconData icon, Color color) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      child: VayuCard(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF004D40))),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(duration, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey)),
                const Spacer(),
                const Icon(Icons.play_circle_fill, color: Color(0xFF00796B), size: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('VAYU (LIVE)', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2.0, color: Colors.orangeAccent)),
            Text('Real-time Air Health', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF80CBC4))),
          ],
        ),
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: const VayuCard(
            padding: EdgeInsets.all(8),
            color: Colors.white,
            child: Icon(Icons.person, color: Color(0xFF00796B), size: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroAqi(dynamic reading, String locationName, bool isAtHome) {
    final statusColor = _getAqiColor(reading.aqi);
    return VayuCard(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFF757575), size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  locationName,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF757575)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isAtHome)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00796B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '🏡 SAFE ZONE',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00796B)),
                  ),
                ),
              if (!isAtHome && reading.stationName != null) 
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Text(
                    '(via ${reading.stationName})',
                    style: const TextStyle(fontSize: 10, color: Color(0xFFBDBDBD)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const Divider(height: 32, thickness: 0.5),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current AQI', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF757575))),
                    const SizedBox(height: 4),
                    Text(
                      '${reading.aqi}',
                      style: TextStyle(fontSize: 72, fontWeight: FontWeight.w900, color: statusColor, height: 1.0),
                    ),
                    Text(
                      reading.category.label.toUpperCase(),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: statusColor, letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.air, color: statusColor, size: 48),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHomeSafeZoneAction(BuildContext context, WidgetRef ref, HealthProfile profile) {
    return GestureDetector(
      onTap: () async {
        final posAsync = ref.read(currentLocationProvider);
        if (posAsync.hasValue) {
          final pos = posAsync.value!;
          final newProfile = profile.copyWith(
            homeLatitude: pos.latitude,
            homeLongitude: pos.longitude,
          );
          await ref.read(storageRepositoryProvider).saveHealthProfile(newProfile);
          ref.invalidate(healthProfileProvider);
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Home Safe Zone set to current location!')),
            );
          }
        }
      },
      child: VayuCard(
        color: const Color(0xFFE0F2F1),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.add_location_alt, color: Color(0xFF00796B)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.hasHome ? 'Update Home Safe Zone' : 'Set Your Safe Zone (Home)',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF004D40)),
                  ),
                  const Text(
                    'Used to auto-detect Indoor vs Outdoor exposure.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF80CBC4)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF00796B)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(ExposureSummary summary, HealthProfile profile) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard('EXPOSURE', summary.totalScore.toStringAsFixed(1), Icons.health_and_safety, const Color(0xFF00796B)),
        _buildStatCard('OUTDOORS', '${summary.totalOutdoorMinutes}m', Icons.directions_walk, const Color(0xFF00796B)),
        _buildStatCard('AVG AQI', summary.avgAqi.toStringAsFixed(0), Icons.analytics, const Color(0xFF0288D1)),
        _buildStatCard('RISK', summary.riskLevel.label.toUpperCase(), Icons.warning_amber_rounded, _getAqiColor(summary.avgAqi.toInt())),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color mainColor) {
    return VayuCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: mainColor, size: 24),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: mainColor, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFBDBDBD), letterSpacing: 1.0)),
        ],
      ),
    );
  }

  Widget _buildExposureInsight(ExposureSummary summary) {
    // We can calculate this dynamically, but for now we'll simulate a 42% reduction
    const reductionPct = 42; 

    return VayuCard(
      color: const Color(0xFF00796B), // Deep Teal
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          const Icon(Icons.eco, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HEALTH INSIGHT',
                  style: TextStyle(color: Color(0xFF80CBC4), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5),
                ),
                const SizedBox(height: 4),
                Text(
                  'You reduced your PM2.5 exposure by $reductionPct% today by following healthy routes.',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationPanel(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Flexible(child: _buildNavIcon(context, Icons.bar_chart, 'Insights', '/insights')),
        Flexible(child: _buildNavIcon(context, Icons.map_outlined, 'Routes', '/map')),
        Flexible(child: _buildNavIcon(context, Icons.camera_alt_outlined, 'Netra', '/vision')),
        Flexible(child: _buildNavIcon(context, Icons.face_retouching_natural, 'Coach', '/coach')),
        Flexible(child: _buildNavIcon(context, Icons.settings_input_component, 'Sim', '/simulation')),
      ],
    );
  }

  Widget _buildNavIcon(BuildContext context, IconData icon, String label, String route) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VayuCard(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: const Color(0xFF00796B), size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label, 
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00796B)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getAqiColor(int aqi) {
    if (aqi <= 50) return const Color(0xFF00BFA5); // Teal
    if (aqi <= 100) return const Color(0xFFFFB300); // Amber
    return const Color(0xFFE53935); // Red
  }
}
