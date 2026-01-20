import 'package:cheat_days/features/shopping_list/domain/shopping_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final shoppingListRepositoryProvider = Provider<ShoppingListRepository>((ref) {
  return ShoppingListRepository(FirebaseFirestore.instance);
});

class ShoppingListRepository {
  final FirebaseFirestore _firestore;

  ShoppingListRepository(this._firestore);

  Stream<List<ShoppingItem>> streamItems(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('shoppingList')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ShoppingItem.fromFirestore(doc))
                  .toList(),
        );
  }

  Future<void> addItem(String userId, ShoppingItem item) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('shoppingList')
        .add(item.toMap());
  }

  Future<void> updateItem(String userId, ShoppingItem item) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('shoppingList')
        .doc(item.id)
        .update(item.toMap());
  }

  Future<void> deleteItem(String userId, String itemId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('shoppingList')
        .doc(itemId)
        .delete();
  }

  Future<void> toggleCheck(
    String userId,
    String itemId,
    bool currentStatus,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('shoppingList')
        .doc(itemId)
        .update({'isChecked': !currentStatus});
  }
}
