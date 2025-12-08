class WeightRecord {
  final String id;
  final String userId;
  final double weight; // kg
  final DateTime date;
  final String? memo;

  WeightRecord({
    required this.id,
    required this.userId,
    required this.weight,
    required this.date,
    this.memo,
  });

  WeightRecord copyWith({
    String? id,
    String? userId,
    double? weight,
    DateTime? date,
    String? memo,
  }) {
    return WeightRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      weight: weight ?? this.weight,
      date: date ?? this.date,
      memo: memo ?? this.memo,
    );
  }

  // JSON serialization for caching and Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'weight': weight,
      'date': date.toIso8601String(),
      'memo': memo,
    };
  }

  factory WeightRecord.fromJson(Map<String, dynamic> json) {
    return WeightRecord(
      id: json['id'] as String,
      userId: json['userId'] as String,
      weight: (json['weight'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      memo: json['memo'] as String?,
    );
  }
}
