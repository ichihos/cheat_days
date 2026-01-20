import 'package:cloud_firestore/cloud_firestore.dart';

class UserSettings {
  final int servingSize;
  final List<String> dislikedIngredients;
  final List<String> dislikedCuisines;
  final String cookingFrequency;

  UserSettings({
    this.servingSize = 2,
    this.dislikedIngredients = const [],
    this.dislikedCuisines = const [],
    this.cookingFrequency = 'daily',
  });

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      servingSize: map['servingSize'] ?? 2,
      dislikedIngredients: List<String>.from(map['dislikedIngredients'] ?? []),
      dislikedCuisines: List<String>.from(map['dislikedCuisines'] ?? []),
      cookingFrequency: map['cookingFrequency'] ?? 'daily',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'servingSize': servingSize,
      'dislikedIngredients': dislikedIngredients,
      'dislikedCuisines': dislikedCuisines,
      'cookingFrequency': cookingFrequency,
    };
  }
}
