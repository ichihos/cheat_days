import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingItem {
  final String id;
  final String name;
  final bool isChecked;
  final bool isAiSuggested;
  final DateTime createdAt;

  ShoppingItem({
    required this.id,
    required this.name,
    this.isChecked = false,
    this.isAiSuggested = false,
    required this.createdAt,
  });

  factory ShoppingItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShoppingItem(
      id: doc.id,
      name: data['name'] ?? '',
      isChecked: data['isChecked'] ?? false,
      isAiSuggested: data['isAiSuggested'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isChecked': isChecked,
      'isAiSuggested': isAiSuggested,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ShoppingItem copyWith({
    String? id,
    String? name,
    bool? isChecked,
    bool? isAiSuggested,
    DateTime? createdAt,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      isChecked: isChecked ?? this.isChecked,
      isAiSuggested: isAiSuggested ?? this.isAiSuggested,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
