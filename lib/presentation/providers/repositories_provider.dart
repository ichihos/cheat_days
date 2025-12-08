import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local_storage.dart';
import '../../data/datasources/firestore_service.dart';
import '../../data/repositories/firebase_cheat_day_repository.dart';
import '../../data/repositories/cheat_memo_repository_impl.dart';
import '../../domain/repositories/cheat_day_repository.dart';
import '../../domain/repositories/cheat_memo_repository.dart';

final localStorageProvider = Provider<LocalStorage>((ref) {
  return LocalStorage();
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final cheatDayRepositoryProvider = Provider<CheatDayRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return FirebaseCheatDayRepository(firestoreService);
});

final cheatMemoRepositoryProvider = Provider<CheatMemoRepository>((ref) {
  final localStorage = ref.watch(localStorageProvider);
  return CheatMemoRepositoryImpl(localStorage);
});
