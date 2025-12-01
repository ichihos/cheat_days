class CheatDay {
  final String id;
  final String imagePath;
  final String description;
  final DateTime date;
  final String userId;

  CheatDay({
    required this.id,
    required this.imagePath,
    required this.description,
    required this.date,
    required this.userId,
  });

  CheatDay copyWith({
    String? id,
    String? imagePath,
    String? description,
    DateTime? date,
    String? userId,
  }) {
    return CheatDay(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      description: description ?? this.description,
      date: date ?? this.date,
      userId: userId ?? this.userId,
    );
  }
}
