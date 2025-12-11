import '../../domain/entities/wishlist_item.dart';

class WishlistItemModel extends WishlistItem {
  WishlistItemModel({
    required super.id,
    required super.userId,
    required super.type,
    required super.referenceId,
    required super.cheatDayId,
    required super.title,
    super.thumbnailUrl,
    super.description,
    required super.createdAt,
    super.isCompleted = false,
  });

  factory WishlistItemModel.fromJson(Map<String, dynamic> json) {
    WishlistItemType type;
    switch (json['type']) {
      case 'restaurant':
        type = WishlistItemType.restaurant;
        break;
      case 'cheatday':
        type = WishlistItemType.cheatday;
        break;
      default:
        type = WishlistItemType.recipe;
    }

    return WishlistItemModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: type,
      referenceId: json['referenceId'] as String,
      cheatDayId: json['cheatDayId'] as String,
      title: json['title'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    String typeString;
    switch (type) {
      case WishlistItemType.restaurant:
        typeString = 'restaurant';
        break;
      case WishlistItemType.cheatday:
        typeString = 'cheatday';
        break;
      case WishlistItemType.recipe:
        typeString = 'recipe';
        break;
    }

    return {
      'id': id,
      'userId': userId,
      'type': typeString,
      'referenceId': referenceId,
      'cheatDayId': cheatDayId,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory WishlistItemModel.fromEntity(WishlistItem entity) {
    return WishlistItemModel(
      id: entity.id,
      userId: entity.userId,
      type: entity.type,
      referenceId: entity.referenceId,
      cheatDayId: entity.cheatDayId,
      title: entity.title,
      thumbnailUrl: entity.thumbnailUrl,
      description: entity.description,
      createdAt: entity.createdAt,
      isCompleted: entity.isCompleted,
    );
  }
}
