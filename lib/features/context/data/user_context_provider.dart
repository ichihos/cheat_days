import 'package:cheat_days/features/auth/repository/auth_repository.dart';
import 'package:cheat_days/features/context/domain/user_context.dart';
import 'package:cheat_days/features/pantry/data/pantry_repository.dart';
import 'package:cheat_days/features/records/data/meal_record_repository.dart';
import 'package:cheat_days/features/recipes/data/recipe_repository.dart';
import 'package:cheat_days/features/shopping_list/data/shopping_list_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ユーザーコンテキストを提供するProvider
/// パントリー、料理記録、買い物リストから冷蔵庫状況を推測
final userContextProvider = FutureProvider<UserContext?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;

  // 各データソースを取得
  final pantryItems = await ref
      .watch(pantryRepositoryProvider)
      .getPantryItems(user.uid);
  final recentMeals = await ref
      .watch(mealRecordRepositoryProvider)
      .getRecentRecords(user.uid, days: 7);
  final shoppingItems = await ref
      .watch(shoppingListRepositoryProvider)
      .getItems(user.uid);
  final allRecipes = await ref.watch(recipeRepositoryProvider).getAllRecipes();

  // 1. パントリーからベースラインを構築
  final fridgeStatus = <String, FridgeItemStatus>{};
  for (final item in pantryItems) {
    fridgeStatus[item.ingredientName] = FridgeItemStatus(
      amount: item.estimatedAmount,
      lastConfirmed: item.lastPurchased ?? item.lastUsed,
      source: 'onboarding',
    );
  }

  // 2. 料理記録から使用した食材を抽出 → 減少推測
  final recentlyUsedIngredients = <String>[];
  for (final meal in recentMeals) {
    // レシピIDから食材を取得
    if (meal.recipeId != null) {
      final recipe = allRecipes.where((r) => r.id == meal.recipeId).firstOrNull;
      if (recipe != null) {
        for (final ingredient in recipe.ingredients) {
          recentlyUsedIngredients.add(ingredient.name);

          // 既存の状態を減少方向に更新
          final current = fridgeStatus[ingredient.name];
          if (current != null && current.amount == 'ある') {
            fridgeStatus[ingredient.name] = current.copyWith(
              amount: '少し',
              source: 'cooking',
            );
          } else if (current != null && current.amount == '少し') {
            fridgeStatus[ingredient.name] = current.copyWith(
              amount: 'なし',
              source: 'cooking',
            );
          }
        }
      }
    }
  }

  // 3. 買い物リスト（チェック済み）から購入を推測 → 増加
  final recentlyBoughtIngredients = <String>[];
  final plannedPurchases = <String>[];

  for (final item in shoppingItems) {
    if (item.isChecked) {
      // 購入済み → 冷蔵庫にある
      recentlyBoughtIngredients.add(item.name);
      fridgeStatus[item.name] = FridgeItemStatus(
        amount: 'ある',
        lastConfirmed: item.createdAt,
        source: 'shopping',
      );
    } else {
      // 未購入 → 買い物予定
      plannedPurchases.add(item.name);
    }
  }

  // 4. 季節と曜日を取得
  final now = DateTime.now();
  final season = _getCurrentSeason(now.month);
  final dayOfWeek = _getDayOfWeek(now.weekday);

  return UserContext(
    fridgeStatus: fridgeStatus,
    recentlyUsedIngredients: recentlyUsedIngredients.toSet().toList(),
    recentlyBoughtIngredients: recentlyBoughtIngredients.toSet().toList(),
    plannedPurchases: plannedPurchases,
    currentSeason: season,
    dayOfWeek: dayOfWeek,
    lastUpdated: now,
  );
});

String _getCurrentSeason(int month) {
  if (month >= 3 && month <= 5) return '春';
  if (month >= 6 && month <= 8) return '夏';
  if (month >= 9 && month <= 11) return '秋';
  return '冬';
}

String _getDayOfWeek(int weekday) {
  const days = ['月', '火', '水', '木', '金', '土', '日'];
  return '${days[weekday - 1]}曜日';
}
