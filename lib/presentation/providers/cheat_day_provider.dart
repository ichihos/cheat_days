import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/cheat_day.dart';
import '../../data/datasources/local_storage.dart';
import 'repositories_provider.dart';

final cheatDaysProvider =
    StateNotifierProvider<CheatDaysNotifier, AsyncValue<List<CheatDay>>>((ref) {
      final repository = ref.watch(cheatDayRepositoryProvider);
      final localStorage = ref.watch(localStorageProvider);
      return CheatDaysNotifier(repository, localStorage);
    });

class CheatDaysNotifier extends StateNotifier<AsyncValue<List<CheatDay>>> {
  final dynamic _repository;
  final LocalStorage _localStorage;
  final _uuid = const Uuid();
  static const _cacheKey = 'cheat_days_cache';
  static const _cacheTimestampKey = 'cheat_days_cache_timestamp';
  static const _cacheDuration = Duration(hours: 1); // キャッシュの有効期限

  CheatDaysNotifier(this._repository, this._localStorage)
    : super(const AsyncValue.loading()) {
    _initializeWithCache();
  }

  /// キャッシュを使って即座に初期化し、バックグラウンドで最新データを取得
  Future<void> _initializeWithCache() async {
    try {
      // キャッシュからデータを読み込んで即座に表示
      final cachedData = await _loadFromCache();
      if (cachedData != null && cachedData.isNotEmpty) {
        state = AsyncValue.data(cachedData);
      }

      // バックグラウンドで最新データを取得
      await _fetchAndUpdateData();
    } catch (e, stack) {
      // キャッシュの読み込みに失敗した場合は通常の読み込み
      await loadCheatDays();
    }
  }

  /// キャッシュからデータを読み込み
  Future<List<CheatDay>?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      final timestamp = prefs.getInt(_cacheTimestampKey);

      if (cachedJson == null || timestamp == null) {
        return null;
      }

      // キャッシュが古すぎる場合は使用しない
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (cacheAge > _cacheDuration.inMilliseconds) {
        return null;
      }

      final List<dynamic> jsonList = jsonDecode(cachedJson);
      return jsonList.map((json) => CheatDay.fromJson(json)).toList();
    } catch (e) {
      // キャッシュの読み込みに失敗した場合はnullを返す
      return null;
    }
  }

  /// データをキャッシュに保存
  Future<void> _saveToCache(List<CheatDay> cheatDays) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = cheatDays.map((cd) => cd.toJson()).toList();
      await prefs.setString(_cacheKey, jsonEncode(jsonList));
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // キャッシュの保存に失敗しても処理を続行
    }
  }

  /// 最新データを取得して更新
  Future<void> _fetchAndUpdateData() async {
    try {
      final cheatDays = await _repository.getAllCheatDays();
      state = AsyncValue.data(cheatDays);
      await _saveToCache(cheatDays);
    } catch (e, stack) {
      // キャッシュが既に表示されている場合は、エラーを無視
      if (state is! AsyncData) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> loadCheatDays() async {
    state = const AsyncValue.loading();
    try {
      final cheatDays = await _repository.getAllCheatDays();
      state = AsyncValue.data(cheatDays);
      await _saveToCache(cheatDays);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addCheatDay({
    required File imageFile,
    required String description,
    required DateTime date,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    String? restaurantName,
    String? restaurantLocation,
    String? recipeText,
  }) async {
    try {
      final imagePath = await _localStorage.saveImage(imageFile);
      final cheatDay = CheatDay(
        id: _uuid.v4(),
        mediaPath: imagePath,
        title: description,
        date: date,
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        hasRestaurant: restaurantName != null && restaurantName.isNotEmpty,
        hasRecipe: recipeText != null && recipeText.isNotEmpty,
        restaurantName: restaurantName,
        restaurantLocation: restaurantLocation,
        recipeText: recipeText,
      );
      await _repository.addCheatDay(cheatDay);
      await loadCheatDays();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateCheatDay(CheatDay cheatDay) async {
    try {
      await _repository.updateCheatDay(cheatDay);
      await loadCheatDays();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteCheatDay(String id) async {
    try {
      await _repository.deleteCheatDay(id);
      await loadCheatDays();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// 楽観的UI更新用: サーバーに問い合わせずにローカル状態を更新
  void updateLocalState(List<CheatDay> cheatDays) {
    state = AsyncValue.data(cheatDays);
  }

  Future<List<CheatDay>> getCheatDaysByDate(DateTime date) async {
    return await _repository.getCheatDaysByDate(date);
  }

  Future<List<CheatDay>> getMyCheatDays(String userId) async {
    return await _repository.getMyCheatDays(userId);
  }
}
