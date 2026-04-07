import 'package:vayu/domain/models/detection_result.dart';
import 'dart:async';

class NetraVisionEngine {
  /// Filters out low confidence detections and applies NMS logic if necessary.
  DetectionResult filterDetections(DetectionResult rawResult) {
    final List<Detection> filtered = [];
    
    // Filter by display confidence threshold (0.6)
    for (final detection in rawResult.detections) {
      if (detection.isDisplayable) {
        filtered.add(detection);
      }
    }
    
    // Basic NMS could go here if the model outputs overlapping boxes
    
    return DetectionResult(
      detections: filtered,
      frameTimestamp: rawResult.frameTimestamp,
      inferenceTimeMs: rawResult.inferenceTimeMs,
      modelName: rawResult.modelName,
    );
  }

  /// Determines if a sequence of detections warrants logging an event.
  /// Needs to be sustained over multiple frames.
  bool shouldLogEvent(List<DetectionResult> historyQueue) {
    if (historyQueue.length < 5) return false; // Need at least 5 frames (~1 second at 5fps)
    
    int highConfidenceSmokeFrames = 0;
    
    for (final result in historyQueue) {
      if (result.detections.any((d) => d.isHighConfidence && (d.label == 'smoke' || d.label == 'fire_smoke'))) {
        highConfidenceSmokeFrames++;
      }
    }
    
    // If 80% of recent frames show high confidence smoke
    return highConfidenceSmokeFrames >= (historyQueue.length * 0.8).floor();
  }
}
