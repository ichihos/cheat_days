import '../../domain/entities/comment.dart';

class CommentModel extends Comment {
  CommentModel({
    required super.id,
    required super.cheatDayId,
    required super.userId,
    required super.userName,
    super.userPhotoUrl,
    required super.content,
    required super.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String,
      cheatDayId: json['cheatDayId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userPhotoUrl: json['userPhotoUrl'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cheatDayId': cheatDayId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CommentModel.fromEntity(Comment entity) {
    return CommentModel(
      id: entity.id,
      cheatDayId: entity.cheatDayId,
      userId: entity.userId,
      userName: entity.userName,
      userPhotoUrl: entity.userPhotoUrl,
      content: entity.content,
      createdAt: entity.createdAt,
    );
  }
}
