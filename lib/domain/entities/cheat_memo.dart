class CheatMemo {
  final String id;
  final String content;
  final DateTime createdAt;
  final bool isCompleted;

  CheatMemo({
    required this.id,
    required this.content,
    required this.createdAt,
    this.isCompleted = false,
  });

  CheatMemo copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    bool? isCompleted,
  }) {
    return CheatMemo(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
