import '../../domain/entities/cheat_day.dart';

class CheatDayModel extends CheatDay {
  CheatDayModel({
    required super.id,
    required super.imagePath,
    required super.description,
    required super.date,
    required super.userId,
  });

  factory CheatDayModel.fromJson(Map<String, dynamic> json) {
    return CheatDayModel(
      id: json['id'] as String,
      imagePath: json['imagePath'] as String,
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
      userId: json['userId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'description': description,
      'date': date.toIso8601String(),
      'userId': userId,
    };
  }

  factory CheatDayModel.fromEntity(CheatDay entity) {
    return CheatDayModel(
      id: entity.id,
      imagePath: entity.imagePath,
      description: entity.description,
      date: entity.date,
      userId: entity.userId,
    );
  }
}
