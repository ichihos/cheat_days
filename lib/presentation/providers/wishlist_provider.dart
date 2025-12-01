import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/wishlist_item.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/entities/restaurant.dart';
import 'firebase_providers.dart';
import 'auth_provider.dart';

final wishlistRepositoryProvider = Provider((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return ref.watch(firebaseWishlistRepositoryProvider);
});

final wishlistProvider = StateNotifierProvider<WishlistNotifier, AsyncValue<List<WishlistItem>>>((ref) {
  final repository = ref.watch(wishlistRepositoryProvider);
  final userAsync = ref.watch(currentUserProvider);

  return WishlistNotifier(
    repository,
    userAsync.value?.uid ?? '',
  );
});

class WishlistNotifier extends StateNotifier<AsyncValue<List<WishlistItem>>> {
  final dynamic _repository;
  final String _userId;
  final _uuid = const Uuid();

  WishlistNotifier(this._repository, this._userId) : super(const AsyncValue.loading()) {
    if (_userId.isNotEmpty) {
      loadWishlist();
    }
  }

  Future<void> loadWishlist() async {
    state = const AsyncValue.loading();
    try {
      final items = await _repository.getAllWishlistItems(_userId);
      state = AsyncValue.data(items);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addRecipeToWishlist({
    required Recipe recipe,
    required String cheatDayId,
    String? thumbnailUrl,
  }) async {
    try {
      final item = WishlistItem(
        id: _uuid.v4(),
        userId: _userId,
        type: WishlistItemType.recipe,
        referenceId: recipe.id,
        cheatDayId: cheatDayId,
        title: recipe.title,
        thumbnailUrl: thumbnailUrl,
        description: '${recipe.ingredients.length}個の材料 • ${recipe.cookingTimeMinutes}分',
        createdAt: DateTime.now(),
      );
      await _repository.addWishlistItem(item);
      await loadWishlist();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addRestaurantToWishlist({
    required Restaurant restaurant,
    required String cheatDayId,
    String? thumbnailUrl,
  }) async {
    try {
      final item = WishlistItem(
        id: _uuid.v4(),
        userId: _userId,
        type: WishlistItemType.restaurant,
        referenceId: restaurant.id,
        cheatDayId: cheatDayId,
        title: restaurant.name,
        thumbnailUrl: thumbnailUrl,
        description: restaurant.address,
        createdAt: DateTime.now(),
      );
      await _repository.addWishlistItem(item);
      await loadWishlist();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleCompletion(String id) async {
    try {
      await _repository.toggleCompletion(id);
      await loadWishlist();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> removeItem(String id) async {
    try {
      await _repository.deleteWishlistItem(id);
      await loadWishlist();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> isInWishlist(String referenceId) async {
    return await _repository.isItemInWishlist(_userId, referenceId);
  }
}
