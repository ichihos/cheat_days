/// チートデイの予定（事前登録）
class ScheduledCheatDay {
  final String id;
  final String userId;
  final DateTime scheduledDate;
  final String? planTitle; // 何を食べるか
  final List<String> plannedItemIds; // 保存リストから選んだアイテムのID
  final String? memo;
  final bool isCompleted; // 投稿済みかどうか
  final String? cheatDayPostId; // 投稿したCheatDayのID
  final DateTime createdAt;

  ScheduledCheatDay({
    required this.id,
    required this.userId,
    required this.scheduledDate,
    this.planTitle,
    this.plannedItemIds = const [],
    this.memo,
    this.isCompleted = false,
    this.cheatDayPostId,
    required this.createdAt,
  });

  ScheduledCheatDay copyWith({
    String? id,
    String? userId,
    DateTime? scheduledDate,
    String? planTitle,
    List<String>? plannedItemIds,
    String? memo,
    bool? isCompleted,
    String? cheatDayPostId,
    DateTime? createdAt,
  }) {
    return ScheduledCheatDay(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      planTitle: planTitle ?? this.planTitle,
      plannedItemIds: plannedItemIds ?? this.plannedItemIds,
      memo: memo ?? this.memo,
      isCompleted: isCompleted ?? this.isCompleted,
      cheatDayPostId: cheatDayPostId ?? this.cheatDayPostId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// 今日がチートデイかどうか
  bool get isToday {
    final now = DateTime.now();
    return scheduledDate.year == now.year &&
        scheduledDate.month == now.month &&
        scheduledDate.day == now.day;
  }

  /// チートデイまでの残り日数（過去の場合は負の値）
  int get daysUntil {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scheduled = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
    );
    return scheduled.difference(today).inDays;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'scheduledDate': scheduledDate.toIso8601String(),
      'planTitle': planTitle,
      'plannedItemIds': plannedItemIds,
      'memo': memo,
      'isCompleted': isCompleted,
      'cheatDayPostId': cheatDayPostId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ScheduledCheatDay.fromJson(Map<String, dynamic> json) {
    return ScheduledCheatDay(
      id: json['id'] as String,
      userId: json['userId'] as String,
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      planTitle: json['planTitle'] as String?,
      plannedItemIds:
          (json['plannedItemIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      memo: json['memo'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      cheatDayPostId: json['cheatDayPostId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
