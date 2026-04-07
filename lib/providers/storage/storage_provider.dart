import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vayu/data/repositories/simple_storage_repository.dart';
import 'package:vayu/domain/interfaces/i_storage_repository.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in ProviderScope');
});

final storageRepositoryProvider = Provider<IStorageRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SimpleStorageRepository(prefs);
});
