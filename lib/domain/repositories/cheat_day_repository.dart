import '../entities/cheat_day.dart';

abstract class CheatDayRepository {
  Future<List<CheatDay>> getAllCheatDays();
  Future<List<CheatDay>> getCheatDaysByDate(DateTime date);
  Future<CheatDay> getCheatDayById(String id);
  Future<void> addCheatDay(CheatDay cheatDay);
  Future<void> updateCheatDay(CheatDay cheatDay);
  Future<void> deleteCheatDay(String id);
  Future<List<CheatDay>> getMyCheatDays(String userId);
}
