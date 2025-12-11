import '../../domain/entities/cheat_day.dart';

class CheatDayModel extends CheatDay {
  CheatDayModel({
    required super.id,
    required super.title,
    super.mediaType = MediaType.image,
    required super.mediaPath,
    super.videoDurationSeconds,
    required super.date,
    required super.userId,
    required super.userName,
    super.userPhotoUrl,
    super.likesCount = 0,
    super.commentsCount = 0,
    super.sharesCount = 0,
    super.likedBy = const [],
    super.isPublic = true,
    super.hasRecipe = false,
    super.hasRestaurant = false,
    super.restaurantName,
    super.restaurantLocation,
    super.recipeText,
  });

  factory CheatDayModel.fromJson(Map<String, dynamic> json) {
    return CheatDayModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? json['description'] as String? ?? '',
      mediaType:
          json['mediaType'] == 'video' ? MediaType.video : MediaType.image,
      mediaPath:
          json['mediaPath'] as String? ?? json['imagePath'] as String? ?? '',
      videoDurationSeconds: json['videoDurationSeconds'] as int?,
      date: DateTime.parse(json['date'] as String),
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userPhotoUrl: json['userPhotoUrl'] as String?,
      likesCount: json['likesCount'] as int? ?? 0,
      commentsCount: json['commentsCount'] as int? ?? 0,
      sharesCount: json['sharesCount'] as int? ?? 0,
      likedBy: List<String>.from(json['likedBy'] ?? []),
      isPublic: json['isPublic'] as bool? ?? true,
      hasRecipe: json['hasRecipe'] as bool? ?? false,
      hasRestaurant: json['hasRestaurant'] as bool? ?? false,
      restaurantName: json['restaurantName'] as String?,
      restaurantLocation: json['restaurantLocation'] as String?,
      recipeText: json['recipeText'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'mediaType': mediaType == MediaType.video ? 'video' : 'image',
      'mediaPath': mediaPath,
      'videoDurationSeconds': videoDurationSeconds,
      'date': date.toIso8601String(),
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'likedBy': likedBy,
      'isPublic': isPublic,
      'hasRecipe': hasRecipe,
      'hasRestaurant': hasRestaurant,
      'restaurantName': restaurantName,
      'restaurantLocation': restaurantLocation,
      'recipeText': recipeText,
    };
  }

  factory CheatDayModel.fromEntity(CheatDay entity) {
    return CheatDayModel(
      id: entity.id,
      title: entity.title,
      mediaType: entity.mediaType,
      mediaPath: entity.mediaPath,
      videoDurationSeconds: entity.videoDurationSeconds,
      date: entity.date,
      userId: entity.userId,
      userName: entity.userName,
      userPhotoUrl: entity.userPhotoUrl,
      likesCount: entity.likesCount,
      commentsCount: entity.commentsCount,
      sharesCount: entity.sharesCount,
      likedBy: entity.likedBy,
      isPublic: entity.isPublic,
      hasRecipe: entity.hasRecipe,
      hasRestaurant: entity.hasRestaurant,
      restaurantName: entity.restaurantName,
      restaurantLocation: entity.restaurantLocation,
      recipeText: entity.recipeText,
    );
  }
}
