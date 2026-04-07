import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vayu/domain/interfaces/i_analytics_repository.dart';
import 'package:vayu/data/repositories/firebase_analytics_repository.dart';
import 'package:vayu/data/repositories/mock_analytics_repository.dart';
import 'package:vayu/providers/auth/auth_provider.dart';

final firestoreProvider = Provider<FirebaseFirestore?>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  if (firebaseAuth != null) {
    return FirebaseFirestore.instance;
  }
  return null;
});

final analyticsRepositoryProvider = Provider<IAnalyticsRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  
  if (firestore == null) {
    return MockAnalyticsRepository();
  }
  
  return FirebaseAnalyticsRepository(firestore);
});