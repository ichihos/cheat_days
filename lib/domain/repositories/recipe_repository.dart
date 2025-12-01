import '../entities/recipe.dart';

abstract class RecipeRepository {
  Future<Recipe?> getRecipeByCheatDayId(String cheatDayId);
  Future<void> addRecipe(Recipe recipe);
  Future<void> updateRecipe(Recipe recipe);
  Future<void> deleteRecipe(String id);
}
