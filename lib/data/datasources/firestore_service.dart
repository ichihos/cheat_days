import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/cheat_day_model.dart';
import '../models/cheat_memo_model.dart';
import '../models/comment_model.dart';
import '../models/recipe_model.dart';
import '../models/restaurant_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // CheatDays Collection
  Future<List<CheatDayModel>> getAllPublicCheatDays() async {
    final snapshot = await _firestore
        .collection('cheatDays')
        .where('isPublic', isEqualTo: true)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => CheatDayModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<List<CheatDayModel>> getUserCheatDays(String userId) async {
    final snapshot = await _firestore
        .collection('cheatDays')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => CheatDayModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<List<CheatDayModel>> getCheatDaysByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection('cheatDays')
        .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('date', isLessThan: endOfDay.toIso8601String())
        .get();

    return snapshot.docs
        .map((doc) => CheatDayModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<String> uploadImage(File imageFile, String userId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref().child('cheatDays/$userId/$timestamp.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<void> addCheatDay(CheatDayModel cheatDay) async {
    await _firestore.collection('cheatDays').doc(cheatDay.id).set(cheatDay.toJson());
  }

  Future<void> updateCheatDay(CheatDayModel cheatDay) async {
    await _firestore.collection('cheatDays').doc(cheatDay.id).update(cheatDay.toJson());
  }

  Future<void> deleteCheatDay(String id, String imagePath) async {
    await _firestore.collection('cheatDays').doc(id).delete();

    try {
      final ref = _storage.refFromURL(imagePath);
      await ref.delete();
    } catch (e) {
      // Image deletion failed, but document is deleted
    }
  }

  // Likes
  Future<void> toggleLike(String cheatDayId, String userId) async {
    final docRef = _firestore.collection('cheatDays').doc(cheatDayId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      final likesCount = data['likesCount'] as int? ?? 0;

      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
        transaction.update(docRef, {
          'likedBy': likedBy,
          'likesCount': likesCount - 1,
        });
      } else {
        likedBy.add(userId);
        transaction.update(docRef, {
          'likedBy': likedBy,
          'likesCount': likesCount + 1,
        });
      }
    });
  }

  // Comments
  Future<List<CommentModel>> getComments(String cheatDayId) async {
    final snapshot = await _firestore
        .collection('cheatDays')
        .doc(cheatDayId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => CommentModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<void> addComment(CommentModel comment) async {
    final batch = _firestore.batch();

    final commentRef = _firestore
        .collection('cheatDays')
        .doc(comment.cheatDayId)
        .collection('comments')
        .doc(comment.id);

    batch.set(commentRef, comment.toJson());

    final cheatDayRef = _firestore.collection('cheatDays').doc(comment.cheatDayId);
    batch.update(cheatDayRef, {
      'commentsCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  Future<void> deleteComment(String cheatDayId, String commentId) async {
    final batch = _firestore.batch();

    final commentRef = _firestore
        .collection('cheatDays')
        .doc(cheatDayId)
        .collection('comments')
        .doc(commentId);

    batch.delete(commentRef);

    final cheatDayRef = _firestore.collection('cheatDays').doc(cheatDayId);
    batch.update(cheatDayRef, {
      'commentsCount': FieldValue.increment(-1),
    });

    await batch.commit();
  }

  // Memos (User-specific)
  Future<List<CheatMemoModel>> getUserMemos(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('memos')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => CheatMemoModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<void> addMemo(String userId, CheatMemoModel memo) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('memos')
        .doc(memo.id)
        .set(memo.toJson());
  }

  Future<void> updateMemo(String userId, CheatMemoModel memo) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('memos')
        .doc(memo.id)
        .update(memo.toJson());
  }

  Future<void> deleteMemo(String userId, String memoId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('memos')
        .doc(memoId)
        .delete();
  }

  // Wishlist (User-specific)
  Future<List<dynamic>> getUserWishlist(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<void> addWishlistItem(String userId, dynamic wishlistItem) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .doc(wishlistItem.id)
        .set(wishlistItem.toJson());
  }

  Future<void> updateWishlistItem(String userId, dynamic wishlistItem) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .doc(wishlistItem.id)
        .update(wishlistItem.toJson());
  }

  Future<void> deleteWishlistItem(String userId, String wishlistItemId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .doc(wishlistItemId)
        .delete();
  }

  // Recipes
  Future<RecipeModel?> getRecipeByCheatDayId(String cheatDayId) async {
    final snapshot = await _firestore
        .collection('recipes')
        .where('cheatDayId', isEqualTo: cheatDayId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    return RecipeModel.fromJson({...doc.data(), 'id': doc.id});
  }

  Future<void> addRecipe(RecipeModel recipe) async {
    await _firestore.collection('recipes').doc(recipe.id).set(recipe.toJson());
  }

  Future<void> updateRecipe(RecipeModel recipe) async {
    await _firestore.collection('recipes').doc(recipe.id).update(recipe.toJson());
  }

  Future<void> deleteRecipe(String id) async {
    await _firestore.collection('recipes').doc(id).delete();
  }

  // Restaurants
  Future<RestaurantModel?> getRestaurantByCheatDayId(String cheatDayId) async {
    final snapshot = await _firestore
        .collection('restaurants')
        .where('cheatDayId', isEqualTo: cheatDayId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    return RestaurantModel.fromJson({...doc.data(), 'id': doc.id});
  }

  Future<void> addRestaurant(RestaurantModel restaurant) async {
    await _firestore.collection('restaurants').doc(restaurant.id).set(restaurant.toJson());
  }

  Future<void> updateRestaurant(RestaurantModel restaurant) async {
    await _firestore.collection('restaurants').doc(restaurant.id).update(restaurant.toJson());
  }

  Future<void> deleteRestaurant(String id) async {
    await _firestore.collection('restaurants').doc(id).delete();
  }
}
