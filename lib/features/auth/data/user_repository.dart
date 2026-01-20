import 'package:cheat_days/features/auth/domain/user_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(FirebaseFirestore.instance);
});

final userSettingsProvider = StreamProvider.autoDispose<UserSettings>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(UserSettings());

  return ref.watch(userRepositoryProvider).streamSettings(user.uid);
});

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository(this._firestore);

  Future<void> createProfileIfAbsent(User user) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      await docRef.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'settings': UserSettings().toMap(), // Default settings
      });
    }
  }

  Stream<UserSettings> streamSettings(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return UserSettings();
      final data = snapshot.data()!;
      if (data.containsKey('settings')) {
        return UserSettings.fromMap(data['settings'] as Map<String, dynamic>);
      }
      return UserSettings();
    });
  }

  Future<void> updateSettings(String uid, UserSettings settings) async {
    await _firestore.collection('users').doc(uid).update({
      'settings': settings.toMap(),
    });
  }
}
