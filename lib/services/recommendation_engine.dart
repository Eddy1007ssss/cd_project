import '../models/attraction.dart';
import '../models/preference_profile.dart';
import '../models/recommendation_result.dart';

class RecommendationEngine {
  const RecommendationEngine._();

  static RecommendationResult score({
    required Attraction attraction,
    required PreferenceProfile preferences,
    List<String> tags = const [],
    Set<String> previousCategories = const {},
  }) {
    var score = 0.0;
    final reasons = <String>[];
    final terms = <String>{
      attraction.category.toLowerCase(),
      ...tags.map((value) => value.toLowerCase()),
    };
    if (preferences.interests.any(
      (interest) => terms.any(
        (term) =>
            term.contains(interest.toLowerCase()) ||
            interest.toLowerCase().contains(term),
      ),
    )) {
      score += 30;
      reasons.add(
        'Matches your ${preferences.interests.join(' or ')} interests',
      );
    }
    if (preferences.maxBudgetMyr == null ||
        attraction.entrancePriceMyr <= preferences.maxBudgetMyr!) {
      score += 15;
      reasons.add(
        preferences.maxBudgetMyr == null
            ? 'Suitable for a flexible budget'
            : 'Within your RM${preferences.maxBudgetMyr!.toStringAsFixed(0)} budget',
      );
    }
    if (attraction.distanceKm != null &&
        attraction.distanceKm! <= preferences.travelRadiusKm) {
      score += 15;
      reasons.add(
        '${attraction.distanceKm!.toStringAsFixed(1)} km from your location',
      );
    }
    if (_crowdRank(attraction.estimatedCrowdLevel) <=
        _crowdRank(preferences.preferredCrowdLevel)) {
      score += 15;
      reasons.add('${attraction.estimatedCrowdLevel} estimated slot crowd');
    }
    final slot = attraction.nextAvailableSlot;
    if (slot != null) {
      score += 15;
      reasons.add(
        '${slot.remainingCapacity} spaces in the next available slot',
      );
      if (_withinPreferredPeriod(slot.startsAt, preferences)) {
        score += 5;
      }
    }
    if (previousCategories.contains(attraction.category.toLowerCase())) {
      score += 10;
      reasons.add('Similar to attractions you previously completed');
    }
    if (preferences.requiredFacilities.isNotEmpty &&
        preferences.requiredFacilities.every(
          (required) => attraction.facilities.any(
            (facility) =>
                facility.toLowerCase().contains(required.toLowerCase()),
          ),
        )) {
      score += 5;
      reasons.add('Includes your required facilities');
    }
    if (reasons.isEmpty) {
      reasons.add('Approved attraction with future availability');
    }
    return RecommendationResult(
      attraction: attraction,
      score: score.clamp(0, 100).toDouble(),
      reasons: reasons,
      recommendedSlot: slot,
    );
  }

  static bool _withinPreferredPeriod(
    DateTime time,
    PreferenceProfile preferences,
  ) {
    int minutes(String value) {
      final parts = value.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }

    final slotMinutes = time.hour * 60 + time.minute;
    return slotMinutes >= minutes(preferences.preferredVisitStart) &&
        slotMinutes <= minutes(preferences.preferredVisitEnd);
  }

  static int _crowdRank(String value) => switch (value.toLowerCase()) {
    'low' => 0,
    'moderate' || 'medium' => 1,
    'high' => 2,
    'critical' => 3,
    _ => 4,
  };
}
