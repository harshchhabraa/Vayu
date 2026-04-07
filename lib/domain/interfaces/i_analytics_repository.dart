import 'package:vayu/domain/models/detection_result.dart';
import 'package:vayu/domain/models/exposure_entry.dart';

abstract class IAnalyticsRepository {
  /// Log app events.
  Future<void> logEvent(String name, [Map<String, dynamic>? parameters]);

  /// Log anonymous vision events for crowd-sourcing.
  Future<void> logVisionEvent(DetectionResult result, double lat, double lng);

  /// Sync exposure summary to cloud.
  Future<void> syncExposureSummary(ExposureSummary summary);
}
