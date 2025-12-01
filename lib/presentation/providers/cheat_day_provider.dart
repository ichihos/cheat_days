import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/cheat_day.dart';
import '../../data/datasources/local_storage.dart';
import 'repositories_provider.dart';

final cheatDaysProvider = StateNotifierProvider<CheatDaysNotifier, AsyncValue<List<CheatDay>>>((ref) {
  final repository = ref.watch(cheatDayRepositoryProvider);
  final localStorage = ref.watch(localStorageProvider);
  return CheatDaysNotifier(repository, localStorage);
});

class CheatDaysNotifier extends StateNotifier<AsyncValue<List<CheatDay>>> {
  final dynamic _repository;
  final LocalStorage _localStorage;
  final _uuid = const Uuid();

  CheatDaysNotifier(this._repository, this._localStorage) : super(const AsyncValue.loading()) {
    loadCheatDays();
  }

  Future<void> loadCheatDays() async {
    state = const AsyncValue.loading();
    try {
      final cheatDays = await _repository.getAllCheatDays();
      state = AsyncValue.data(cheatDays);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addCheatDay({
    required File imageFile,
    required String description,
    required DateTime date,
    required String userId,
  }) async {
    try {
      final imagePath = await _localStorage.saveImage(imageFile);
      final cheatDay = CheatDay(
        id: _uuid.v4(),
        imagePath: imagePath,
        description: description,
        date: date,
        userId: userId,
      );
      await _repository.addCheatDay(cheatDay);
      await loadCheatDays();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteCheatDay(String id) async {
    try {
      await _repository.deleteCheatDay(id);
      await loadCheatDays();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<List<CheatDay>> getCheatDaysByDate(DateTime date) async {
    return await _repository.getCheatDaysByDate(date);
  }

  Future<List<CheatDay>> getMyCheatDays(String userId) async {
    return await _repository.getMyCheatDays(userId);
  }
}
