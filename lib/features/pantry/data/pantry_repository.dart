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

  /// アイテムが存在すれば更新、なければ作成（食材名で検索）
  Future<void> upsertByName(String userId, PantryItem item) async {
    final collection = _firestore
        .collection('users')
        .doc(userId)
        .collection('pantry');

    // 食材名で既存アイテムを検索
    final existing = await collection
        .where('ingredientName', isEqualTo: item.ingredientName)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      // 既存アイテムを更新
      await collection.doc(existing.docs.first.id).update(item.toMap());
    } else {
      // 新規作成
      await collection.add(item.toMap());
    }
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
