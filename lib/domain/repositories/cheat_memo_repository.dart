import '../entities/cheat_memo.dart';

abstract class CheatMemoRepository {
  Future<List<CheatMemo>> getAllMemos();
  Future<CheatMemo> getMemoById(String id);
  Future<void> addMemo(CheatMemo memo);
  Future<void> updateMemo(CheatMemo memo);
  Future<void> deleteMemo(String id);
  Future<void> toggleMemoCompletion(String id);
}
