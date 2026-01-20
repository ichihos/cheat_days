import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/meal_record.dart';

final mealRecordRepositoryProvider = Provider<MealRecordRepository>((ref) {
  return MealRecordRepository(FirebaseFirestore.instance);
});

class MealRecordRepository {
  final FirebaseFirestore _firestore;

  MealRecordRepository(this._firestore);

  Stream<List<MealRecord>> streamRecords(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('mealRecords')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => MealRecord.fromFirestore(doc))
                  .toList(),
        );
  }

  Future<void> addRecord(String userId, MealRecord record) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('mealRecords')
        .add(record.toMap());
  }
}
