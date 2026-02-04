import 'package:cloud_firestore/cloud_firestore.dart';
import 'recipe.dart';

/// ユーザーごとにカスタマイズされたレシピ
/// メッシーの調整（食材変更など）を保持する
class CustomizedRecipe {
  final String id;
  final String originalRecipeId;
  final String date; // ISO date string (e.g., "2025-01-26")
  final Recipe recipe; // カスタマイズされたレシピ内容
  final List<RecipeAdjustmentLog> adjustmentHistory;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomizedRecipe({
    required this.id,
    required this.originalRecipeId,
    required this.date,
    required this.recipe,
    this.adjustmentHistory = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomizedRecipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomizedRecipe(
      id: doc.id,
      originalRecipeId: data['originalRecipeId'] ?? '',
      date: data['date'] ?? '',
      recipe: Recipe(
        id: data['recipe']['id'] ?? '',
        name: data['recipe']['name'] ?? '',
        imageUrl: data['recipe']['imageUrl'] ?? '',
        category: data['recipe']['category'] ?? 'main',
        cuisine: data['recipe']['cuisine'] ?? 'japanese',
        timeMinutes: data['recipe']['timeMinutes'] ?? 0,
        costYen: data['recipe']['costYen'] ?? 0,
        difficulty: data['recipe']['difficulty'] ?? 1,
        seasons: List<String>.from(data['recipe']['seasons'] ?? []),
        calories: data['recipe']['calories'],
        ingredients:
            (data['recipe']['ingredients'] as List<dynamic>?)
                ?.map((e) => Ingredient.fromMap(e as Map<String, dynamic>))
                .toList() ??
            [],
        steps: List<String>.from(data['recipe']['steps'] ?? []),
        tags: List<String>.from(data['recipe']['tags'] ?? []),
        createdAt:
            data['recipe']['createdAt'] != null
                ? (data['recipe']['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
      ),
      adjustmentHistory:
          (data['adjustmentHistory'] as List<dynamic>?)
              ?.map(
                (e) =>
                    RecipeAdjustmentLog.fromMap(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'originalRecipeId': originalRecipeId,
      'date': date,
      'recipe': {
        'id': recipe.id,
        'name': recipe.name,
        'imageUrl': recipe.imageUrl,
        'category': recipe.category,
        'cuisine': recipe.cuisine,
        'timeMinutes': recipe.timeMinutes,
        'costYen': recipe.costYen,
        'difficulty': recipe.difficulty,
        'seasons': recipe.seasons,
        'calories': recipe.calories,
        'ingredients': recipe.ingredients.map((e) => e.toMap()).toList(),
        'steps': recipe.steps,
        'tags': recipe.tags,
        'createdAt': Timestamp.fromDate(recipe.createdAt),
      },
      'adjustmentHistory': adjustmentHistory.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  CustomizedRecipe copyWith({
    String? id,
    String? originalRecipeId,
    String? date,
    Recipe? recipe,
    List<RecipeAdjustmentLog>? adjustmentHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomizedRecipe(
      id: id ?? this.id,
      originalRecipeId: originalRecipeId ?? this.originalRecipeId,
      date: date ?? this.date,
      recipe: recipe ?? this.recipe,
      adjustmentHistory: adjustmentHistory ?? this.adjustmentHistory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// オリジナルレシピから新しいCustomizedRecipeを作成
  factory CustomizedRecipe.fromOriginal({
    required Recipe original,
    required String date,
  }) {
    final now = DateTime.now();
    return CustomizedRecipe(
      id: '',
      originalRecipeId: original.id,
      date: date,
      recipe: original,
      adjustmentHistory: [],
      createdAt: now,
      updatedAt: now,
    );
  }
}

/// レシピ調整の履歴ログ
class RecipeAdjustmentLog {
  final String type; // scale, substitute, remove
  final String description;
  final DateTime timestamp;

  RecipeAdjustmentLog({
    required this.type,
    required this.description,
    required this.timestamp,
  });

  factory RecipeAdjustmentLog.fromMap(Map<String, dynamic> map) {
    return RecipeAdjustmentLog(
      type: map['type'] ?? '',
      description: map['description'] ?? '',
      timestamp:
          map['timestamp'] != null
              ? (map['timestamp'] as Timestamp).toDate()
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
