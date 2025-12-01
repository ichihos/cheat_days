import '../../domain/entities/wishlist_item.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../datasources/firestore_service.dart';
import '../models/wishlist_item_model.dart';

class FirebaseWishlistRepository implements WishlistRepository {
  final FirestoreService firestoreService;

  FirebaseWishlistRepository(this.firestoreService);

  @override
  Future<List<WishlistItem>> getAllWishlistItems(String userId) async {
    return await firestoreService.getUserWishlist(userId);
  }

  @override
  Future<List<WishlistItem>> getWishlistItemsByType(
    String userId,
    WishlistItemType type,
  ) async {
    final allItems = await getAllWishlistItems(userId);
    return allItems.where((item) => item.type == type).toList();
  }

  @override
  Future<WishlistItem> getWishlistItemById(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<void> addWishlistItem(WishlistItem item) async {
    await firestoreService.addWishlistItem(
      item.userId,
      WishlistItemModel.fromEntity(item),
    );
  }

  @override
  Future<void> updateWishlistItem(WishlistItem item) async {
    await firestoreService.updateWishlistItem(
      item.userId,
      WishlistItemModel.fromEntity(item),
    );
  }

  @override
  Future<void> deleteWishlistItem(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<void> toggleCompletion(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> isItemInWishlist(String userId, String referenceId) async {
    final items = await getAllWishlistItems(userId);
    return items.any((item) => item.referenceId == referenceId);
  }
}
