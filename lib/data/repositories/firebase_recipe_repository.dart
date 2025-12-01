import '../../domain/entities/recipe.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../datasources/firestore_service.dart';
import '../models/recipe_model.dart';

class FirebaseRecipeRepository implements RecipeRepository {
  final FirestoreService firestoreService;

  FirebaseRecipeRepository(this.firestoreService);

  @override
  Future<Recipe?> getRecipeByCheatDayId(String cheatDayId) async {
    return await firestoreService.getRecipeByCheatDayId(cheatDayId);
  }

  @override
  Future<void> addRecipe(Recipe recipe) async {
    await firestoreService.addRecipe(RecipeModel.fromEntity(recipe));
  }

  @override
  Future<void> updateRecipe(Recipe recipe) async {
    await firestoreService.updateRecipe(RecipeModel.fromEntity(recipe));
  }

  @override
  Future<void> deleteRecipe(String id) async {
    await firestoreService.deleteRecipe(id);
  }
}
