import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vayu/domain/models/exposure_snapshot.dart';

/// Current user activity, can be automtically detected or manually toggled.
final activityProvider = StateProvider<ActivityMode>((ref) => ActivityMode.walking);
