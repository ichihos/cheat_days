import 'package:cheat_days/core/constants/app_constants.dart';
import 'package:cheat_days/features/auth/domain/user_settings.dart';
import 'package:cheat_days/features/home/data/ai_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/recipe.dart';
import '../data/recipe_repository.dart';

// We introduce a state to hold the "AI Comment" as well, tied to the recipe.
// Actually, let's wrap the result in a state object.

class DailySuggestionState {
  final Recipe? recipe;
  final String? messieComment;

  DailySuggestionState({this.recipe, this.messieComment});
}

final dailySuggestionProvider = FutureProvider<DailySuggestionState>((
  ref,
) async {
  final repository = ref.watch(recipeRepositoryProvider);
  final aiService = ref.watch(aiServiceProvider);

  // 1. Fetch Candidates (e.g. 10 recipes)
  // In a real app, filtering by user's available ingredients or history would happen here or in DB query
  final recipes =
      await repository
          .getAllRecipes(); // For MVP, just get all (assuming < 100) or limit

  if (recipes.isEmpty) {
    return DailySuggestionState();
  }

  // 2. Mock UserSettings for MVP (or fetch from User repository)
  final settings = UserSettings(servingSize: 2, dislikedIngredients: []);

  // 3. Call AI
  // We limit candidates to saving token usage if list is huge, e.g. take random 10
  final candidates = (recipes..shuffle()).take(10).toList();

  try {
    final suggestion = await aiService.suggestMeal(
      candidates: candidates,
      settings: settings,
    );

    if (suggestion != null) {
      final selectedRecipe = recipes.firstWhere(
        (r) => r.id == suggestion.recipeId,
        orElse: () => candidates.first,
      );
      return DailySuggestionState(
        recipe: selectedRecipe,
        messieComment: suggestion.messieComment,
      );
    }
  } catch (e) {
    print("AI Service invocation failed: $e, falling back to random.");
  }

  // Fallback: Random
  final randomRecipe = candidates.first;
  return DailySuggestionState(
    recipe: randomRecipe,
    messieComment:
        "鶏もも肉そろそろ使い切りたい${AppConstants.messieSuffix}。\n${randomRecipe.name}どう${AppConstants.messieSuffix}？", // Fallback comment
  );
});
