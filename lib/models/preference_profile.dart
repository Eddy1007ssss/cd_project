class PreferenceProfile {
  const PreferenceProfile({
    required this.touristId,
    this.interests = const [],

    // Budget
    this.minBudgetMyr = 0,
    this.maxBudgetMyr,

    // Location
    this.preferredLocation,
    this.preferredLatitude,
    this.preferredLongitude,

    // Distance
    this.travelRadiusKm = 10,

    // Crowd level
    this.preferredCrowdLevel = 'moderate',

    // Preferred visit time
    this.preferredVisitStart = '09:00',
    this.preferredVisitEnd = '17:00',

    // Facilities
    this.requiredFacilities = const [],

    // Accessibility
    this.accessibilityNeeds = const [],

    // indoor / outdoor / both
    this.environmentPreference = 'both',

    // solo / family / group
    this.travellingType = 'solo',
  });

  final String touristId;

  final List<String> interests;

  final double minBudgetMyr;
  final double? maxBudgetMyr;

  final String? preferredLocation;
  final double? preferredLatitude;
  final double? preferredLongitude;

  final double travelRadiusKm;

  final String preferredCrowdLevel;

  final String preferredVisitStart;
  final String preferredVisitEnd;

  final List<String> requiredFacilities;

  final List<String> accessibilityNeeds;

  final String environmentPreference;

  final String travellingType;

  factory PreferenceProfile.fromMap(Map<String, dynamic> map) =>
      PreferenceProfile(
        touristId: map['tourist_id'] as String,

        interests: ((map['interests'] as List?) ?? const [])
            .map((value) => value.toString())
            .toList(),

        minBudgetMyr:
        (map['min_budget_myr'] as num?)?.toDouble() ?? 0,

        maxBudgetMyr:
        (map['max_budget_myr'] as num?)?.toDouble(),

        preferredLocation:
        map['preferred_location'] as String?,

        preferredLatitude:
        (map['preferred_latitude'] as num?)?.toDouble(),

        preferredLongitude:
        (map['preferred_longitude'] as num?)?.toDouble(),

        travelRadiusKm:
        (map['travel_radius_km'] as num?)?.toDouble() ?? 10,

        preferredCrowdLevel:
        map['preferred_crowd_level'] as String? ?? 'moderate',

        preferredVisitStart:
        _shortTime(map['preferred_visit_start'] as String?) ?? '09:00',

        preferredVisitEnd:
        _shortTime(map['preferred_visit_end'] as String?) ?? '17:00',

        requiredFacilities:
        ((map['required_facilities'] as List?) ?? const [])
            .map((value) => value.toString())
            .toList(),

        accessibilityNeeds:
        ((map['accessibility_needs'] as List?) ?? const [])
            .map((value) => value.toString())
            .toList(),

        environmentPreference:
        map['environment_preference'] as String? ?? 'both',

        travellingType:
        map['travelling_type'] as String? ?? 'solo',
      );

  Map<String, dynamic> toMap() => {
    'tourist_id': touristId,

    'interests': interests,

    'min_budget_myr': minBudgetMyr,
    'max_budget_myr': maxBudgetMyr,

    'preferred_location': preferredLocation,
    'preferred_latitude': preferredLatitude,
    'preferred_longitude': preferredLongitude,

    'travel_radius_km': travelRadiusKm,

    'preferred_crowd_level': preferredCrowdLevel,

    'preferred_visit_start': preferredVisitStart,
    'preferred_visit_end': preferredVisitEnd,

    'required_facilities': requiredFacilities,

    'accessibility_needs': accessibilityNeeds,

    'environment_preference': environmentPreference,

    'travelling_type': travellingType,
  };

  static String? _shortTime(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    return value.substring(
      0,
      value.length >= 5 ? 5 : value.length,
    );
  }
}