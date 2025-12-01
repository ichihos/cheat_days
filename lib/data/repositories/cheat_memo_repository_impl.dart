import '../../domain/entities/cheat_memo.dart';
import '../../domain/repositories/cheat_memo_repository.dart';
import '../datasources/local_storage.dart';
import '../models/cheat_memo_model.dart';

class CheatMemoRepositoryImpl implements CheatMemoRepository {
  final LocalStorage localStorage;

  CheatMemoRepositoryImpl(this.localStorage);

  @override
  Future<List<CheatMemo>> getAllMemos() async {
    return await localStorage.getCheatMemos();
  }

  @override
  Future<CheatMemo> getMemoById(String id) async {
    final allMemos = await localStorage.getCheatMemos();
    return allMemos.firstWhere((memo) => memo.id == id);
  }

  @override
  Future<void> addMemo(CheatMemo memo) async {
    final allMemos = await localStorage.getCheatMemos();
    allMemos.add(CheatMemoModel.fromEntity(memo));
    await localStorage.saveCheatMemos(allMemos);
  }

  @override
  Future<void> updateMemo(CheatMemo memo) async {
    final allMemos = await localStorage.getCheatMemos();
    final index = allMemos.indexWhere((m) => m.id == memo.id);
    if (index != -1) {
      allMemos[index] = CheatMemoModel.fromEntity(memo);
      await localStorage.saveCheatMemos(allMemos);
    }
  }

  @override
  Future<void> deleteMemo(String id) async {
    final allMemos = await localStorage.getCheatMemos();
    allMemos.removeWhere((memo) => memo.id == id);
    await localStorage.saveCheatMemos(allMemos);
  }

  @override
  Future<void> toggleMemoCompletion(String id) async {
    final allMemos = await localStorage.getCheatMemos();
    final index = allMemos.indexWhere((memo) => memo.id == id);
    if (index != -1) {
      final memo = allMemos[index];
      allMemos[index] = CheatMemoModel.fromEntity(
        memo.copyWith(isCompleted: !memo.isCompleted),
      );
      await localStorage.saveCheatMemos(allMemos);
    }
  }
}
