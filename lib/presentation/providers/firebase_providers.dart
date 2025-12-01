import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/firestore_service.dart';
import '../../data/datasources/notification_service.dart';
import '../../data/repositories/firebase_cheat_day_repository.dart';
import '../../data/repositories/firebase_cheat_memo_repository.dart';
import '../../data/repositories/firebase_comment_repository.dart';
import '../../domain/repositories/cheat_day_repository.dart';
import '../../domain/repositories/cheat_memo_repository.dart';
import '../../domain/repositories/comment_repository.dart';
import 'auth_provider.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final firebaseCheatDayRepositoryProvider = Provider<CheatDayRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return FirebaseCheatDayRepository(firestoreService);
});

final firebaseCheatMemoRepositoryProvider = Provider<CheatMemoRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final userAsync = ref.watch(currentUserProvider);

  return userAsync.when(
    data: (user) {
      if (user == null) throw Exception('User not authenticated');
      return FirebaseCheatMemoRepository(firestoreService, user.uid);
    },
    loading: () => throw Exception('Loading user'),
    error: (e, _) => throw e,
  );
});

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return FirebaseCommentRepository(firestoreService);
});
