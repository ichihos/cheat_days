class Restaurant {
  final String id;
  final String cheatDayId;
  final String name;
  final String address;
  final String? phoneNumber;
  final String? website;
  final double? latitude;
  final double? longitude;
  final String? mapUrl;
  final List<String> tags;
  final DateTime createdAt;

  Restaurant({
    required this.id,
    required this.cheatDayId,
    required this.name,
    required this.address,
    this.phoneNumber,
    this.website,
    this.latitude,
    this.longitude,
    this.mapUrl,
    this.tags = const [],
    required this.createdAt,
  });

  Restaurant copyWith({
    String? id,
    String? cheatDayId,
    String? name,
    String? address,
    String? phoneNumber,
    String? website,
    double? latitude,
    double? longitude,
    String? mapUrl,
    List<String>? tags,
    DateTime? createdAt,
  }) {
    return Restaurant(
      id: id ?? this.id,
      cheatDayId: cheatDayId ?? this.cheatDayId,
      name: name ?? this.name,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      mapUrl: mapUrl ?? this.mapUrl,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
