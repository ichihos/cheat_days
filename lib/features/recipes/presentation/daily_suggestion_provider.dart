import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cheat_days/core/constants/app_constants.dart';
import 'package:cheat_days/features/auth/data/user_repository.dart';
import 'package:cheat_days/features/auth/domain/user_settings.dart';
import 'package:cheat_days/features/auth/repository/auth_repository.dart';
import 'package:cheat_days/features/home/data/ai_service.dart';
import 'package:cheat_days/features/pantry/data/pantry_repository.dart';
import 'package:cheat_days/features/records/data/meal_record_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/recipe.dart';
import '../data/recipe_repository.dart';

class DailySuggestionState {
  final Recipe? recipe;
  final Recipe? sideDish;
  final String? messieComment;
  final String? reason;

  DailySuggestionState({
    this.recipe,
    this.sideDish,
    this.messieComment,
    this.reason,
  });
}

final dailySuggestionProvider = FutureProvider<DailySuggestionState>((
  ref,
) async {
  final repository = ref.watch(recipeRepositoryProvider);
  final aiService = ref.watch(aiServiceProvider);
  final user = ref.watch(authStateProvider).value;

  // 1. Fetch all recipes
  final recipes = await repository.getAllRecipes();

  if (recipes.isEmpty) {
    return DailySuggestionState();
  }

  // Check Firestore for pre-generated suggestion
  if (user != null) {
    try {
      final firestore = FirebaseFirestore.instance;
      final suggestionSnap =
          await firestore
              .collection('users')
              .doc(user.uid)
              .collection('daily_suggestions')
              .orderBy('createdAt', descending: true)
              .limit(1)
              .get();

      if (suggestionSnap.docs.isNotEmpty) {
        final data = suggestionSnap.docs.first.data();
        final selectedRecipeId = data['selectedRecipeId'] as String?;
        final sideDishId = data['sideDishRecipeId'] as String?;
        final messieComment = data['messieComment'] as String?;
        final reason = data['reason'] as String?;

        if (selectedRecipeId != null) {
          final selectedRecipe = recipes.firstWhere(
            (r) => r.id == selectedRecipeId,
            orElse: () => recipes.first,
          );
          Recipe? sideDish;
          if (sideDishId != null) {
            try {
              sideDish = recipes.firstWhere((r) => r.id == sideDishId);
            } catch (_) {}
          }

          return DailySuggestionState(
            recipe: selectedRecipe,
            sideDish: sideDish,
            messieComment: messieComment,
            reason: reason,
          );
        }
      }
    } catch (e) {
      print("Error fetching daily suggestion from Firestore: $e");
    }
  }

  // 2. Fetch user settings
  UserSettings settings;
  try {
    settings = await ref.watch(userSettingsProvider.future);
  } catch (e) {
    print("Failed to load user settings: $e, using defaults.");
    settings = UserSettings();
  }

  // 3. Fetch recent meal records (last 7 days)
  final recentMeals =
      user != null
          ? await ref
              .watch(mealRecordRepositoryProvider)
              .getRecentRecords(user.uid, days: 7)
          : null;

  // 4. Fetch pantry items
  final pantryItems =
      user != null
          ? await ref.watch(pantryRepositoryProvider).getPantryItems(user.uid)
          : null;

  // 5. Select candidates (Mix of Main and Side)
  // Define categories for main and side
  final mainCategories = ['main', 'rice', 'noodle'];
  final sideCategories = ['side', 'soup'];

  final mains =
      recipes.where((r) => mainCategories.contains(r.category)).toList()
        ..shuffle();
  final sides =
      recipes.where((r) => sideCategories.contains(r.category)).toList()
        ..shuffle();

  // Take up to 6 mains and 4 sides
  final candidates = [...mains.take(6), ...sides.take(4)];

  // Create a fallback if we don't have enough specific categories
  if (candidates.length < 5) {
    final remaining =
        recipes.where((r) => !candidates.contains(r)).toList()..shuffle();
    candidates.addAll(remaining.take(10 - candidates.length));
  }

  // 6. Call AI with full context (Fallback)
  try {
    final suggestion = await aiService.suggestMeal(
      candidates: candidates,
      settings: settings,
      recentMeals: recentMeals,
      pantryItems: pantryItems,
    );

    if (suggestion != null) {
      final selectedRecipe = recipes.firstWhere(
        (r) => r.id == suggestion.recipeId,
        orElse: () => candidates.first,
      );
      Recipe? sideDish;
      if (suggestion.sideDishId != null) {
        try {
          sideDish = recipes.firstWhere((r) => r.id == suggestion.sideDishId);
        } catch (_) {}
      }

      // Save this fallback suggestion to Firestore so we don't regenerate immediately
      if (user != null) {
        try {
          final dateStr = DateTime.now().toIso8601String().split('T')[0];
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('daily_suggestions')
              .doc(dateStr)
              .set({
                'selectedRecipeId': suggestion.recipeId,
                'sideDishRecipeId': suggestion.sideDishId,
                'messieComment': suggestion.messieComment,
                'reason': suggestion.reason,
                'createdAt': FieldValue.serverTimestamp(),
                'date': dateStr,
              });
        } catch (e) {
          print("Failed to save fallback suggestion: $e");
        }
      }

      return DailySuggestionState(
        recipe: selectedRecipe,
        sideDish: sideDish,
        messieComment: suggestion.messieComment,
        reason: suggestion.reason,
      );
    }
  } catch (e) {
    print("AI Service invocation failed: $e, falling back to random.");
  }

  // Fallback: Random selection with generic comment
  final randomRecipe = candidates.first;
  return DailySuggestionState(
    recipe: randomRecipe,
    messieComment:
        "${randomRecipe.name}どう${AppConstants.messieSuffix}？\n${randomRecipe.timeMinutes}分で作れる${AppConstants.messieSuffix}！",
  );
});
