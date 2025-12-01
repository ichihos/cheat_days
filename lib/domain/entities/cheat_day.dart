enum MediaType { image, video }

class CheatDay {
  final String id;
  final String title;
  final MediaType mediaType;
  final String mediaPath;
  final int? videoDurationSeconds;
  final DateTime date;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final List<String> likedBy;
  final bool isPublic;
  final bool hasRecipe;
  final bool hasRestaurant;

  CheatDay({
    required this.id,
    required this.title,
    this.mediaType = MediaType.image,
    required this.mediaPath,
    this.videoDurationSeconds,
    required this.date,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.likedBy = const [],
    this.isPublic = true,
    this.hasRecipe = false,
    this.hasRestaurant = false,
  });

  CheatDay copyWith({
    String? id,
    String? title,
    MediaType? mediaType,
    String? mediaPath,
    int? videoDurationSeconds,
    DateTime? date,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    List<String>? likedBy,
    bool? isPublic,
    bool? hasRecipe,
    bool? hasRestaurant,
  }) {
    return CheatDay(
      id: id ?? this.id,
      title: title ?? this.title,
      mediaType: mediaType ?? this.mediaType,
      mediaPath: mediaPath ?? this.mediaPath,
      videoDurationSeconds: videoDurationSeconds ?? this.videoDurationSeconds,
      date: date ?? this.date,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      likedBy: likedBy ?? this.likedBy,
      isPublic: isPublic ?? this.isPublic,
      hasRecipe: hasRecipe ?? this.hasRecipe,
      hasRestaurant: hasRestaurant ?? this.hasRestaurant,
    );
  }

  // Helper getters
  bool get isVideo => mediaType == MediaType.video;
  bool get isImage => mediaType == MediaType.image;
  String get imagePath => mediaPath; // backward compatibility
  String get description => title; // backward compatibility
}
