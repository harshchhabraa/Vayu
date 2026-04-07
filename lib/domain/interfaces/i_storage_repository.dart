import 'package:vayu/domain/models/exposure_entry.dart';
import 'package:vayu/domain/models/health_profile.dart';

abstract class IStorageRepository {
  /// Save an exposure entry.
  Future<void> saveExposureEntry(ExposureEntry entry);

  /// Get exposure entries for a specific date string (e.g. YYYY-MM-DD).
  Future<List<ExposureEntry>> getExposureEntries(DateTime date);

  /// Get daily exposure summaries.
  Future<List<ExposureSummary>> getExposureSummaries(DateTime start, DateTime end);

  /// Save daily exposure summary.
  Future<void> saveExposureSummary(ExposureSummary summary);

  /// Save/Update the user's health profile.
  Future<void> saveHealthProfile(HealthProfile profile);

  /// Load the user's health profile.
  Future<HealthProfile?> getHealthProfile();
}
