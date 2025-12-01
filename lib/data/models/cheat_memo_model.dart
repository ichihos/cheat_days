import '../../domain/entities/cheat_memo.dart';

class CheatMemoModel extends CheatMemo {
  CheatMemoModel({
    required super.id,
    required super.content,
    required super.createdAt,
    super.isCompleted = false,
  });

  factory CheatMemoModel.fromJson(Map<String, dynamic> json) {
    return CheatMemoModel(
      id: json['id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory CheatMemoModel.fromEntity(CheatMemo entity) {
    return CheatMemoModel(
      id: entity.id,
      content: entity.content,
      createdAt: entity.createdAt,
      isCompleted: entity.isCompleted,
    );
  }
}
