import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vayu/domain/interfaces/i_auth_repository.dart';

/// A mock implementation of [IAuthRepository] to allow app usage without Firebase.
class MockAuthRepository implements IAuthRepository {
  final _authStateController = StreamController<User?>.broadcast();
  User? _currentUser;

  MockAuthRepository() {
    // Start as logged out
    _authStateController.add(null);
  }

  @override
  Stream<User?> authStateChanges() => _authStateController.stream;

  @override
  User? getCurrentUser() => _currentUser;

  @override
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    // Validate password length at least
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    // Create a fake User object (mocking Firebase User)
    _currentUser = MockUser(email: email);
    _authStateController.add(_currentUser);
    
    // In a real mock, we would return a fake UserCredential object
    // For simplicity, we just use the internal state. 
    // Returning dummy credential
    return _createFakeCredential(_currentUser!);
  }

  @override
  Future<UserCredential> signUpWithEmailAndPassword(String email, String password) async {
    return signInWithEmailAndPassword(email, password);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
  }

  UserCredential _createFakeCredential(User user) {
    return MockUserCredential(user);
  }
}

class MockUserCredential implements UserCredential {
  MockUserCredential(this._user);
  final User _user;

  @override
  User? get user => _user;

  @override
  AuthCredential? get credential => null;

  @override
  AdditionalUserInfo? get additionalUserInfo => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A minimal mock of the Firebase [User] object.
class MockUser implements User {
  MockUser({required this.email});
  
  @override
  final String? email;
  
  @override
  String get uid => 'mock-user-id';
  
  @override
  String? get displayName => 'Vayu Explorer';

  @override
  bool get emailVerified => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
