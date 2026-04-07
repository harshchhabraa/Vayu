import 'dart:async';
import 'dart:math';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vayu/providers/vision/vision_provider.dart';
import 'package:vayu/providers/analytics/analytics_provider.dart';
import 'package:vayu/domain/models/detection_result.dart';
import 'package:vayu/presentation/widgets/vayu_hud_painter.dart';
import 'package:vayu/presentation/widgets/vayu_card.dart';

class NetraVisionScreen extends ConsumerStatefulWidget {
  const NetraVisionScreen({super.key});

  @override
  ConsumerState<NetraVisionScreen> createState() => _NetraVisionScreenState();
}

class _NetraVisionScreenState extends ConsumerState<NetraVisionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _scannerController;
  final List<Detection> _history = [];
  Timer? _simulationTimer;

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    
    // Initialize the vision pipeline
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(visionPipelineProvider);
    });
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _simulationTimer?.cancel();
    super.dispose();
  }

  void _startLocalSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      final random = Random();
      final labels = ['smoke', 'heavy_traffic', 'industrial_emission', 'haze'];
      final label = labels[random.nextInt(labels.length)];
      
      final detection = Detection(
        label: label,
        confidence: 0.75 + random.nextDouble() * 0.2,
        boundingBox: BoundingBox(
          left: 0.2 + random.nextDouble() * 0.3,
          top: 0.2 + random.nextDouble() * 0.3,
          right: 0.5 + random.nextDouble() * 0.3,
          bottom: 0.5 + random.nextDouble() * 0.3,
        ),
      );

      final result = DetectionResult(
        detections: [detection],
        frameTimestamp: DateTime.now(),
        inferenceTimeMs: 32,
        modelName: 'NETRA-V1-SIM',
      );

      if (mounted) {
        ref.read(visionResultProvider.notifier).state = result;
      }
    });
  }

  void _addToHistory(DetectionResult? result) {
    if (result == null || result.detections.isEmpty) return;
    
    final best = result.highestConfidence;
    if (best != null && best.isHighConfidence) {
      setState(() {
        if (_history.length >= 10) _history.removeAt(0);
        _history.add(best);
        ref.read(analyticsRepositoryProvider).logVisionEvent(result, 0.0, 0.0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameraControllerAsync = ref.watch(cameraControllerProvider);
    final visionResult = ref.watch(visionResultProvider);
    final isSimulated = ref.watch(isVisionSimulatedProvider);

    // Listen for new results to update history
    ref.listen<DetectionResult?>(visionResultProvider, (prev, next) {
      _addToHistory(next);
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: isSimulated 
          ? _buildSimulationView(context, visionResult)
          : cameraControllerAsync.when(
              data: (controller) => _buildCameraView(context, controller, visionResult),
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.tealAccent)),
              error: (err, stack) => _buildErrorFallback(context, err.toString()),
            ),
    );
  }

  Widget _buildCameraView(BuildContext context, CameraController controller, DetectionResult? visionResult) {
    final isPortrait = MediaQuery.of(context).size.width < 600;

    return Stack(
      children: [
        Flex(
          direction: isPortrait ? Axis.vertical : Axis.horizontal,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: CameraPreview(controller),
                    ),
                  ),
                  _buildHudLayer(visionResult, controller.value.previewSize),
                  _buildScannerLayer(),
                ],
              ),
            ),
            isPortrait ? _buildBottomLogPanel() : _buildSidebar(),
          ],
        ),
        _buildBackButton(context),
      ],
    );
  }

  Widget _buildSimulationView(BuildContext context, DetectionResult? visionResult) {
    final isPortrait = MediaQuery.of(context).size.width < 600;

    return Stack(
      children: [
        Flex(
          direction: isPortrait ? Axis.vertical : Axis.horizontal,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.5,
                          colors: [Color(0xFF002B2B), Colors.black],
                        ),
                      ),
                      child: Opacity(
                        opacity: 0.1,
                        child: CustomPaint(painter: GridPainter()),
                      ),
                    ),
                  ),
                  const Center(
                    child: Text(
                      'AI VISION SIMULATION ACTIVE',
                      style: TextStyle(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                  ),
                  _buildHudLayer(visionResult, const Size(1920, 1080)),
                  _buildScannerLayer(),
                ],
              ),
            ),
            isPortrait ? _buildBottomLogPanel() : _buildSidebar(),
          ],
        ),
        _buildBackButton(context),
      ],
    );
  }

  Widget _buildBottomLogPanel() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        border: const Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final detection = _history[_history.length - 1 - index];
                return _buildLogEntry(detection);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NETRA LOG', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
          Text('AI ATMOSPHERIC ANALYSIS', style: TextStyle(color: Colors.tealAccent, fontSize: 8, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildErrorFallback(BuildContext context, String error) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.symmetric(horizontal: 40),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_rounded, color: Colors.redAccent, size: 64),
            const SizedBox(height: 24),
            const Text(
              'CAMERA ACCESS BLOCKED',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your hardware is not responding or permission was denied.',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(isVisionSimulatedProvider.notifier).state = true;
                  _startLocalSimulation();
                },
                icon: const Icon(Icons.bolt, color: Colors.black),
                label: const Text('ENTER SIMULATION MODE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(cameraControllerProvider),
              child: const Text('RETRY HARDWARE ACCESS', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHudLayer(DetectionResult? result, Size? previewSize) {
    if (result == null || previewSize == null) return const SizedBox.shrink();
    return Positioned.fill(
      child: CustomPaint(
        painter: VayuHudPainter(
          detections: result.detections,
          previewSize: previewSize,
        ),
      ),
    );
  }

  Widget _buildScannerLayer() {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: _scannerController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: constraints.maxHeight * _scannerController.value,
                    left: 0, right: 0,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        boxShadow: [BoxShadow(color: Colors.tealAccent.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)],
                        color: Colors.tealAccent.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        border: const Border(left: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40), // Offset for desktop back button area
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final detection = _history[_history.length - 1 - index];
                return _buildLogEntry(detection);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntry(Detection detection) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(detection.gasColor).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  detection.inferredGasLabel.split(' (').first, 
                  style: TextStyle(color: Color(detection.gasColor), fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text('${(detection.confidence * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 4),
          Text('LOCATED IN SECTOR ${_generateSector()}', style: const TextStyle(color: Colors.white24, fontSize: 8)),
        ],
      ),
    );
  }

  String _generateSector() => String.fromCharCode(65 + Random().nextInt(6)) + (Random().nextInt(9) + 1).toString();

  Widget _buildBackButton(BuildContext context) {
    return Positioned(
      top: 50, left: 16,
      child: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
        onPressed: () => context.pop(),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.tealAccent.withOpacity(0.2)..strokeWidth = 0.5;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) { canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint); }
    for (double y = 0; y < size.height; y += step) { canvas.drawLine(Offset(0, y), Offset(size.width, y), paint); }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
