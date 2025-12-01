import '../../domain/entities/recipe.dart';

class RecipeModel extends Recipe {
  RecipeModel({
    required super.id,
    required super.cheatDayId,
    required super.title,
    required super.ingredients,
    required super.steps,
    required super.cookingTimeMinutes,
    required super.servings,
    required super.createdAt,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      id: json['id'] as String,
      cheatDayId: json['cheatDayId'] as String,
      title: json['title'] as String,
      ingredients: List<String>.from(json['ingredients'] ?? []),
      steps: List<String>.from(json['steps'] ?? []),
      cookingTimeMinutes: json['cookingTimeMinutes'] as int,
      servings: json['servings'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cheatDayId': cheatDayId,
      'title': title,
      'ingredients': ingredients,
      'steps': steps,
      'cookingTimeMinutes': cookingTimeMinutes,
      'servings': servings,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RecipeModel.fromEntity(Recipe entity) {
    return RecipeModel(
      id: entity.id,
      cheatDayId: entity.cheatDayId,
      title: entity.title,
      ingredients: entity.ingredients,
      steps: entity.steps,
      cookingTimeMinutes: entity.cookingTimeMinutes,
      servings: entity.servings,
      createdAt: entity.createdAt,
    );
  }
}
