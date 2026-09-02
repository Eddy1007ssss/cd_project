class PreferenceProfile {
  final String touristId;
  final List<String> interestedCategories; // e.g. ['Nature', 'Culture', 'Adventure']
  final double minBudget;
  final double maxBudget;
  final double preferredDistanceKm;
  final String crowdTolerance; // 'Low', 'Medium', 'High'
  final bool needsAccessibility;
  final String environmentPreference; // 'Indoor', 'Outdoor', 'Both'
  final String travellingType; // 'Solo', 'Family', 'Group', 'Couple'
  final DateTime? updatedAt;

  PreferenceProfile({
    required this.touristId,
    required this.interestedCategories,
    required this.minBudget,
    required this.maxBudget,
    required this.preferredDistanceKm,
    required this.crowdTolerance,
    required this.needsAccessibility,
    required this.environmentPreference,
    required this.travellingType,
    this.updatedAt,
  });

  factory PreferenceProfile.fromMap(Map<String, dynamic> map) {
    return PreferenceProfile(
      touristId: map['tourist_id'] as String,
      interestedCategories: (map['interested_categories'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      minBudget: (map['min_budget'] as num?)?.toDouble() ?? 0.0,
      maxBudget: (map['max_budget'] as num?)?.toDouble() ?? 0.0,
      preferredDistanceKm:
      (map['preferred_distance_km'] as num?)?.toDouble() ?? 0.0,
      crowdTolerance: map['crowd_tolerance'] as String? ?? 'Medium',
      needsAccessibility: map['needs_accessibility'] as bool? ?? false,
      environmentPreference: map['environment_preference'] as String? ?? 'Both',
      travellingType: map['travelling_type'] as String? ?? 'Solo',
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tourist_id': touristId,
      'interested_categories': interestedCategories,
      'min_budget': minBudget,
      'max_budget': maxBudget,
      'preferred_distance_km': preferredDistanceKm,
      'crowd_tolerance': crowdTolerance,
      'needs_accessibility': needsAccessibility,
      'environment_preference': environmentPreference,
      'travelling_type': travellingType,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // Helpful for the "Update Preference Profile" screen (UC-M2-05):
  // create a copy with only some fields changed
  PreferenceProfile copyWith({
    List<String>? interestedCategories,
    double? minBudget,
    double? maxBudget,
    double? preferredDistanceKm,
    String? crowdTolerance,
    bool? needsAccessibility,
    String? environmentPreference,
    String? travellingType,
  }) {
    return PreferenceProfile(
      touristId: touristId,
      interestedCategories: interestedCategories ?? this.interestedCategories,
      minBudget: minBudget ?? this.minBudget,
      maxBudget: maxBudget ?? this.maxBudget,
      preferredDistanceKm: preferredDistanceKm ?? this.preferredDistanceKm,
      crowdTolerance: crowdTolerance ?? this.crowdTolerance,
      needsAccessibility: needsAccessibility ?? this.needsAccessibility,
      environmentPreference:
      environmentPreference ?? this.environmentPreference,
      travellingType: travellingType ?? this.travellingType,
      updatedAt: DateTime.now(),
    );
  }
}