import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vayu/domain/engines/simulation_engine.dart';
import 'package:vayu/domain/engines/exposure_engine.dart';
import 'package:vayu/domain/engines/forecast_generator.dart';
import 'package:vayu/domain/models/simulation_scenario.dart';
import 'package:vayu/domain/models/exposure_entry.dart';
import 'package:vayu/domain/models/health_profile.dart';
import 'package:vayu/domain/models/forecast_point.dart';
import 'package:vayu/providers/aqi/aqi_provider.dart';
import 'package:vayu/providers/exposure/exposure_provider.dart';
import 'package:vayu/presentation/widgets/vayu_background.dart';
import 'package:vayu/presentation/widgets/vayu_card.dart';
import 'package:vayu/presentation/widgets/vayu_button.dart';
import 'package:vayu/presentation/widgets/vayu_comparison_chart.dart';
import 'package:vayu/presentation/widgets/vayu_deterioration_chart.dart';
import 'package:vayu/presentation/widgets/atmosphere_overlay.dart';

enum BehaviorScenario { stayIndoor, outdoorExercise, motorizedTransit, activeTransit }

extension BehaviorScenarioExtension on BehaviorScenario {
  String get label {
    switch (this) {
      case BehaviorScenario.stayIndoor: return 'STAY INDOOR';
      case BehaviorScenario.outdoorExercise: return 'OUTDOOR EXERCISE';
      case BehaviorScenario.motorizedTransit: return 'MOTORIZED TRANSIT';
      case BehaviorScenario.activeTransit: return 'ACTIVE TRANSIT';
    }
  }
}

class SimulationScreen extends ConsumerStatefulWidget {
  const SimulationScreen({super.key});

  @override
  ConsumerState<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends ConsumerState<SimulationScreen> {
  BehaviorScenario _scenario = BehaviorScenario.stayIndoor;
  SimulationSeriesResult? _result;
  List<ForecastPoint> _forecast = [];
  
  double _hoverAqi = 50.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initForecast());
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _initForecast() {
    final aqiVal = ref.read(currentAqiProvider).asData?.value.aqi ?? 50.0;
    _forecast = SyntheticForecastGenerator().generate(aqiVal.toDouble());
    _runSimulation(); 
  }

  void _runSimulation() {
    if (_forecast.isEmpty) return;

    final exposureEngine = ref.read(exposureEngineProvider);
    final engine = SimulationEngine(exposureEngine);
    final summary = ref.read(dailyExposureProvider);
    final profile = ref.read(healthProfileProvider).value ?? HealthProfile.defaultProfile;
    
    final scenarioData = _createScenarioForBehavior(_scenario);

    setState(() {
      _result = engine.simulateSeries(
        scenario: scenarioData, 
        baseline: summary, 
        todaysForecast: _forecast, 
        profile: profile,
      );
    });
  }

  SimulationScenario _createScenarioForBehavior(BehaviorScenario behavior) {
    switch (behavior) {
      case BehaviorScenario.stayIndoor: return const SimulationScenario(indoorAirQualityFactor: 0.1);
      case BehaviorScenario.outdoorExercise: return const SimulationScenario(outdoorHoursOverride: 2.0);
      case BehaviorScenario.motorizedTransit: return const SimulationScenario(commuteModeOverride: 'car');
      case BehaviorScenario.activeTransit: return const SimulationScenario(commuteModeOverride: 'bicycle');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('4-HOUR AI SIMULATOR', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16, letterSpacing: 2.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), onPressed: () => context.pop()),
      ),
      body: VayuBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 100.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildMainSimulatorCard(),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildSectionHeader(Icons.tune, 'DIAGNOSTIC CONTROLS'),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildScenarioSelection(),
              ),
              const SizedBox(height: 48),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildSectionHeader(Icons.auto_graph, 'HOUR-BY-HOUR AI TIMELINE'),
              ),
              const SizedBox(height: 24),
              _buildModernNarrativeTimeline(),
              const SizedBox(height: 48),
              if (_result != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: _buildProjectionOutcome(),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: _buildHealthDeteriorationCard(),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: _buildProtocolHeader(),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(children: _result!.protocols.map((p) => _buildProtocolCard(p)).toList()),
                ),
              ],
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Colors.tealAccent, size: 14),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
      ],
    );
  }

  Widget _buildMainSimulatorCard() {
    if (_forecast.isEmpty || _result == null) return const Center(child: CircularProgressIndicator(color: Colors.white));

    return VayuCard(
      height: 360,
      padding: EdgeInsets.zero,
      color: Colors.black.withOpacity(0.5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            AtmosphereOverlay(currentAqi: _hoverAqi, intensity: 0.8),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: VayuComparisonChart(
                data: ComparisonData(
                  baseline: _result!.baselinePoints,
                  projected: _result!.projectedPoints,
                  aqiValues: _forecast.map((f) => f.predictedAqi).toList(),
                ),
                onScrub: (x, y, aqi) {
                  setState(() {
                    _hoverAqi = aqi;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioSelection() {
    return Wrap(
      spacing: 12, runSpacing: 12,
      children: BehaviorScenario.values.map((s) {
        final isSelected = _scenario == s;
        return InkWell(
          onTap: () {
            setState(() => _scenario = s);
            _runSimulation();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF004D40) : Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? Colors.tealAccent : Colors.white10, width: 2),
              boxShadow: isSelected ? [BoxShadow(color: Colors.tealAccent.withOpacity(0.3), blurRadius: 15)] : null,
            ),
            child: Text(
              s.label,
              style: TextStyle(
                color: isSelected ? Colors.tealAccent : Colors.white.withOpacity(0.4),
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 1.5,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModernNarrativeTimeline() {
    if (_result == null) return const SizedBox.shrink();
    
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _result!.narratives.length,
        itemBuilder: (context, index) {
          final n = _result!.narratives[index];
          return _buildUltraPremiumGlassCard(n);
        },
      ),
    );
  }

  Widget _buildUltraPremiumGlassCard(HourNarrative n) {
    Color accentColor;
    IconData icon;
    
    switch (n.hazardLevel) {
      case HazardLevel.critical: 
        accentColor = Colors.redAccent;
        icon = Icons.bolt;
        break;
      case HazardLevel.unhealthy: 
        accentColor = Colors.orangeAccent;
        icon = Icons.cloud_outlined;
        break;
      case HazardLevel.optimal: 
        accentColor = const Color(0xFF00E5FF);
        icon = Icons.verified_user_outlined;
        break;
    }

    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 20, bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
              boxShadow: [
                BoxShadow(color: accentColor.withOpacity(0.15), blurRadius: 15, offset: const Offset(4, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('HOUR ${n.hour} • ${n.time}', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1.2)),
                    _buildStatusBadge(n.status, accentColor),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(icon, color: accentColor, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(n.headline, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: -0.5)),
                    ),
                  ],
                ),
                const Spacer(),
                Text(n.impact, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, height: 1.4, fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                Container(
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(2)),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (n.aqiValue / 300).clamp(0.1, 1.0),
                    child: Container(decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(2))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(status, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
    );
  }

  Widget _buildProjectionOutcome() {
    final delta = _result!.deltaPercent;
    final color = delta < 0 ? const Color(0xFF00E5FF) : Colors.redAccent;
    
    return VayuCard(
      padding: const EdgeInsets.all(32),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('DIAGNOSTIC OUTCOME', style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2.0)),
              Icon(delta < 0 ? Icons.check_circle_outline : Icons.report_problem_outlined, color: color, size: 24),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            delta < 0 
                ? 'Vitality preservation successful. Damage buffer +${delta.abs().toStringAsFixed(1)}%.'
                : 'Projected inflammatory decay. Vitality drops by ${delta.toStringAsFixed(1)}%.',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF004D40), height: 1.1, letterSpacing: -0.5),
          ),
          const SizedBox(height: 16),
          Text(_result!.insights.first, style: const TextStyle(fontSize: 14, color: Color(0xFF546E7A), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildHealthDeteriorationCard() {
    return VayuCard(
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('SYSTEM VITALITY DECAY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
              Icon(Icons.monitor_heart_outlined, color: Color(0xFF00E5FF), size: 18),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 140,
            child: VayuDeteriorationChart(stressPoints: _result!.lungStressIndex),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('100% HEALTH', style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
              Container(height: 1, width: 40, color: Colors.white10),
              const Text('PREDICTED STRESS', style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolHeader() {
    return _buildSectionHeader(Icons.medical_information_outlined, 'AI RECOVERY PROTOCOLS');
  }

  Widget _buildProtocolCard(HealthProtocol protocol) {
    final isDiet = protocol.category == 'Dietary';
    final accentColor = isDiet ? const Color(0xFFFB8C00) : const Color(0xFF00E5FF);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: VayuCard(
        color: Colors.white,
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isDiet ? Icons.restaurant_menu : Icons.security, color: accentColor, size: 22),
                const SizedBox(width: 16),
                Text(protocol.title, style: TextStyle(color: accentColor, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5)),
              ],
            ),
            const SizedBox(height: 14),
            Text(protocol.description, style: const TextStyle(fontSize: 15, color: Color(0xFF37474F), fontWeight: FontWeight.w700, height: 1.3)),
            const Divider(height: 40, thickness: 1.5, color: Color(0xFFECEFF1)),
            const Text('SCIENTIFIC PROTOCOL', style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1.5)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12, runSpacing: 12,
              children: protocol.items.map((item) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.06), 
                  borderRadius: BorderRadius.circular(16), 
                  border: Border.all(color: accentColor.withOpacity(0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getProtocolIcon(item), size: 14, color: accentColor),
                    const SizedBox(width: 10),
                    Text(item, style: TextStyle(color: accentColor, fontWeight: FontWeight.w900, fontSize: 12)),
                  ],
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getProtocolIcon(String item) {
    if (item.contains('Vitamin')) return Icons.bolt;
    if (item.contains('Turmeric')) return Icons.auto_awesome;
    if (item.contains('Omega-3')) return Icons.waves;
    if (item.contains('Broccoli')) return Icons.eco;
    if (item.contains('Mask')) return Icons.masks;
    if (item.contains('Purifier')) return Icons.air;
    return Icons.check_circle_outline;
  }
}
