import '../models/attraction.dart';
import '../models/preference_profile.dart';
import '../models/recommendation_result.dart';

class RecommendationEngine {
  const RecommendationEngine._();

  static const double _interestWeight = 25;
  static const double _budgetWeight = 15;
  static const double _distanceWeight = 15;
  static const double _ratingWeight = 15;
  static const double _crowdWeight = 15;
  static const double _slotWeight = 15;

  static RecommendationResult score({
    required Attraction attraction,
    required PreferenceProfile preferences,
    List<String> tags = const [],
    Set<String> previousCategories = const {},
    double? averageRating,
  }) {
    var earnedScore = 0.0;
    var availableWeight = 0.0;

    final reasons = <String>[];

    final normalizedCategory = attraction.category.toLowerCase();

    final normalizedTags = tags
        .map((value) => value.toLowerCase())
        .toSet();

    final terms = <String>{
      normalizedCategory,
      ...normalizedTags,
    };

    //
    // 1. INTEREST MATCH - 25%
    //
    availableWeight += _interestWeight;

    final interestMatched = preferences.interests.any(
          (interest) {
        final normalizedInterest = interest.toLowerCase();

        return terms.any(
              (term) =>
          term.contains(normalizedInterest) ||
              normalizedInterest.contains(term),
        );
      },
    );

    final previousCategoryMatched =
    previousCategories.contains(normalizedCategory);

    if (interestMatched) {
      earnedScore += _interestWeight;

      reasons.add(
        'Matches your ${preferences.interests.join(' or ')} interests',
      );
    } else if (previousCategoryMatched) {
      // Partial interest score based on previous activity.
      earnedScore += _interestWeight * 0.8;

      reasons.add(
        'Similar to attractions you previously visited',
      );
    }

    //
    // 2. BUDGET MATCH - 15%
    //
    availableWeight += _budgetWeight;

    final price = attraction.entrancePriceMyr;

    final minimumBudget = preferences.minBudgetMyr;
    final maximumBudget = preferences.maxBudgetMyr;

    final withinMinimum = price >= minimumBudget;

    final withinMaximum =
        maximumBudget == null || price <= maximumBudget;

    if (withinMinimum && withinMaximum) {
      earnedScore += _budgetWeight;

      if (maximumBudget == null) {
        reasons.add(
          'Suitable for your flexible budget',
        );
      } else {
        reasons.add(
          'RM${price.toStringAsFixed(0)} is within your '
              'RM${minimumBudget.toStringAsFixed(0)} - '
              'RM${maximumBudget.toStringAsFixed(0)} budget',
        );
      }
    }

    //
    // 3. DISTANCE SCORE - 15%
    //
    final distance = attraction.distanceKm;

    if (distance != null) {
      availableWeight += _distanceWeight;

      if (distance <= preferences.travelRadiusKm) {
        final distanceRatio = _clamp01(
          1 - (distance / preferences.travelRadiusKm),
        );

        // Attraction still gets some distance points when it is
        // inside the selected radius, while nearer attractions
        // receive more.
        final normalizedDistance =
            0.5 + (distanceRatio * 0.5);

        earnedScore +=
            _distanceWeight * normalizedDistance;

        reasons.add(
          '${distance.toStringAsFixed(1)} km away and within '
              'your ${preferences.travelRadiusKm.toStringAsFixed(0)} km radius',
        );
      }
    }

    //
    // 4. RATING SCORE - 15%
    //
    // Rating is excluded when no visitor feedback exists.
    if (averageRating != null) {
      availableWeight += _ratingWeight;

      // Assumes overall_rating uses a 1-5 rating scale.
      final normalizedRating = _clamp01(
        averageRating / 5.0,
      );

      earnedScore +=
          _ratingWeight * normalizedRating;

      reasons.add(
        'Rated ${averageRating.toStringAsFixed(1)}/5 by visitors',
      );
    }

    //
    // 5. LOW-CROWD SCORE - 15%
    //
    final actualCrowdRank = _crowdRank(
      attraction.crowdLevel,
    );

    final preferredCrowdRank = _crowdRank(
      preferences.preferredCrowdLevel,
    );

    // 4 means unavailable/unknown.
    if (actualCrowdRank < 4) {
      availableWeight += _crowdWeight;

      if (actualCrowdRank <= preferredCrowdRank) {
        final crowdFactor = switch (actualCrowdRank) {
          0 => 1.0, // Low
          1 => 0.80, // Moderate
          2 => 0.55, // High
          3 => 0.25, // Critical
          _ => 0.0,
        };

        earnedScore +=
            _crowdWeight * crowdFactor;

        reasons.add(
          '${attraction.crowdLevel} live crowd level',
        );
      }
    }

    //
    // 6. SLOT AVAILABILITY - 15%
    //
    availableWeight += _slotWeight;

    final slot = attraction.nextAvailableSlot;

    if (slot != null) {
      earnedScore += _slotWeight;

      reasons.add(
        '${slot.remainingCapacity} spaces available in the next slot',
      );

      if (_withinPreferredPeriod(
        slot.startsAt,
        preferences,
      )) {
        reasons.add(
          'Available during your preferred visiting time',
        );
      }
    }

    //
    // ADDITIONAL PREFERENCE REASONS
    // These improve explanations but do NOT increase the
    // official 100-point recommendation score.
    //

    // Indoor / Outdoor preference
    if (preferences.environmentPreference == 'both' ||
        attraction.attractionType.toLowerCase() ==
            preferences.environmentPreference.toLowerCase()) {
      reasons.add(
        preferences.environmentPreference == 'both'
            ? 'Suitable for your indoor/outdoor preference'
            : 'Matches your ${preferences.environmentPreference} preference',
      );
    }

    // Required facilities
    if (preferences.requiredFacilities.isNotEmpty) {
      final hasRequiredFacilities =
      preferences.requiredFacilities.every(
          (required) => attraction.facilities.any(
          (facility) => facility
          .toLowerCase()
          .contains(required.toLowerCase()),
    ),
    );

    if (hasRequiredFacilities) {
    reasons.add(
    'Includes your required facilities',
    );
    }
    }

    // Accessibility
    if (preferences.accessibilityNeeds.isNotEmpty) {
    final accessibilityMatched =
    preferences.accessibilityNeeds.every(
    (required) => attraction.facilities.any(
    (facility) {
    final facilityValue =
    facility.toLowerCase();
    final requiredValue =
    required.toLowerCase();

    return facilityValue.contains(
    requiredValue,
    ) ||
    requiredValue.contains(
    facilityValue,
    );
    },
    ),
    );

    if (accessibilityMatched) {
    reasons.add(
    'Matches your accessibility needs',
    );
    }
    }

    // Travelling type can be matched through interest tags
    // when the operator has supplied suitable tags.
    if (normalizedTags.contains(
    preferences.travellingType.toLowerCase(),
    )) {
    reasons.add(
    'Suitable for ${preferences.travellingType} travel',
    );
    }

    if (reasons.isEmpty) {
    reasons.add(
    'Approved attraction with future availability',
    );
    }

    //
    // NORMALISE SCORE
    //
    // If rating/crowd/location data is unavailable, that
    // factor is excluded instead of unfairly giving 0.
    final finalScore = availableWeight == 0
    ? 0.0
        : (earnedScore / availableWeight) * 100;

    return RecommendationResult(
    attraction: attraction,
    score: finalScore.clamp(0, 100).toDouble(),
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

      return int.parse(parts[0]) * 60 +
          int.parse(parts[1]);
    }

    final slotMinutes =
        time.hour * 60 + time.minute;

    return slotMinutes >=
        minutes(
          preferences.preferredVisitStart,
        ) &&
        slotMinutes <=
            minutes(
              preferences.preferredVisitEnd,
            );
  }

  static double _clamp01(double value) {
    if (value < 0) {
      return 0;
    }

    if (value > 1) {
      return 1;
    }

    return value;
  }

  static int _crowdRank(String value) =>
      switch (value.toLowerCase()) {
        'low' => 0,
        'moderate' || 'medium' => 1,
        'high' => 2,
        'critical' => 3,
        _ => 4,
      };
}
