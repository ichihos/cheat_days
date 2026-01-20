import 'package:cloud_firestore/cloud_firestore.dart';

class MealRecord {
  final String id;
  final String? recipeId;
  final String recipeName;
  final String? imageUrl;
  final String mealType; // breakfast, lunch, dinner, snack
  final DateTime date;
  final DateTime createdAt;

  MealRecord({
    required this.id,
    this.recipeId,
    required this.recipeName,
    this.imageUrl,
    required this.mealType,
    required this.date,
    required this.createdAt,
  });

  factory MealRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MealRecord(
      id: doc.id,
      recipeId: data['recipeId'],
      recipeName: data['recipeName'] ?? '',
      imageUrl: data['imageUrl'],
      mealType: data['mealType'] ?? 'dinner',
      date: (data['date'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipeId': recipeId,
      'recipeName': recipeName,
      'imageUrl': imageUrl,
      'mealType': mealType,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
