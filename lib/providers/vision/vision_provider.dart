import 'dart:isolate';
import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vayu/domain/models/detection_result.dart';
import 'package:vayu/ml/inference_engine.dart';

// Provider to toggle simulation
final isVisionSimulatedProvider = StateProvider<bool>((ref) => false);

// Provider for the Camera Controller
final cameraControllerProvider = FutureProvider<CameraController>((ref) async {
  final cameras = await availableCameras();
  if (cameras.isEmpty) throw Exception('No cameras available');
  
  final controller = CameraController(
    cameras.first, 
    ResolutionPreset.medium,
    enableAudio: false,
    imageFormatGroup: ImageFormatGroup.yuv420,
  );
  
  await controller.initialize();
  return controller;
});

// Provider for the Netra Vision state (latest detection result)
final visionResultProvider = StateProvider<DetectionResult?>((ref) => null);

// Provider that manages the background Inference Isolate
final visionIsolateProvider = FutureProvider<SendPort>((ref) async {
  final receivePort = ReceivePort();
  await Isolate.spawn(InferenceIsolateWorker.inferenceEntryPoint, receivePort.sendPort);
  return await receivePort.first as SendPort;
});

// The simulation loop logic
Timer? _simulationTimer;

void startSimulation(WidgetRef ref) {
  _simulationTimer?.cancel();
  _simulationTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
    final random = Random();
    final labels = ['smoke', 'heavy_traffic', 'industrial_emission', 'haze'];
    final label = labels[random.nextInt(labels.length)];
    
    final detection = Detection(
      label: label,
      confidence: 0.7 + random.nextDouble() * 0.25,
      boundingBox: BoundingBox(
        left: 0.1 + random.nextDouble() * 0.4,
        top: 0.1 + random.nextDouble() * 0.4,
        right: 0.5 + random.nextDouble() * 0.4,
        bottom: 0.5 + random.nextDouble() * 0.4,
      ),
    );

    final result = DetectionResult(
      detections: [detection],
      frameTimestamp: DateTime.now(),
      inferenceTimeMs: 45,
      modelName: 'NETRA-V1-SIM',
    );

    ref.read(visionResultProvider.notifier).state = result;
  });
}

void stopSimulation() {
  _simulationTimer?.cancel();
  _simulationTimer = null;
}

// A simple notifier/listener to bridge the Camera Stream to the Isolate
final visionPipelineProvider = Provider((ref) async {
  final isSimulated = ref.watch(isVisionSimulatedProvider);
  
  if (isSimulated) {
    // Logic for simulation handled via external calls for now or a timer
    return;
  }

  final controllerAsync = ref.watch(cameraControllerProvider);
  final isolatePortAsync = ref.watch(visionIsolateProvider);
  
  if (controllerAsync.hasValue && isolatePortAsync.hasValue) {
    final controller = controllerAsync.value!;
    final port = isolatePortAsync.value!;
    
    bool isProcessing = false;
    
    controller.startImageStream((CameraImage image) async {
      if (isProcessing) return; 
      isProcessing = true;
      
      final replyPort = ReceivePort();
      port.send({
        'replyPort': replyPort.sendPort,
        'image': image.planes.first.bytes,
        'width': image.width,
        'height': image.height,
      });
      
      final result = await replyPort.first as DetectionResult;
      ref.read(visionResultProvider.notifier).state = result;
      
      isProcessing = false;
      replyPort.close();
    });
  }
});
