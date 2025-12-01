import '../../domain/entities/restaurant.dart';

class RestaurantModel extends Restaurant {
  RestaurantModel({
    required super.id,
    required super.cheatDayId,
    required super.name,
    required super.address,
    super.phoneNumber,
    super.website,
    super.latitude,
    super.longitude,
    super.mapUrl,
    super.tags = const [],
    required super.createdAt,
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      id: json['id'] as String,
      cheatDayId: json['cheatDayId'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      website: json['website'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      mapUrl: json['mapUrl'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cheatDayId': cheatDayId,
      'name': name,
      'address': address,
      'phoneNumber': phoneNumber,
      'website': website,
      'latitude': latitude,
      'longitude': longitude,
      'mapUrl': mapUrl,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RestaurantModel.fromEntity(Restaurant entity) {
    return RestaurantModel(
      id: entity.id,
      cheatDayId: entity.cheatDayId,
      name: entity.name,
      address: entity.address,
      phoneNumber: entity.phoneNumber,
      website: entity.website,
      latitude: entity.latitude,
      longitude: entity.longitude,
      mapUrl: entity.mapUrl,
      tags: entity.tags,
      createdAt: entity.createdAt,
    );
  }
}
