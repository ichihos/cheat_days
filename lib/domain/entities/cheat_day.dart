class CheatDay {
  final String id;
  final String imagePath;
  final String description;
  final DateTime date;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final int likesCount;
  final int commentsCount;
  final List<String> likedBy;
  final bool isPublic;

  CheatDay({
    required this.id,
    required this.imagePath,
    required this.description,
    required this.date,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.likedBy = const [],
    this.isPublic = true,
  });

  CheatDay copyWith({
    String? id,
    String? imagePath,
    String? description,
    DateTime? date,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    int? likesCount,
    int? commentsCount,
    List<String>? likedBy,
    bool? isPublic,
  }) {
    return CheatDay(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      description: description ?? this.description,
      date: date ?? this.date,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      likedBy: likedBy ?? this.likedBy,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}
