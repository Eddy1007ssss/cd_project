class PreferenceProfile {
  const PreferenceProfile({
    required this.touristId,
    this.interests = const [],
    this.maxBudgetMyr,
    this.preferredLocation,
    this.preferredLatitude,
    this.preferredLongitude,
    this.travelRadiusKm = 10,
    this.preferredCrowdLevel = 'moderate',
    this.preferredVisitStart = '09:00',
    this.preferredVisitEnd = '17:00',
    this.requiredFacilities = const [],
  });

  final String touristId;
  final List<String> interests;
  final double? maxBudgetMyr;
  final String? preferredLocation;
  final double? preferredLatitude;
  final double? preferredLongitude;
  final double travelRadiusKm;
  final String preferredCrowdLevel;
  final String preferredVisitStart;
  final String preferredVisitEnd;
  final List<String> requiredFacilities;

  factory PreferenceProfile.fromMap(Map<String, dynamic> map) =>
      PreferenceProfile(
        touristId: map['tourist_id'] as String,
        interests: ((map['interests'] as List?) ?? const [])
            .map((value) => value.toString())
            .toList(),
        maxBudgetMyr: (map['max_budget_myr'] as num?)?.toDouble(),
        preferredLocation: map['preferred_location'] as String?,
        preferredLatitude: (map['preferred_latitude'] as num?)?.toDouble(),
        preferredLongitude: (map['preferred_longitude'] as num?)?.toDouble(),
        travelRadiusKm: (map['travel_radius_km'] as num?)?.toDouble() ?? 10,
        preferredCrowdLevel:
            map['preferred_crowd_level'] as String? ?? 'moderate',
        preferredVisitStart:
            _shortTime(map['preferred_visit_start'] as String?) ?? '09:00',
        preferredVisitEnd:
            _shortTime(map['preferred_visit_end'] as String?) ?? '17:00',
        requiredFacilities: ((map['required_facilities'] as List?) ?? const [])
            .map((value) => value.toString())
            .toList(),
      );

  Map<String, dynamic> toMap() => {
    'tourist_id': touristId,
    'interests': interests,
    'max_budget_myr': maxBudgetMyr,
    'preferred_location': preferredLocation,
    'preferred_latitude': preferredLatitude,
    'preferred_longitude': preferredLongitude,
    'travel_radius_km': travelRadiusKm,
    'preferred_crowd_level': preferredCrowdLevel,
    'preferred_visit_start': preferredVisitStart,
    'preferred_visit_end': preferredVisitEnd,
    'required_facilities': requiredFacilities,
  };

  static String? _shortTime(String? value) =>
      value?.substring(0, value.length >= 5 ? 5 : value.length);
}
