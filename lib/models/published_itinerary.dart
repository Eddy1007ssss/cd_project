class PublishedItineraryStop {
  const PublishedItineraryStop({
    required this.attractionId,
    required this.attractionName,
    required this.category,
    required this.locationName,
    required this.position,
    required this.startsAt,
    required this.endsAt,
    this.coverImageUrl,
    this.storageImagePath,
    this.travelMinutesFromPrevious,
    this.distanceKmFromPrevious,
  });

  final String attractionId;
  final String attractionName;
  final String category;
  final String locationName;
  final int position;
  final String startsAt;
  final String endsAt;
  final String? coverImageUrl;
  final String? storageImagePath;
  final int? travelMinutesFromPrevious;
  final double? distanceKmFromPrevious;

  factory PublishedItineraryStop.fromMap(Map<String, dynamic> row) {
    final attraction =
        (row['attraction'] as Map?)?.cast<String, dynamic>() ?? const {};
    final images = ((attraction['attraction_images'] as List?) ?? const [])
        .whereType<Map>()
        .map((value) => value.cast<String, dynamic>())
        .toList()
      ..sort((a, b) => ((a['display_order'] as num?)?.toInt() ?? 0)
          .compareTo((b['display_order'] as num?)?.toInt() ?? 0));
    return PublishedItineraryStop(
      attractionId: attraction['id']?.toString() ?? '',
      attractionName: attraction['name']?.toString() ?? 'Attraction',
      category: attraction['category']?.toString() ?? 'Attraction',
      locationName: attraction['location_name']?.toString() ?? 'Malaysia',
      position: (row['position'] as num?)?.toInt() ?? 0,
      startsAt: row['starts_at']?.toString() ?? '',
      endsAt: row['ends_at']?.toString() ?? '',
      coverImageUrl: attraction['cover_image_url'] as String?,
      storageImagePath:
          images.isEmpty ? null : images.first['storage_path'] as String?,
      travelMinutesFromPrevious:
          (row['travel_minutes_from_previous'] as num?)?.toInt(),
      distanceKmFromPrevious:
          (row['distance_km_from_previous'] as num?)?.toDouble(),
    );
  }
}

class PublishedItinerary {
  const PublishedItinerary({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.publishedAt,
    required this.stops,
    this.authorName,
  });

  final String id;
  final String title;
  final String description;
  final String? authorName;
  final DateTime date;
  final DateTime publishedAt;
  final List<PublishedItineraryStop> stops;

  factory PublishedItinerary.fromMap(Map<String, dynamic> row) {
    final stops = ((row['stops'] as List?) ?? const [])
        .whereType<Map>()
        .map((value) => PublishedItineraryStop.fromMap(
              value.cast<String, dynamic>(),
            ))
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    return PublishedItinerary(
      id: row['id'] as String,
      title: row['title'] as String? ?? 'Shared itinerary',
      description: row['description'] as String? ?? '',
      authorName: row['author_name'] as String?,
      date: DateTime.parse(row['itinerary_date'] as String),
      publishedAt: DateTime.parse(row['published_at'] as String).toLocal(),
      stops: stops,
    );
  }
}
