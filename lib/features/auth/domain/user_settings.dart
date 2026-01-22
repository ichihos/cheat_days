class UserSettings {
  final int servingSize;
  final List<String> dislikedIngredients;
  final List<String> dislikedCuisines;
  final String cookingFrequency;
  final bool isOnboardingComplete;
  final int totalRecordsCount;
  final DateTime? lastRecordDate;

  UserSettings({
    this.servingSize = 2,
    this.dislikedIngredients = const [],
    this.dislikedCuisines = const [],
    this.cookingFrequency = 'daily',
    this.isOnboardingComplete = false,
    this.totalRecordsCount = 0,
    this.lastRecordDate,
  });

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      servingSize: map['servingSize'] ?? 2,
      dislikedIngredients: List<String>.from(map['dislikedIngredients'] ?? []),
      dislikedCuisines: List<String>.from(map['dislikedCuisines'] ?? []),
      cookingFrequency: map['cookingFrequency'] ?? 'daily',
      isOnboardingComplete: map['isOnboardingComplete'] ?? false,
      totalRecordsCount: map['totalRecordsCount'] ?? 0,
      lastRecordDate:
          map['lastRecordDate'] != null
              ? DateTime.tryParse(map['lastRecordDate'])
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'servingSize': servingSize,
      'dislikedIngredients': dislikedIngredients,
      'dislikedCuisines': dislikedCuisines,
      'cookingFrequency': cookingFrequency,
      'isOnboardingComplete': isOnboardingComplete,
      'totalRecordsCount': totalRecordsCount,
      'lastRecordDate': lastRecordDate?.toIso8601String(),
    };
  }

  UserSettings copyWith({
    int? servingSize,
    List<String>? dislikedIngredients,
    List<String>? dislikedCuisines,
    String? cookingFrequency,
    bool? isOnboardingComplete,
    int? totalRecordsCount,
    DateTime? lastRecordDate,
  }) {
    return UserSettings(
      servingSize: servingSize ?? this.servingSize,
      dislikedIngredients: dislikedIngredients ?? this.dislikedIngredients,
      dislikedCuisines: dislikedCuisines ?? this.dislikedCuisines,
      cookingFrequency: cookingFrequency ?? this.cookingFrequency,
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
      totalRecordsCount: totalRecordsCount ?? this.totalRecordsCount,
      lastRecordDate: lastRecordDate ?? this.lastRecordDate,
    );
  }
}
