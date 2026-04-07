import 'package:vayu/domain/interfaces/i_analytics_repository.dart';
import 'package:vayu/domain/models/detection_result.dart';
import 'package:vayu/domain/models/exposure_entry.dart';
import 'package:flutter/foundation.dart';

class MockAnalyticsRepository implements IAnalyticsRepository {
  @override
  Future<void> logEvent(String name, [Map<String, dynamic>? parameters]) async {
    debugPrint('Mock Analytics: Logging event "$name" with params: $parameters');
  }

  @override
  Future<void> logVisionEvent(DetectionResult result, double lat, double lng) async {
    debugPrint('Mock Analytics: Logging vision event with ${result.detections.length} detections at ($lat, $lng)');
  }

  @override
  Future<void> syncExposureSummary(ExposureSummary summary) async {
    debugPrint('Mock Analytics: Syncing exposure summary with score ${summary.totalScore}');
  }
}
