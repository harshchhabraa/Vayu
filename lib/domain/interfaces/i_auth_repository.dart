import 'package:firebase_auth/firebase_auth.dart' as auth;

/// The core domain interface for Authentication.
abstract class IAuthRepository {
  /// Stream of the user's authentication state.
  /// Emits null if the user is unauthenticated.
  Stream<auth.User?> authStateChanges();

  /// Gets the currently authenticated user synchronously.
  auth.User? getCurrentUser();

  /// Sign in with email and password.
  Future<auth.UserCredential> signInWithEmailAndPassword(String email, String password);

  /// Create a new account with email and password.
  Future<auth.UserCredential> signUpWithEmailAndPassword(String email, String password);

  /// Sign out the current user.
  Future<void> signOut();
}

// Temporary path reference fix since we don't have the real package exported cleanly in this scaffold
// Note: In real setup, we import 'package:firebase_auth/firebase_auth.dart'
