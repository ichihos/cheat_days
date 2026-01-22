import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(FirebaseAuth.instance, FirebaseFirestore.instance);
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepository(this._firebaseAuth, this._firestore);

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _firebaseAuth.signInAnonymously();
      final user = userCredential.user;

      // Create user document in Firestore if it doesn't exist
      if (user != null) {
        final userDoc = _firestore.collection('users').doc(user.uid);
        final docSnapshot = await userDoc.get();
        if (!docSnapshot.exists) {
          await userDoc.set({
            'uid': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
            'isPremium': false,
            'settings': {
              'servingSize': 2,
              'dislikedIngredients': [],
              'dislikedCuisines': [],
              'cookingFrequency': 'often',
            },
          });
        }
      }

      return user;
    } catch (e) {
      // Handle error cleanly in a real app
      print("Error signing in anonymously: $e");
      return null;
    }
  }

  User? get currentUser => _firebaseAuth.currentUser;
}
