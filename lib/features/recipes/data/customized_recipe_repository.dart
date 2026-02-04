import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/customized_recipe.dart';
import '../domain/recipe.dart';

final customizedRecipeRepositoryProvider =
    Provider<CustomizedRecipeRepository>((ref) {
      return CustomizedRecipeRepository(FirebaseFirestore.instance);
    });

class CustomizedRecipeRepository {
  final FirebaseFirestore _firestore;

  CustomizedRecipeRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('customized_recipes');
  }

  /// 今日のカスタマイズ済みレシピをストリームで取得
  Stream<CustomizedRecipe?> streamTodaysCustomizedRecipe(String userId) {
    final today = _getTodayString();
    return _collection(userId)
        .where('date', isEqualTo: today)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return CustomizedRecipe.fromFirestore(snapshot.docs.first);
        });
  }

  /// 日付指定でカスタマイズ済みレシピを取得
  Future<CustomizedRecipe?> getCustomizedRecipe(
    String userId,
    String date,
  ) async {
    final snapshot =
        await _collection(userId).where('date', isEqualTo: date).limit(1).get();

    if (snapshot.docs.isEmpty) return null;
    return CustomizedRecipe.fromFirestore(snapshot.docs.first);
  }

  /// 今日のカスタマイズ済みレシピを取得
  Future<CustomizedRecipe?> getTodaysCustomizedRecipe(String userId) async {
    return getCustomizedRecipe(userId, _getTodayString());
  }

  /// カスタマイズ済みレシピを作成または更新
  Future<CustomizedRecipe> saveCustomizedRecipe(
    String userId,
    CustomizedRecipe customizedRecipe,
  ) async {
    // 同じ日付の既存レシピがあるか確認
    final existing = await getCustomizedRecipe(userId, customizedRecipe.date);

    if (existing != null) {
      // 更新
      final updated = customizedRecipe.copyWith(
        id: existing.id,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
      );
      await _collection(userId).doc(existing.id).update(updated.toMap());
      return updated;
    } else {
      // 新規作成
      final docRef = await _collection(userId).add(customizedRecipe.toMap());
      return customizedRecipe.copyWith(id: docRef.id);
    }
  }

  /// レシピを更新（食材変更など）
  Future<void> updateRecipe(
    String userId,
    String customizedRecipeId,
    Recipe updatedRecipe,
    RecipeAdjustmentLog? adjustmentLog,
  ) async {
    final doc = await _collection(userId).doc(customizedRecipeId).get();
    if (!doc.exists) return;

    final current = CustomizedRecipe.fromFirestore(doc);
    final newHistory = List<RecipeAdjustmentLog>.from(current.adjustmentHistory);
    if (adjustmentLog != null) {
      newHistory.add(adjustmentLog);
    }

    final updated = current.copyWith(
      recipe: updatedRecipe,
      adjustmentHistory: newHistory,
      updatedAt: DateTime.now(),
    );

    await _collection(userId).doc(customizedRecipeId).update(updated.toMap());
  }

  /// オリジナルレシピから今日用のカスタマイズ済みレシピを初期化
  Future<CustomizedRecipe> initializeTodaysRecipe(
    String userId,
    Recipe originalRecipe,
  ) async {
    final today = _getTodayString();
    final existing = await getCustomizedRecipe(userId, today);

    // 既に同じオリジナルレシピで初期化済みなら既存を返す
    if (existing != null && existing.originalRecipeId == originalRecipe.id) {
      return existing;
    }

    // 新しいレシピで初期化（または別のレシピに切り替わった場合）
    final customized = CustomizedRecipe.fromOriginal(
      original: originalRecipe,
      date: today,
    );

    return saveCustomizedRecipe(userId, customized);
  }

  /// 副菜用のカスタマイズ済みレシピを初期化
  Future<CustomizedRecipe> initializeSideDishRecipe(
    String userId,
    Recipe sideDishRecipe,
  ) async {
    final today = '${_getTodayString()}_side';
    final existing = await getCustomizedRecipe(userId, today);

    if (existing != null && existing.originalRecipeId == sideDishRecipe.id) {
      return existing;
    }

    final customized = CustomizedRecipe.fromOriginal(
      original: sideDishRecipe,
      date: today,
    );

    return saveCustomizedRecipe(userId, customized);
  }

  /// 削除
  Future<void> deleteCustomizedRecipe(
    String userId,
    String customizedRecipeId,
  ) async {
    await _collection(userId).doc(customizedRecipeId).delete();
  }

  /// 古いカスタマイズ済みレシピをクリーンアップ（7日以上前）
  Future<void> cleanupOldRecipes(String userId) async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
    final cutoffString = _formatDate(cutoffDate);

    final snapshot =
        await _collection(userId).where('date', isLessThan: cutoffString).get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  String _getTodayString() {
    return _formatDate(DateTime.now());
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
