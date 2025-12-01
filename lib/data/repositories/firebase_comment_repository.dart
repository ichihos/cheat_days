import '../../domain/entities/comment.dart';
import '../../domain/repositories/comment_repository.dart';
import '../datasources/firestore_service.dart';
import '../models/comment_model.dart';

class FirebaseCommentRepository implements CommentRepository {
  final FirestoreService firestoreService;

  FirebaseCommentRepository(this.firestoreService);

  @override
  Future<List<Comment>> getComments(String cheatDayId) async {
    return await firestoreService.getComments(cheatDayId);
  }

  @override
  Future<void> addComment(Comment comment) async {
    await firestoreService.addComment(CommentModel.fromEntity(comment));
  }

  @override
  Future<void> deleteComment(String cheatDayId, String commentId) async {
    await firestoreService.deleteComment(cheatDayId, commentId);
  }
}
