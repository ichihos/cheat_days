import 'package:cloud_firestore/cloud_firestore.dart';

class Recipe {
  final String id;
  final String name;
  final String imageUrl;
  final String category; // main, side, soup, rice, noodle
  final String cuisine; // japanese, western, chinese, korean, other
  final int timeMinutes;
  final int costYen;
  final int difficulty; // 1-3
  final List<String> seasons;
  final int? calories;
  final List<Ingredient> ingredients;
  final List<String> steps;
  final List<String> tags;
  final DateTime createdAt;

  Recipe({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.cuisine,
    required this.timeMinutes,
    required this.costYen,
    required this.difficulty,
    required this.seasons,
    this.calories,
    required this.ingredients,
    required this.steps,
    required this.tags,
    required this.createdAt,
  });

  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Recipe(
      id: doc.id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? 'main',
      cuisine: data['cuisine'] ?? 'japanese',
      timeMinutes: data['timeMinutes'] ?? 0,
      costYen: data['costYen'] ?? 0,
      difficulty: data['difficulty'] ?? 1,
      seasons: List<String>.from(data['seasons'] ?? []),
      calories: data['calories'],
      ingredients:
          (data['ingredients'] as List<dynamic>?)
              ?.map((e) => Ingredient.fromMap(e))
              .toList() ??
          [],
      steps: List<String>.from(data['steps'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'category': category,
      'cuisine': cuisine,
      'timeMinutes': timeMinutes,
      'costYen': costYen,
      'difficulty': difficulty,
      'seasons': seasons,
      'calories': calories,
      'ingredients': ingredients.map((e) => e.toMap()).toList(),
      'steps': steps,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class Ingredient {
  final String name;
  final String amount;
  final String
  unit; // Ideally separate, but spec says "amount" as number/string mix in UI might need care. Spec says number. Let's stick to string for "amount" to be flexible or custom. Spec: amount: number. Let's check spec.
  // Spec: amount: number, unit: string.
  // Wait, I will use dynamic or specific types. Ideally double.
  final bool isMain;

  Ingredient({
    required this.name,
    required this.amount,
    required this.unit,
    required this.isMain,
  });

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      name: map['name'] ?? '',
      amount:
          map['amount']?.toString() ??
          '0', // Handle as string for safety in UI display
      unit: map['unit'] ?? '',
      isMain: map['isMain'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount, // Store as is
      'unit': unit,
      'isMain': isMain,
    };
  }

  Ingredient copyWith({
    String? name,
    String? amount,
    String? unit,
    bool? isMain,
  }) {
    return Ingredient(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      isMain: isMain ?? this.isMain,
    );
  }
}
