import '../entities/wishlist_item.dart';

abstract class WishlistRepository {
  Future<List<WishlistItem>> getAllWishlistItems(String userId);
  Future<List<WishlistItem>> getWishlistItemsByType(String userId, WishlistItemType type);
  Future<WishlistItem> getWishlistItemById(String id);
  Future<void> addWishlistItem(WishlistItem item);
  Future<void> updateWishlistItem(WishlistItem item);
  Future<void> deleteWishlistItem(String id);
  Future<void> toggleCompletion(String id);
  Future<bool> isItemInWishlist(String userId, String referenceId);
}
