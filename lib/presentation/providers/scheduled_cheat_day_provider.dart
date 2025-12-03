import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/scheduled_cheat_day.dart';
import 'auth_provider.dart';

final scheduledCheatDaysProvider = StreamProvider<List<ScheduledCheatDay>>((
  ref,
) {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection('scheduled_cheat_days')
      .where('userId', isEqualTo: currentUser.uid)
      .orderBy('scheduledDate', descending: false)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs
                .map(
                  (doc) =>
                      ScheduledCheatDay.fromJson({...doc.data(), 'id': doc.id}),
                )
                .toList(),
      );
});

/// 次のチートデイを取得
final nextCheatDayProvider = Provider<ScheduledCheatDay?>((ref) {
  final scheduledDays = ref.watch(scheduledCheatDaysProvider).value ?? [];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final futureDays =
      scheduledDays.where((day) {
        final scheduled = DateTime(
          day.scheduledDate.year,
          day.scheduledDate.month,
          day.scheduledDate.day,
        );
        return scheduled.isAfter(today) || scheduled.isAtSameMomentAs(today);
      }).toList();

  if (futureDays.isEmpty) return null;
  return futureDays.first;
});

/// 今日がチートデイかどうか
final isTodayCheatDayProvider = Provider<bool>((ref) {
  final nextCheatDay = ref.watch(nextCheatDayProvider);
  return nextCheatDay?.isToday ?? false;
});

/// チートデイまでの日数
final daysUntilCheatDayProvider = Provider<int?>((ref) {
  final nextCheatDay = ref.watch(nextCheatDayProvider);
  return nextCheatDay?.daysUntil;
});

class ScheduledCheatDayNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  ScheduledCheatDayNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> addScheduledCheatDay({
    required DateTime scheduledDate,
    String? planTitle,
    List<String> plannedItemIds = const [],
    String? memo,
  }) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) throw Exception('ログインが必要です');

    state = const AsyncValue.loading();
    try {
      final docRef =
          FirebaseFirestore.instance.collection('scheduled_cheat_days').doc();
      final scheduledDay = ScheduledCheatDay(
        id: docRef.id,
        userId: currentUser.uid,
        scheduledDate: scheduledDate,
        planTitle: planTitle,
        plannedItemIds: plannedItemIds,
        memo: memo,
        createdAt: DateTime.now(),
      );

      await docRef.set(scheduledDay.toJson());
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateScheduledCheatDay(ScheduledCheatDay scheduledDay) async {
    state = const AsyncValue.loading();
    try {
      await FirebaseFirestore.instance
          .collection('scheduled_cheat_days')
          .doc(scheduledDay.id)
          .update(scheduledDay.toJson());
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteScheduledCheatDay(String id) async {
    state = const AsyncValue.loading();
    try {
      await FirebaseFirestore.instance
          .collection('scheduled_cheat_days')
          .doc(id)
          .delete();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> markAsCompleted(String id, String cheatDayPostId) async {
    state = const AsyncValue.loading();
    try {
      await FirebaseFirestore.instance
          .collection('scheduled_cheat_days')
          .doc(id)
          .update({'isCompleted': true, 'cheatDayPostId': cheatDayPostId});
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final scheduledCheatDayNotifierProvider =
    StateNotifierProvider<ScheduledCheatDayNotifier, AsyncValue<void>>((ref) {
      return ScheduledCheatDayNotifier(ref);
    });
