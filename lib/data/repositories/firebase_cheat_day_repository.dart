import 'dart:io';
import '../../domain/entities/cheat_day.dart';
import '../../domain/repositories/cheat_day_repository.dart';
import '../datasources/firestore_service.dart';
import '../models/cheat_day_model.dart';

class FirebaseCheatDayRepository implements CheatDayRepository {
  final FirestoreService firestoreService;

  FirebaseCheatDayRepository(this.firestoreService);

  @override
  Future<List<CheatDay>> getAllCheatDays() async {
    return await firestoreService.getAllPublicCheatDays();
  }

  @override
  Future<List<CheatDay>> getCheatDaysByDate(DateTime date) async {
    return await firestoreService.getCheatDaysByDate(date);
  }

  @override
  Future<CheatDay> getCheatDayById(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<void> addCheatDay(CheatDay cheatDay) async {
    await firestoreService.addCheatDay(CheatDayModel.fromEntity(cheatDay));
  }

  Future<void> addCheatDayWithImage(File imageFile, CheatDay cheatDay) async {
    final imageUrl = await firestoreService.uploadImage(
      imageFile,
      cheatDay.userId,
    );
    final cheatDayWithUrl = cheatDay.copyWith(mediaPath: imageUrl);
    await firestoreService.addCheatDay(
      CheatDayModel.fromEntity(cheatDayWithUrl),
    );
  }

  @override
  Future<void> updateCheatDay(CheatDay cheatDay) async {
    await firestoreService.updateCheatDay(CheatDayModel.fromEntity(cheatDay));
  }

  @override
  Future<void> deleteCheatDay(String id) async {
    final cheatDays = await firestoreService.getAllPublicCheatDays();
    final cheatDay = cheatDays.firstWhere((day) => day.id == id);
    await firestoreService.deleteCheatDay(id, cheatDay.imagePath);
  }

  @override
  Future<List<CheatDay>> getMyCheatDays(String userId) async {
    return await firestoreService.getUserCheatDays(userId);
  }

  Future<void> toggleLike(String cheatDayId, String userId) async {
    await firestoreService.toggleLike(cheatDayId, userId);
  }
}
