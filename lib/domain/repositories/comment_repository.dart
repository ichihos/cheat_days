import '../entities/comment.dart';

abstract class CommentRepository {
  Future<List<Comment>> getComments(String cheatDayId);
  Future<void> addComment(Comment comment);
  Future<void> deleteComment(String cheatDayId, String commentId);
}
