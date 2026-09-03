class AttractionImage {
  const AttractionImage({required this.path, this.caption, this.order = 0});

  final String path;
  final String? caption;
  final int order;

  factory AttractionImage.fromMap(Map<String, dynamic> map) => AttractionImage(
    path: map['storage_path'] as String,
    caption: map['caption'] as String?,
    order: map['display_order'] as int? ?? 0,
  );
}

class AttractionOperatingHours {
  const AttractionOperatingHours({
    required this.dayOfWeek,
    required this.isClosed,
    this.opensAt,
    this.closesAt,
    this.note,
  });

  final int dayOfWeek;
  final bool isClosed;
  final String? opensAt;
  final String? closesAt;
  final String? note;

  factory AttractionOperatingHours.fromMap(Map<String, dynamic> map) =>
      AttractionOperatingHours(
        dayOfWeek: map['day_of_week'] as int,
        isClosed: map['is_closed'] as bool? ?? false,
        opensAt: map['opens_at'] as String?,
        closesAt: map['closes_at'] as String?,
        note: map['note'] as String?,
      );
}

class AttractionSlotPreview {
  const AttractionSlotPreview({
    required this.id,
    required this.startsAt,
    required this.endsAt,
    required this.maximumCapacity,
    required this.reservedCapacity,
    required this.status,
  });

  final String id;
  final DateTime startsAt;
  final DateTime endsAt;
  final int maximumCapacity;
  final int reservedCapacity;
  final String status;

  int get remainingCapacity => maximumCapacity - reservedCapacity;
  double get occupancyRatio =>
      maximumCapacity == 0 ? 0 : reservedCapacity / maximumCapacity;
  bool get isBookable =>
      status == 'open' &&
      remainingCapacity > 0 &&
      startsAt.isAfter(DateTime.now());

  factory AttractionSlotPreview.fromMap(Map<String, dynamic> map) =>
      AttractionSlotPreview(
        id: map['id'] as String,
        startsAt: DateTime.parse(map['starts_at'] as String).toLocal(),
        endsAt: DateTime.parse(map['ends_at'] as String).toLocal(),
        maximumCapacity: map['maximum_capacity'] as int,
        reservedCapacity: map['reserved_capacity'] as int? ?? 0,
        status: map['status'] as String,
      );
}

class Attraction {
  const Attraction({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.locationName,
    required this.address,
    required this.entrancePriceMyr,
    required this.facilities,
    required this.attractionType,
    required this.maximumCapacity,
    required this.listingStatus,
    required this.images,
    required this.operatingHours,
    required this.slots,
    this.latitude,
    this.longitude,
    this.visitorGuidelines,
    this.attractionRules,
    this.coverImageUrl,
    this.distanceKm,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final String locationName;
  final String address;
  final double? latitude;
  final double? longitude;
  final double entrancePriceMyr;
  final List<String> facilities;
  final String? visitorGuidelines;
  final String? attractionRules;
  final String attractionType;
  final int maximumCapacity;
  final String listingStatus;
  final String? coverImageUrl;
  final List<AttractionImage> images;
  final List<AttractionOperatingHours> operatingHours;
  final List<AttractionSlotPreview> slots;
  final double? distanceKm;

  List<AttractionSlotPreview> get availableSlots =>
      slots.where((slot) => slot.isBookable).toList()
        ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

  AttractionSlotPreview? get nextAvailableSlot =>
      availableSlots.isEmpty ? null : availableSlots.first;

  String get estimatedCrowdLevel {
    final ratio = nextAvailableSlot?.occupancyRatio;
    if (ratio == null) return 'Unavailable';
    if (ratio < .4) return 'Low';
    if (ratio < .7) return 'Moderate';
    if (ratio < .9) return 'High';
    return 'Critical';
  }

  bool get isAccessible => facilities.any((facility) {
    final value = facility.toLowerCase();
    return value.contains('wheelchair') || value.contains('accessible');
  });

  bool isOpenAt(DateTime time) {
    final databaseDay = time.weekday % 7;
    final hours = operatingHours.where((item) => item.dayOfWeek == databaseDay);
    if (hours.isEmpty || hours.first.isClosed) return false;
    final opens = _minutes(hours.first.opensAt);
    final closes = _minutes(hours.first.closesAt);
    final now = time.hour * 60 + time.minute;
    return opens != null && closes != null && now >= opens && now < closes;
  }

  Attraction copyWithDistance(double? value) => Attraction(
    id: id,
    name: name,
    description: description,
    category: category,
    locationName: locationName,
    address: address,
    latitude: latitude,
    longitude: longitude,
    entrancePriceMyr: entrancePriceMyr,
    facilities: facilities,
    visitorGuidelines: visitorGuidelines,
    attractionRules: attractionRules,
    attractionType: attractionType,
    maximumCapacity: maximumCapacity,
    listingStatus: listingStatus,
    coverImageUrl: coverImageUrl,
    images: images,
    operatingHours: operatingHours,
    slots: slots,
    distanceKm: value,
  );

  factory Attraction.fromMap(Map<String, dynamic> map) {
    List<Map<String, dynamic>> maps(String key) =>
        ((map[key] as List?) ?? const [])
            .map((value) => (value as Map).cast<String, dynamic>())
            .toList();
    final images =
        maps('attraction_images').map(AttractionImage.fromMap).toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    final hours =
        maps('operating_hours').map(AttractionOperatingHours.fromMap).toList()
          ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
    final slots =
        maps('attraction_slots').map(AttractionSlotPreview.fromMap).toList()
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return Attraction(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Attraction',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'Attraction',
      locationName: map['location_name'] as String? ?? 'Malaysia',
      address: map['address'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      entrancePriceMyr: (map['entrance_price_myr'] as num?)?.toDouble() ?? 0,
      facilities: ((map['facilities'] as List?) ?? const [])
          .map((value) => value.toString())
          .toList(),
      visitorGuidelines: map['visitor_guidelines'] as String?,
      attractionRules: map['attraction_rules'] as String?,
      attractionType: map['attraction_type'] as String? ?? 'indoor',
      maximumCapacity: map['maximum_capacity'] as int? ?? 1,
      listingStatus: map['listing_status'] as String? ?? 'draft',
      coverImageUrl: map['cover_image_url'] as String?,
      images: images,
      operatingHours: hours,
      slots: slots,
    );
  }

  static int? _minutes(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    return int.tryParse(parts[0]) == null || int.tryParse(parts[1]) == null
        ? null
        : int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}

class AttractionFilters {
  const AttractionFilters({
    this.category,
    this.location,
    this.maximumPrice,
    this.maximumDistanceKm,
    this.crowdLevel,
    this.requiredFacility,
    this.openNow = false,
  });

  final String? category;
  final String? location;
  final double? maximumPrice;
  final double? maximumDistanceKm;
  final String? crowdLevel;
  final String? requiredFacility;
  final bool openNow;

  bool get isActive =>
      category != null ||
      location != null ||
      maximumPrice != null ||
      maximumDistanceKm != null ||
      crowdLevel != null ||
      requiredFacility != null ||
      openNow;
}

bool attractionMatches({
  required Attraction attraction,
  String keyword = '',
  AttractionFilters filters = const AttractionFilters(),
  DateTime? now,
}) {
  final normalized = keyword.trim().toLowerCase();
  final searchable =
      '${attraction.name} ${attraction.description} ${attraction.category} ${attraction.locationName}'
          .toLowerCase();
  if (normalized.isNotEmpty && !searchable.contains(normalized)) return false;
  if (filters.category != null &&
      attraction.category.toLowerCase() != filters.category!.toLowerCase()) {
    return false;
  }
  if (filters.location != null &&
      !attraction.locationName.toLowerCase().contains(
        filters.location!.toLowerCase(),
      )) {
    return false;
  }
  if (filters.maximumPrice != null &&
      attraction.entrancePriceMyr > filters.maximumPrice!) {
    return false;
  }
  if (filters.maximumDistanceKm != null &&
      (attraction.distanceKm == null ||
          attraction.distanceKm! > filters.maximumDistanceKm!)) {
    return false;
  }
  if (filters.crowdLevel != null &&
      attraction.estimatedCrowdLevel.toLowerCase() !=
          filters.crowdLevel!.toLowerCase()) {
    return false;
  }
  if (filters.requiredFacility != null &&
      !attraction.facilities.any(
        (value) => value.toLowerCase().contains(
          filters.requiredFacility!.toLowerCase(),
        ),
      )) {
    return false;
  }
  if (filters.openNow && !attraction.isOpenAt(now ?? DateTime.now())) {
    return false;
  }
  return true;
}
