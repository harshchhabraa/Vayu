import 'package:vayu/domain/models/detection_result.dart';
import 'dart:typed_data';

abstract class IVisionRepository {
  /// Initialize ML models.
  Future<void> initialize();

  /// Run inference on a camera frame.
  Future<DetectionResult> processFrame(Uint8List frameData, int width, int height);

  /// Free resources.
  Future<void> dispose();
}
