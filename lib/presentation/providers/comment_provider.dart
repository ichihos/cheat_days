import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/comment.dart';
import 'firebase_providers.dart';
import 'auth_provider.dart';

final commentsProvider = StateNotifierProvider.family<CommentsNotifier, AsyncValue<List<Comment>>, String>(
  (ref, cheatDayId) {
    final repository = ref.watch(commentRepositoryProvider);
    return CommentsNotifier(repository, cheatDayId);
  },
);

class CommentsNotifier extends StateNotifier<AsyncValue<List<Comment>>> {
  final dynamic _repository;
  final String _cheatDayId;
  final _uuid = const Uuid();

  CommentsNotifier(this._repository, this._cheatDayId) : super(const AsyncValue.loading()) {
    loadComments();
  }

  Future<void> loadComments() async {
    state = const AsyncValue.loading();
    try {
      final comments = await _repository.getComments(_cheatDayId);
      state = AsyncValue.data(comments);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addComment(String content, String userId, String userName, String? userPhotoUrl) async {
    try {
      final comment = Comment(
        id: _uuid.v4(),
        cheatDayId: _cheatDayId,
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        content: content,
        createdAt: DateTime.now(),
      );
      await _repository.addComment(comment);
      await loadComments();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await _repository.deleteComment(_cheatDayId, commentId);
      await loadComments();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
