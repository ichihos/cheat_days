enum WishlistItemType { recipe, restaurant }

class WishlistItem {
  final String id;
  final String userId;
  final WishlistItemType type;
  final String referenceId; // recipeId or restaurantId
  final String cheatDayId;
  final String title;
  final String? thumbnailUrl;
  final String? description;
  final DateTime createdAt;
  final bool isCompleted;

  WishlistItem({
    required this.id,
    required this.userId,
    required this.type,
    required this.referenceId,
    required this.cheatDayId,
    required this.title,
    this.thumbnailUrl,
    this.description,
    required this.createdAt,
    this.isCompleted = false,
  });

  WishlistItem copyWith({
    String? id,
    String? userId,
    WishlistItemType? type,
    String? referenceId,
    String? cheatDayId,
    String? title,
    String? thumbnailUrl,
    String? description,
    DateTime? createdAt,
    bool? isCompleted,
  }) {
    return WishlistItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      referenceId: referenceId ?? this.referenceId,
      cheatDayId: cheatDayId ?? this.cheatDayId,
      title: title ?? this.title,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  bool get isRecipe => type == WishlistItemType.recipe;
  bool get isRestaurant => type == WishlistItemType.restaurant;
}
