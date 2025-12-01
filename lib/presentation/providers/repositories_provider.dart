import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local_storage.dart';
import '../../data/repositories/cheat_day_repository_impl.dart';
import '../../data/repositories/cheat_memo_repository_impl.dart';
import '../../domain/repositories/cheat_day_repository.dart';
import '../../domain/repositories/cheat_memo_repository.dart';

final localStorageProvider = Provider<LocalStorage>((ref) {
  return LocalStorage();
});

final cheatDayRepositoryProvider = Provider<CheatDayRepository>((ref) {
  final localStorage = ref.watch(localStorageProvider);
  return CheatDayRepositoryImpl(localStorage);
});

final cheatMemoRepositoryProvider = Provider<CheatMemoRepository>((ref) {
  final localStorage = ref.watch(localStorageProvider);
  return CheatMemoRepositoryImpl(localStorage);
});
