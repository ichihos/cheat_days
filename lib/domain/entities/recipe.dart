class Recipe {
  final String id;
  final String cheatDayId;
  final String title;
  final List<String> ingredients;
  final List<String> steps;
  final int cookingTimeMinutes;
  final int servings;
  final DateTime createdAt;

  Recipe({
    required this.id,
    required this.cheatDayId,
    required this.title,
    required this.ingredients,
    required this.steps,
    required this.cookingTimeMinutes,
    required this.servings,
    required this.createdAt,
  });

  Recipe copyWith({
    String? id,
    String? cheatDayId,
    String? title,
    List<String>? ingredients,
    List<String>? steps,
    int? cookingTimeMinutes,
    int? servings,
    DateTime? createdAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      cheatDayId: cheatDayId ?? this.cheatDayId,
      title: title ?? this.title,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      cookingTimeMinutes: cookingTimeMinutes ?? this.cookingTimeMinutes,
      servings: servings ?? this.servings,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
