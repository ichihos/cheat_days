import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/weight_record.dart';
import '../../domain/repositories/weight_repository.dart';

class FirebaseWeightRepository implements WeightRepository {
  final FirebaseFirestore _firestore;

  FirebaseWeightRepository(this._firestore);

  CollectionReference get _collection => _firestore.collection('weight_records');

  @override
  Future<void> addWeightRecord(WeightRecord record) async {
    await _collection.doc(record.id).set(record.toJson());
  }

  @override
  Future<void> updateWeightRecord(WeightRecord record) async {
    await _collection.doc(record.id).update(record.toJson());
  }

  @override
  Future<void> deleteWeightRecord(String id) async {
    await _collection.doc(id).delete();
  }

  @override
  Future<List<WeightRecord>> getWeightRecords(String userId) async {
    final querySnapshot = await _collection
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => WeightRecord.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<WeightRecord>> getWeightRecordsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final querySnapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
        .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
        .orderBy('date', descending: false)
        .get();

    return querySnapshot.docs
        .map((doc) => WeightRecord.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<WeightRecord?> getWeightRecordByDate(
    String userId,
    DateTime date,
  ) async {
    // 日付の開始と終了を取得
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final querySnapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('date', isLessThanOrEqualTo: endOfDay.toIso8601String())
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    return WeightRecord.fromJson(
      querySnapshot.docs.first.data() as Map<String, dynamic>,
    );
  }
}
