class Attraction {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final double rating;
  final String crowdLevel; // e.g. 'Low', 'Medium', 'High'
  final int availableSlots;
  final double latitude;
  final double longitude;
  final String location; // human-readable address/area
  final List<String> imageUrls;
  final String openingHours; // e.g. "9:00 AM - 6:00 PM"
  final List<String> facilities; // e.g. ['Parking', 'Wheelchair Access']
  final bool isAccessible;
  final String operatingStatus; // 'Open', 'Closed', 'Full'
  final DateTime? crowdUpdatedAt; // for stale crowd data fallback (UC-M2-13 alt flow)

  Attraction({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.rating,
    required this.crowdLevel,
    required this.availableSlots,
    required this.latitude,
    required this.longitude,
    required this.location,
    required this.imageUrls,
    required this.openingHours,
    required this.facilities,
    required this.isAccessible,
    required this.operatingStatus,
    this.crowdUpdatedAt,
  });

  // Convert a Supabase row (Map) into an Attraction object
  factory Attraction.fromMap(Map<String, dynamic> map) {
    return Attraction(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      crowdLevel: map['crowd_level'] as String? ?? 'Unknown',
      availableSlots: map['available_slots'] as int? ?? 0,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      location: map['location'] as String? ?? '',
      imageUrls: (map['image_urls'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      openingHours: map['opening_hours'] as String? ?? '',
      facilities: (map['facilities'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      isAccessible: map['is_accessible'] as bool? ?? false,
      operatingStatus: map['operating_status'] as String? ?? 'Open',
      crowdUpdatedAt: map['crowd_updated_at'] != null
          ? DateTime.tryParse(map['crowd_updated_at'] as String)
          : null,
    );
  }

  // Convert an Attraction object back into a Map (e.g. for updates)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'rating': rating,
      'crowd_level': crowdLevel,
      'available_slots': availableSlots,
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
      'image_urls': imageUrls,
      'opening_hours': openingHours,
      'facilities': facilities,
      'is_accessible': isAccessible,
      'operating_status': operatingStatus,
      'crowd_updated_at': crowdUpdatedAt?.toIso8601String(),
    };
  }
}