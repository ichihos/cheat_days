import '../../domain/entities/cheat_memo.dart';
import '../../domain/repositories/cheat_memo_repository.dart';
import '../datasources/firestore_service.dart';
import '../models/cheat_memo_model.dart';

class FirebaseCheatMemoRepository implements CheatMemoRepository {
  final FirestoreService firestoreService;
  final String userId;

  FirebaseCheatMemoRepository(this.firestoreService, this.userId);

  @override
  Future<List<CheatMemo>> getAllMemos() async {
    return await firestoreService.getUserMemos(userId);
  }

  @override
  Future<CheatMemo> getMemoById(String id) async {
    final memos = await getAllMemos();
    return memos.firstWhere((memo) => memo.id == id);
  }

  @override
  Future<void> addMemo(CheatMemo memo) async {
    await firestoreService.addMemo(userId, CheatMemoModel.fromEntity(memo));
  }

  @override
  Future<void> updateMemo(CheatMemo memo) async {
    await firestoreService.updateMemo(userId, CheatMemoModel.fromEntity(memo));
  }

  @override
  Future<void> deleteMemo(String id) async {
    await firestoreService.deleteMemo(userId, id);
  }

  @override
  Future<void> toggleMemoCompletion(String id) async {
    final memo = await getMemoById(id);
    final updatedMemo = memo.copyWith(isCompleted: !memo.isCompleted);
    await updateMemo(updatedMemo);
  }
}
