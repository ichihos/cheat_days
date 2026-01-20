import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/recipe.dart';

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepository(FirebaseFirestore.instance);
});

class RecipeRepository {
  final FirebaseFirestore _firestore;

  RecipeRepository(this._firestore);

  Future<List<Recipe>> getAllRecipes() async {
    final snapshot = await _firestore.collection('recipes').get();
    return snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
  }

  Future<Recipe?> getRecipe(String id) async {
    final doc = await _firestore.collection('recipes').doc(id).get();
    if (doc.exists) {
      return Recipe.fromFirestore(doc);
    }
    return null;
  }

  // Simple random suggestion for MVP
  Future<Recipe?> getDailySuggestion() async {
    // In a real app, this would be a specific collection 'dailySuggestions'
    // For now, we fetch a few recipes and pick one random one.
    // Optimization: query limit 1 with random offset or similar.
    final snapshot = await _firestore.collection('recipes').limit(10).get();
    if (snapshot.docs.isNotEmpty) {
      return Recipe.fromFirestore(
        snapshot.docs.first,
      ); // Just pick the first for now for simplicity
    }
    return null;
  }

  Future<void> saveRecipe(Recipe recipe) async {
    // Uses set() to create or update with specific ID
    await _firestore.collection('recipes').doc(recipe.id).set(recipe.toMap());
  }

  Future<void> addRecipe(Recipe recipe) async {
    // Wrapper for legacy or if you specifically want add() behavior (autogen ID)
    // But since our Recipe model has ID, we should use saveRecipe usually.
    // However, if ID is empty/null, add() generates one.
    // Our Recipe model requires ID. So we trust the ID is set.
    await saveRecipe(recipe);
  }
}
