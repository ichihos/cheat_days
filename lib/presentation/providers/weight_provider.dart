import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/weight_record.dart';
import '../../domain/repositories/weight_repository.dart';
import 'firebase_providers.dart';
import '../../data/repositories/firebase_weight_repository.dart';

final weightRepositoryProvider = Provider<WeightRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirebaseWeightRepository(firestore);
});

final weightRecordsProvider = StateNotifierProvider<WeightRecordsNotifier,
    AsyncValue<List<WeightRecord>>>((ref) {
  final repository = ref.watch(weightRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider).value;
  return WeightRecordsNotifier(repository, currentUser?.uid);
});

class WeightRecordsNotifier extends StateNotifier<AsyncValue<List<WeightRecord>>> {
  final WeightRepository _repository;
  final String? _userId;
  final _uuid = const Uuid();

  WeightRecordsNotifier(this._repository, this._userId)
      : super(const AsyncValue.loading()) {
    if (_userId != null) {
      loadWeightRecords();
    }
  }

  Future<void> loadWeightRecords() async {
    if (_userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final records = await _repository.getWeightRecords(_userId!);
      state = AsyncValue.data(records);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addWeightRecord({
    required double weight,
    required DateTime date,
    String? memo,
  }) async {
    if (_userId == null) return;

    try {
      final record = WeightRecord(
        id: _uuid.v4(),
        userId: _userId!,
        weight: weight,
        date: date,
        memo: memo,
      );
      await _repository.addWeightRecord(record);
      await loadWeightRecords();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateWeightRecord(WeightRecord record) async {
    try {
      await _repository.updateWeightRecord(record);
      await loadWeightRecords();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteWeightRecord(String id) async {
    try {
      await _repository.deleteWeightRecord(id);
      await loadWeightRecords();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<List<WeightRecord>> getWeightRecordsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (_userId == null) return [];
    return await _repository.getWeightRecordsByDateRange(
      _userId!,
      startDate,
      endDate,
    );
  }

  Future<WeightRecord?> getWeightRecordByDate(DateTime date) async {
    if (_userId == null) return null;
    return await _repository.getWeightRecordByDate(_userId!, date);
  }
}
