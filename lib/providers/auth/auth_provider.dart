import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vayu/domain/interfaces/i_auth_repository.dart';
import 'package:vayu/data/repositories/firebase_auth_repository.dart';
import 'package:vayu/data/repositories/mock_auth_repository.dart';
import 'package:vayu/core/config/vayu_config.dart';

// Base instances
final firebaseAuthProvider = Provider<FirebaseAuth?>((ref) {
  try {
    if (Firebase.apps.isNotEmpty) {
      return FirebaseAuth.instance;
    }
  } catch (e) {
    // Firebase not initialized
  }
  return null;
});

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  
  if (VayuConfig.useMockAuth || firebaseAuth == null) {
    return MockAuthRepository();
  }
  
  return FirebaseAuthRepository(firebaseAuth);
});

// Stream of auth state changes (used by GoRouter to redirect)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

// Controller for handling loading states and invoking auth actions
final authControllerProvider = AsyncNotifierProvider<AuthController, void>(() {
  return AuthController();
});

class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // No initial async work needed
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      await repo.signInWithEmailAndPassword(email, password);
    });
  }

  Future<void> signUp(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      await repo.signUpWithEmailAndPassword(email, password);
    });
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      await repo.signOut();
    });
  }
}
