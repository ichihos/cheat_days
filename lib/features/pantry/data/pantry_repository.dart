import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/pantry_item.dart';

final pantryRepositoryProvider = Provider<PantryRepository>((ref) {
  return PantryRepository(FirebaseFirestore.instance);
});

class PantryRepository {
  final FirebaseFirestore _firestore;

  PantryRepository(this._firestore);

  Stream<List<PantryItem>> streamPantry(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('pantry')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => PantryItem.fromFirestore(doc))
                  .toList(),
        );
  }

  Future<List<PantryItem>> getPantryItems(String userId) async {
    final snapshot =
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('pantry')
            .get();
    return snapshot.docs.map((doc) => PantryItem.fromFirestore(doc)).toList();
  }

  Future<void> addItem(String userId, PantryItem item) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('pantry')
        .add(item.toMap());
  }

  Future<void> updateItem(String userId, PantryItem item) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('pantry')
        .doc(item.id)
        .update(item.toMap());
  }

  Future<void> deleteItem(String userId, String itemId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('pantry')
        .doc(itemId)
        .delete();
  }
}
