import '../../domain/entities/cheat_day.dart';
import '../../domain/repositories/cheat_day_repository.dart';
import '../datasources/local_storage.dart';
import '../models/cheat_day_model.dart';

class CheatDayRepositoryImpl implements CheatDayRepository {
  final LocalStorage localStorage;

  CheatDayRepositoryImpl(this.localStorage);

  @override
  Future<List<CheatDay>> getAllCheatDays() async {
    return await localStorage.getCheatDays();
  }

  @override
  Future<List<CheatDay>> getCheatDaysByDate(DateTime date) async {
    final allDays = await localStorage.getCheatDays();
    return allDays.where((day) {
      return day.date.year == date.year &&
          day.date.month == date.month &&
          day.date.day == date.day;
    }).toList();
  }

  @override
  Future<CheatDay> getCheatDayById(String id) async {
    final allDays = await localStorage.getCheatDays();
    return allDays.firstWhere((day) => day.id == id);
  }

  @override
  Future<void> addCheatDay(CheatDay cheatDay) async {
    final allDays = await localStorage.getCheatDays();
    allDays.add(CheatDayModel.fromEntity(cheatDay));
    await localStorage.saveCheatDays(allDays);
  }

  @override
  Future<void> updateCheatDay(CheatDay cheatDay) async {
    final allDays = await localStorage.getCheatDays();
    final index = allDays.indexWhere((day) => day.id == cheatDay.id);
    if (index != -1) {
      allDays[index] = CheatDayModel.fromEntity(cheatDay);
      await localStorage.saveCheatDays(allDays);
    }
  }

  @override
  Future<void> deleteCheatDay(String id) async {
    final allDays = await localStorage.getCheatDays();
    final day = allDays.firstWhere((day) => day.id == id);
    await localStorage.deleteImage(day.imagePath);
    allDays.removeWhere((day) => day.id == id);
    await localStorage.saveCheatDays(allDays);
  }

  @override
  Future<List<CheatDay>> getMyCheatDays(String userId) async {
    final allDays = await localStorage.getCheatDays();
    return allDays.where((day) => day.userId == userId).toList();
  }
}
