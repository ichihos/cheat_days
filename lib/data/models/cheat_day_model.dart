import '../../domain/entities/cheat_day.dart';

class CheatDayModel extends CheatDay {
  CheatDayModel({
    required super.id,
    required super.imagePath,
    required super.description,
    required super.date,
    required super.userId,
    required super.userName,
    super.userPhotoUrl,
    super.likesCount = 0,
    super.commentsCount = 0,
    super.likedBy = const [],
    super.isPublic = true,
  });

  factory CheatDayModel.fromJson(Map<String, dynamic> json) {
    return CheatDayModel(
      id: json['id'] as String,
      imagePath: json['imagePath'] as String,
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userPhotoUrl: json['userPhotoUrl'] as String?,
      likesCount: json['likesCount'] as int? ?? 0,
      commentsCount: json['commentsCount'] as int? ?? 0,
      likedBy: List<String>.from(json['likedBy'] ?? []),
      isPublic: json['isPublic'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'description': description,
      'date': date.toIso8601String(),
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'likedBy': likedBy,
      'isPublic': isPublic,
    };
  }

  factory CheatDayModel.fromEntity(CheatDay entity) {
    return CheatDayModel(
      id: entity.id,
      imagePath: entity.imagePath,
      description: entity.description,
      date: entity.date,
      userId: entity.userId,
      userName: entity.userName,
      userPhotoUrl: entity.userPhotoUrl,
      likesCount: entity.likesCount,
      commentsCount: entity.commentsCount,
      likedBy: entity.likedBy,
      isPublic: entity.isPublic,
    );
  }
}
