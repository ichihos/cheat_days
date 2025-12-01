import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/cheat_memo.dart';
import 'repositories_provider.dart';

final cheatMemosProvider = StateNotifierProvider<CheatMemosNotifier, AsyncValue<List<CheatMemo>>>((ref) {
  final repository = ref.watch(cheatMemoRepositoryProvider);
  return CheatMemosNotifier(repository);
});

class CheatMemosNotifier extends StateNotifier<AsyncValue<List<CheatMemo>>> {
  final dynamic _repository;
  final _uuid = const Uuid();

  CheatMemosNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadMemos();
  }

  Future<void> loadMemos() async {
    state = const AsyncValue.loading();
    try {
      final memos = await _repository.getAllMemos();
      state = AsyncValue.data(memos);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addMemo(String content) async {
    try {
      final memo = CheatMemo(
        id: _uuid.v4(),
        content: content,
        createdAt: DateTime.now(),
        isCompleted: false,
      );
      await _repository.addMemo(memo);
      await loadMemos();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleMemoCompletion(String id) async {
    try {
      await _repository.toggleMemoCompletion(id);
      await loadMemos();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteMemo(String id) async {
    try {
      await _repository.deleteMemo(id);
      await loadMemos();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
