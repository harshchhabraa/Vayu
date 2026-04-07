import 'package:firebase_auth/firebase_auth.dart';
import 'package:vayu/domain/interfaces/i_auth_repository.dart';

class FirebaseAuthRepository implements IAuthRepository {
  final FirebaseAuth _firebaseAuth;

  FirebaseAuthRepository(this._firebaseAuth);

  @override
  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }

  @override
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  @override
  Future<UserCredential> signUpWithEmailAndPassword(String email, String password) async {
    try {
      // In a real app, we might also update the displayName here or write to Firestore
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  /// Maps technical Firebase errors to user-friendly messages.
  Exception _handleFirebaseException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return Exception('Invalid email or password.');
      case 'email-already-in-use':
        return Exception('This email is already registered. Please log in.');
      case 'weak-password':
        return Exception('Password is too weak. Must be at least 6 characters.');
      case 'invalid-email':
        return Exception('The email address is badly formatted.');
      case 'network-request-failed':
        return Exception('Network error. Please check your connection.');
      default:
        return Exception(e.message ?? 'Authentication failed.');
    }
  }
}
