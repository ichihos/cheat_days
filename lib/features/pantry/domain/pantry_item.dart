import 'package:cloud_firestore/cloud_firestore.dart';

class PantryItem {
  final String id;
  final String ingredientName;
  final String estimatedAmount; // "ある", "少し", "なし"
  final DateTime? lastPurchased;
  final DateTime? lastUsed;

  PantryItem({
    required this.id,
    required this.ingredientName,
    required this.estimatedAmount,
    this.lastPurchased,
    this.lastUsed,
  });

  factory PantryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PantryItem(
      id: doc.id,
      ingredientName: data['ingredientName'] ?? '',
      estimatedAmount: data['estimatedAmount'] ?? 'ある',
      lastPurchased:
          data['lastPurchased'] != null
              ? (data['lastPurchased'] as Timestamp).toDate()
              : null,
      lastUsed:
          data['lastUsed'] != null
              ? (data['lastUsed'] as Timestamp).toDate()
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ingredientName': ingredientName,
      'estimatedAmount': estimatedAmount,
      'lastPurchased':
          lastPurchased != null ? Timestamp.fromDate(lastPurchased!) : null,
      'lastUsed': lastUsed != null ? Timestamp.fromDate(lastUsed!) : null,
    };
  }
}
