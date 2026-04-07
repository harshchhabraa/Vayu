import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vayu/domain/interfaces/i_analytics_repository.dart';
import 'package:vayu/domain/models/detection_result.dart';
import 'package:vayu/domain/models/exposure_entry.dart';

class FirebaseAnalyticsRepository implements IAnalyticsRepository {
  final FirebaseFirestore _firestore;

  FirebaseAnalyticsRepository(this._firestore);

  @override
  Future<void> logEvent(String name, [Map<String, dynamic>? parameters]) async {
    // Basic event logging to a user-specific events collection
    await _firestore.collection('events').add({
      'name': name,
      'parameters': parameters,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> logVisionEvent(DetectionResult result, double lat, double lng) async {
    // Anonymous community mapping for pollution sources
    // Only log high-confidence detections
    final highConfidenceDetections = result.detections.where((d) => d.isHighConfidence).toList();
    if (highConfidenceDetections.isEmpty) return;

    await _firestore.collection('community_emissions').add({
      'detections': highConfidenceDetections.map((d) => {
        'label': d.label,
        'confidence': d.confidence,
        'inferred_gas': _mapToGas(d.label),
      }).toList(),
      'location': GeoPoint(lat, lng),
      'timestamp': FieldValue.serverTimestamp(),
      'model_version': result.modelName,
    });
  }

  @override
  Future<void> syncExposureSummary(ExposureSummary summary) async {
    // Secure personal exposure history
    await _firestore.collection('exposure_history').add({
      'total_score': summary.totalScore,
      'timestamp': FieldValue.serverTimestamp(),
      'entry_count': summary.entries.length,
    });
  }

  String _mapToGas(String label) {
    switch (label) {
      case 'smoke':
      case 'industrial_emission':
        return 'CO / CO2 (Inferred)';
      case 'heavy_traffic':
        return 'NOx / Particulates (Inferred)';
      case 'haze':
        return 'PM2.5 / Dust (Inferred)';
      default:
        return 'Unknown Pollutant';
    }
  }
}
