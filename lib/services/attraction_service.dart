import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/module2_demo_data.dart';
import '../models/attraction.dart';
import '../models/preference_profile.dart';
import '../models/recommendation_result.dart';
import 'location_service.dart';
import 'recommendation_engine.dart';

const _attractionSelection = '''
  id, name, description, category, location_name, address,
  latitude, longitude, entrance_price_myr, facilities,
  visitor_guidelines, attraction_rules, attraction_type,
  maximum_capacity, listing_status, cover_image_url,
  attraction_images(storage_path, caption, display_order),
  operating_hours(day_of_week, is_closed, opens_at, closes_at, note),
  attraction_slots(id, starts_at, ends_at, maximum_capacity, reserved_capacity, status)
''';

class AttractionService {
  AttractionService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static PreferenceProfile _demoPreferences = const PreferenceProfile(
    touristId: module2DemoTouristId,
    interests: [
      'history',
      'nature',
      'culture',
    ],
    maxBudgetMyr: 40,
    preferredLocation: 'Dataran Merdeka, Kuala Lumpur',
    preferredLatitude: 3.1478,
    preferredLongitude: 101.6937,
    travelRadiusKm: 15,
    preferredCrowdLevel: 'moderate',
    requiredFacilities: [
      'Restrooms',
    ],
  );

  String? get currentUserId => _client.auth.currentUser?.id;

  bool get isDemoMode => currentUserId == null;

  // ============================================================
  // GET APPROVED ATTRACTIONS
  // ============================================================

  Future<List<Attraction>> getApprovedAttractions({
    LocationPoint? origin,
  }) async {
    if (isDemoMode) {
      return module2DemoAttractions()
          .map(
            (attraction) => _withDistance(
          attraction,
          origin,
        ),
      )
          .toList();
    }

    final rows = await _client
        .from('attractions')
        .select(_attractionSelection)
        .eq('listing_status', 'approved')
        .order('name');

    return rows
        .map(Attraction.fromMap)
        .map(
          (attraction) => _withDistance(
        attraction,
        origin,
      ),
    )
        .toList();
  }

  // ============================================================
  // GET ATTRACTION BY ID
  // ============================================================

  Future<Attraction?> getAttractionById(
      String id, {
        LocationPoint? origin,
      }) async {
    if (isDemoMode) {
      final attractions = await getApprovedAttractions(
        origin: origin,
      );

      for (final attraction in attractions) {
        if (attraction.id == id) {
          return attraction;
        }
      }

      return null;
    }

    final row = await _client
        .from('attractions')
        .select(_attractionSelection)
        .eq('id', id)
        .eq('listing_status', 'approved')
        .maybeSingle();

    if (row == null) {
      return null;
    }

    return _withDistance(
      Attraction.fromMap(row),
      origin,
    );
  }

  // ============================================================
  // SEARCH AND FILTER
  // ============================================================

  Future<List<Attraction>> searchAndFilter({
    String keyword = '',
    AttractionFilters filters = const AttractionFilters(),
    LocationPoint? origin,
  }) async {
    final attractions = await getApprovedAttractions(
      origin: origin,
    );

    return attractions
        .where(
          (attraction) => attractionMatches(
        attraction: attraction,
        keyword: keyword,
        filters: filters,
      ),
    )
        .toList();
  }

  // ============================================================
  // GET TOURIST PREFERENCES
  // ============================================================

  Future<PreferenceProfile> getPreferences({
    LocationPoint? defaultOrigin,
  }) async {
    if (isDemoMode) {
      return _demoPreferences;
    }

    final userId = currentUserId;

    if (userId == null) {
      throw const AuthException(
        'Sign in as a tourist to save discovery preferences.',
      );
    }

    final row = await _client
        .from('tourist_discovery_preferences')
        .select()
        .eq('tourist_id', userId)
        .maybeSingle();

    if (row != null) {
      return PreferenceProfile.fromMap(row);
    }

    return PreferenceProfile(
      touristId: userId,
      preferredLatitude: defaultOrigin?.latitude,
      preferredLongitude: defaultOrigin?.longitude,
      preferredLocation: defaultOrigin?.label,
    );
  }

  // ============================================================
  // SAVE / UPDATE TOURIST PREFERENCES
  // ============================================================

  Future<void> savePreferences(
      PreferenceProfile preferences,
      ) async {
    if (isDemoMode) {
      _demoPreferences = preferences;
      return;
    }

    if (preferences.touristId != currentUserId) {
      throw const AuthException(
        'You can only update your own preferences.',
      );
    }

    await _client
        .from('tourist_discovery_preferences')
        .upsert(
      preferences.toMap(),
    );
  }

  // ============================================================
  // SMART RECOMMENDATIONS
  // ============================================================

  Future<List<RecommendationResult>> getRecommendations({
    required LocationPoint origin,
  }) async {
    final preferences = await getPreferences(
      defaultOrigin: origin,
    );

    final attractions = await getApprovedAttractions(
      origin: origin,
    );

    final tags = isDemoMode
        ? module2DemoInterestTags
        : await _getInterestTags();

    final previousCategories =
    await _getCompletedVisitCategories();

    final averageRatings = isDemoMode
        ? <String, double>{}
        : await _getAverageRatings();

    // ----------------------------------------------------------
    // Environment preference
    // ----------------------------------------------------------

    List<Attraction> suitableAttractions = attractions;

    final environment =
    preferences.environmentPreference.toLowerCase().trim();

    if (environment != 'both') {
      final environmentMatches = attractions.where(
            (attraction) {
          return attraction.attractionType.toLowerCase().trim() ==
              environment;
        },
      ).toList();

      // If matching attractions exist, prioritise only
      // attractions that match Indoor / Outdoor preference.
      //
      // If none exist, return all attractions as fallback.
      if (environmentMatches.isNotEmpty) {
        suitableAttractions = environmentMatches;
      }
    }

    final results = suitableAttractions
        .map(
          (attraction) => RecommendationEngine.score(
        attraction: attraction,
        preferences: preferences,
        tags: tags[attraction.id] ?? const [],
        previousCategories: previousCategories,
        averageRating: averageRatings[attraction.id],
      ),
    )
        .toList()
      ..sort(
            (a, b) => b.score.compareTo(a.score),
      );

    await _recordImpressions(
      results.take(5),
    );

    return results;
  }

  // ============================================================
  // NEARBY ATTRACTIONS
  // ============================================================

  Future<List<Attraction>> getNearby(
      LocationPoint origin,
      ) async {
    final attractions = await getApprovedAttractions(
      origin: origin,
    );

    return attractions
        .where(
          (item) => item.distanceKm != null,
    )
        .toList()
      ..sort(
            (a, b) => a.distanceKm!.compareTo(
          b.distanceKm!,
        ),
      );
  }

  // ============================================================
  // UPCOMING BOOKING LOCATION
  // ============================================================

  Future<BookingLocationAnchor?> getUpcomingBookingAnchor() async {
    if (currentUserId == null) {
      return null;
    }

    try {
      final rows = await _client
          .from('bookings')
          .select(
        'slot:attraction_slots!inner(starts_at, ends_at, '
            'attraction:attractions!inner(id, name, latitude, longitude))',
      )
          .eq(
        'tourist_id',
        currentUserId!,
      )
          .eq(
        'status',
        'confirmed',
      );

      final anchors = <BookingLocationAnchor>[];

      for (final row in rows) {
        final rawSlot = row['slot'];
        if (rawSlot is! Map) continue;
        final slot = rawSlot.cast<String, dynamic>();

        final startsAt = DateTime.tryParse(
          slot['starts_at']?.toString() ?? '',
        )?.toLocal();
        final endsAt = DateTime.tryParse(
          slot['ends_at']?.toString() ?? '',
        )?.toLocal();

        final rawAttraction = slot['attraction'];
        if (rawAttraction is! Map) continue;
        final attraction = rawAttraction.cast<String, dynamic>();
        final attractionId = attraction['id']?.toString().trim() ?? '';
        final attractionName = attraction['name']?.toString().trim() ?? '';

        final latitude =
        (attraction['latitude'] as num?)?.toDouble();

        final longitude =
        (attraction['longitude'] as num?)?.toDouble();

        if (startsAt != null &&
            endsAt != null &&
            attractionId.isNotEmpty &&
            attractionName.isNotEmpty &&
            startsAt.isAfter(DateTime.now()) &&
            latitude != null &&
            longitude != null) {
          anchors.add(
            BookingLocationAnchor(
              attractionId:
              attractionId,
              attractionName:
              attractionName,
              endsAt: endsAt,
              location: LocationPoint(
                latitude: latitude,
                longitude: longitude,
                label:
                attractionName,
              ),
            ),
          );
        }
      }

      anchors.sort(
            (a, b) => a.endsAt.compareTo(
          b.endsAt,
        ),
      );

      return anchors.isEmpty
          ? null
          : anchors.first;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // CHECK WHETHER ATTRACTION FITS AFTER BOOKING
  // ============================================================

  bool fitsAfterBooking(
      Attraction attraction,
      BookingLocationAnchor anchor,
      ) {
    if (attraction.id == anchor.attractionId ||
        attraction.distanceKm == null) {
      return false;
    }

    final earliest = anchor.endsAt.add(
      Duration(
        minutes: LocationService.estimatedTravelMinutes(
          attraction.distanceKm!,
        ),
      ),
    );

    return attraction.availableSlots.any(
          (slot) =>
      slot.startsAt.year == anchor.endsAt.year &&
          slot.startsAt.month == anchor.endsAt.month &&
          slot.startsAt.day == anchor.endsAt.day &&
          !slot.startsAt.isBefore(
            earliest,
          ),
    );
  }

  // ============================================================
  // IMAGE URL
  // ============================================================

  String publicImageUrl(String path) {
    if (path.startsWith('http')) {
      return path;
    }

    return _client.storage
        .from('attraction-images')
        .getPublicUrl(path);
  }

  // ============================================================
  // ADD DISTANCE TO ATTRACTION
  // ============================================================

  Attraction _withDistance(
      Attraction attraction,
      LocationPoint? origin,
      ) {
    if (origin == null ||
        attraction.latitude == null ||
        attraction.longitude == null) {
      return attraction;
    }

    return attraction.copyWithDistance(
      LocationService.distanceKm(
        firstLatitude: origin.latitude,
        firstLongitude: origin.longitude,
        secondLatitude:
        attraction.latitude!,
        secondLongitude:
        attraction.longitude!,
      ),
    );
  }

  // ============================================================
  // GET ATTRACTION INTEREST TAGS
  // ============================================================

  Future<Map<String, List<String>>> _getInterestTags() async {
    try {
      final rows = await _client
          .from('attraction_interest_tags')
          .select(
        'attraction_id, tag',
      );

      final result =
      <String, List<String>>{};

      for (final row in rows) {
        result
            .putIfAbsent(
          row['attraction_id'] as String,
              () => [],
        )
            .add(
          row['tag'] as String,
        );
      }

      return result;
    } catch (_) {
      return const {};
    }
  }

  // ============================================================
  // GET AVERAGE VISITOR RATINGS
  // ============================================================

  Future<Map<String, double>> _getAverageRatings() async {
    try {
      final rows = await _client
          .from('feedback')
          .select(
        'attraction_id, overall_rating',
      );

      final totals =
      <String, double>{};

      final counts =
      <String, int>{};

      for (final row in rows) {
        final attractionId =
        row['attraction_id'] as String?;

        final rating =
        (row['overall_rating'] as num?)?.toDouble();

        if (attractionId == null ||
            rating == null) {
          continue;
        }

        totals[attractionId] =
            (totals[attractionId] ?? 0) +
                rating;

        counts[attractionId] =
            (counts[attractionId] ?? 0) +
                1;
      }

      final averages =
      <String, double>{};

      for (final entry in totals.entries) {
        final count =
        counts[entry.key];

        if (count != null &&
            count > 0) {
          averages[entry.key] =
              entry.value / count;
        }
      }

      return averages;
    } catch (_) {
      return const {};
    }
  }

  // ============================================================
  // COMPLETED VISIT CATEGORIES
  // ============================================================

  Future<Set<String>> _getCompletedVisitCategories() async {
    if (currentUserId == null) {
      return const {};
    }

    try {
      final rows = await _client
          .from('bookings')
          .select(
        'slot:attraction_slots!inner('
            'attraction:attractions!inner(category))',
      )
          .eq(
        'tourist_id',
        currentUserId!,
      )
          .eq(
        'status',
        'completed',
      );

      final categories = <String>{};
      for (final row in rows) {
        final rawSlot = row['slot'];
        if (rawSlot is! Map) continue;
        final rawAttraction = rawSlot['attraction'];
        if (rawAttraction is! Map) continue;
        final category = rawAttraction['category']?.toString().trim();
        if (category != null && category.isNotEmpty) {
          categories.add(category.toLowerCase());
        }
      }
      return categories;
    } catch (_) {
      return const {};
    }
  }

  // ============================================================
  // ALTERNATIVE ATTRACTIONS
  // UC-M2-11
  // ============================================================

  Future<
      ({
      List<String> issues,
      List<RecommendationResult> alternatives,
      })> getAlternativeAttractions({
    required Attraction selectedAttraction,
    required LocationPoint origin,
  }) async {
    final preferences = await getPreferences(
      defaultOrigin: origin,
    );

    // Determine why the selected attraction
    // may not be suitable for the tourist.
    final issues = _getSuitabilityIssues(
      selectedAttraction,
      preferences,
    );

    // No issue means the attraction is already suitable.
    if (issues.isEmpty) {
      return (
      issues: issues,
      alternatives: <RecommendationResult>[],
      );
    }

    final attractions = await getApprovedAttractions(
      origin: origin,
    );

    final tags = isDemoMode
        ? module2DemoInterestTags
        : await _getInterestTags();

    final previousCategories =
    await _getCompletedVisitCategories();

    final averageRatings = isDemoMode
        ? <String, double>{}
        : await _getAverageRatings();

    final selectedTags =
    (tags[selectedAttraction.id] ?? const [])
        .map(
          (value) => value.toLowerCase(),
    )
        .toSet();

    // ==========================================================
    // FIND SIMILAR ATTRACTIONS
    // ==========================================================

    final similarAttractions = attractions.where(
          (attraction) {
        // Never recommend the same attraction.
        if (attraction.id ==
            selectedAttraction.id) {
          return false;
        }

        final sameCategory =
            attraction.category.toLowerCase() ==
                selectedAttraction.category.toLowerCase();

        final candidateTags =
        (tags[attraction.id] ?? const [])
            .map(
              (value) => value.toLowerCase(),
        )
            .toSet();

        final sharedInterestTag =
        candidateTags.any(
          selectedTags.contains,
        );

        return sameCategory ||
            sharedInterestTag;
      },
    ).toList();

    // ==========================================================
    // FIND BETTER ALTERNATIVES
    // ==========================================================

    var candidates =
    similarAttractions.where(
          (attraction) {
        final candidateIssues =
        _getSuitabilityIssues(
          attraction,
          preferences,
        );

        // An alternative is considered better
        // when it has fewer suitability problems.
        return candidateIssues.length <
            issues.length;
      },
    ).toList();

    // If no candidate is clearly better,
    // still show similar attractions as fallback.
    if (candidates.isEmpty) {
      candidates = similarAttractions;
    }

    // ==========================================================
    // SCORE AND RANK ALTERNATIVES
    // ==========================================================

    final alternatives = candidates.map(
          (attraction) {
        final result =
        RecommendationEngine.score(
          attraction: attraction,
          preferences: preferences,
          tags:
          tags[attraction.id] ?? const [],
          previousCategories:
          previousCategories,
          averageRating:
          averageRatings[attraction.id],
        );

        final alternativeReasons =
        _getAlternativeReasons(
          selectedAttraction:
          selectedAttraction,
          alternative:
          attraction,
          preferences:
          preferences,
        );

        final combinedReasons = <String>{
          ...alternativeReasons,
          ...result.reasons,
        }.toList();

        return RecommendationResult(
          attraction:
          result.attraction,
          score:
          result.score,
          reasons:
          combinedReasons,
          recommendedSlot:
          result.recommendedSlot,
        );
      },
    ).toList()
      ..sort(
            (a, b) => b.score.compareTo(
          a.score,
        ),
      );

    return (
    issues: issues,
    alternatives:
    alternatives.take(5).toList(),
    );
  }

  // ============================================================
  // FIND SUITABILITY PROBLEMS
  // ============================================================

  List<String> _getSuitabilityIssues(
      Attraction attraction,
      PreferenceProfile preferences,
      ) {
    final issues = <String>[];

    // ----------------------------------------------------------
    // CLOSED
    // ----------------------------------------------------------

    // Only evaluate opening status when operating
    // hours are actually available.
    if (attraction.operatingHours.isNotEmpty &&
        !attraction.isOpenAt(
          DateTime.now(),
        )) {
      issues.add(
        'This attraction is currently closed.',
      );
    }

    // ----------------------------------------------------------
    // FULL / NO AVAILABLE SLOT
    // ----------------------------------------------------------

    if (attraction.availableSlots.isEmpty) {
      issues.add(
        'No available future slots.',
      );
    }

    // ----------------------------------------------------------
    // TOO EXPENSIVE
    // ----------------------------------------------------------

    final maxBudget =
        preferences.maxBudgetMyr;

    if (maxBudget != null &&
        attraction.entrancePriceMyr >
            maxBudget) {
      issues.add(
        'RM${attraction.entrancePriceMyr.toStringAsFixed(0)} '
            'exceeds your RM${maxBudget.toStringAsFixed(0)} budget.',
      );
    }

    // ----------------------------------------------------------
    // TOO FAR
    // ----------------------------------------------------------

    final distance =
        attraction.distanceKm;

    if (distance != null &&
        distance >
            preferences.travelRadiusKm) {
      issues.add(
        '${distance.toStringAsFixed(1)} km away, '
            'outside your preferred '
            '${preferences.travelRadiusKm.toStringAsFixed(0)} km radius.',
      );
    }

    // ----------------------------------------------------------
    // TOO CROWDED
    // ----------------------------------------------------------

    final actualCrowd =
    _alternativeCrowdRank(
      attraction.estimatedCrowdLevel,
    );

    final preferredCrowd =
    _alternativeCrowdRank(
      preferences.preferredCrowdLevel,
    );

    // Rank 4 means crowd information unavailable.
    if (actualCrowd < 4 &&
        preferredCrowd < 4 &&
        actualCrowd >
            preferredCrowd) {
      issues.add(
        '${attraction.estimatedCrowdLevel} crowd level '
            'is higher than your preferred '
            '${preferences.preferredCrowdLevel} crowd level.',
      );
    }

    return issues;
  }

  // ============================================================
  // EXPLAIN WHY ALTERNATIVE IS BETTER
  // ============================================================

  List<String> _getAlternativeReasons({
    required Attraction selectedAttraction,
    required Attraction alternative,
    required PreferenceProfile preferences,
  }) {
    final reasons = <String>[];

    // ----------------------------------------------------------
    // SAME CATEGORY
    // ----------------------------------------------------------

    if (selectedAttraction.category.toLowerCase() ==
        alternative.category.toLowerCase()) {
      reasons.add(
        'Similar ${alternative.category} attraction',
      );
    }

    // ----------------------------------------------------------
    // BETTER BUDGET
    // ----------------------------------------------------------

    final maxBudget =
        preferences.maxBudgetMyr;

    if (maxBudget != null &&
        selectedAttraction.entrancePriceMyr >
            maxBudget &&
        alternative.entrancePriceMyr <=
            maxBudget) {
      reasons.add(
        'Within your RM${maxBudget.toStringAsFixed(0)} budget',
      );
    }

    // ----------------------------------------------------------
    // CLOSER
    // ----------------------------------------------------------

    final selectedDistance =
        selectedAttraction.distanceKm;

    final alternativeDistance =
        alternative.distanceKm;

    if (selectedDistance != null &&
        alternativeDistance != null &&
        selectedDistance >
            preferences.travelRadiusKm &&
        alternativeDistance <=
            preferences.travelRadiusKm) {
      reasons.add(
        '${alternativeDistance.toStringAsFixed(1)} km away '
            'and within your preferred radius',
      );
    }

    // ----------------------------------------------------------
    // AVAILABLE SLOT
    // ----------------------------------------------------------

    if (selectedAttraction.availableSlots.isEmpty &&
        alternative.nextAvailableSlot != null) {
      reasons.add(
        '${alternative.nextAvailableSlot!.remainingCapacity} '
            'spaces available in the next slot',
      );
    }

    // ----------------------------------------------------------
    // LOWER CROWD
    // ----------------------------------------------------------

    final selectedCrowd =
    _alternativeCrowdRank(
      selectedAttraction.estimatedCrowdLevel,
    );

    final alternativeCrowd =
    _alternativeCrowdRank(
      alternative.estimatedCrowdLevel,
    );

    final preferredCrowd =
    _alternativeCrowdRank(
      preferences.preferredCrowdLevel,
    );

    if (selectedCrowd < 4 &&
        alternativeCrowd < 4 &&
        selectedCrowd >
            preferredCrowd &&
        alternativeCrowd <=
            preferredCrowd) {
      reasons.add(
        '${alternative.estimatedCrowdLevel} crowd matches '
            'your preferred crowd level',
      );
    }

    // ----------------------------------------------------------
    // OPEN NOW
    // ----------------------------------------------------------

    final selectedHasHours =
        selectedAttraction.operatingHours.isNotEmpty;

    final alternativeHasHours =
        alternative.operatingHours.isNotEmpty;

    if (selectedHasHours &&
        alternativeHasHours &&
        !selectedAttraction.isOpenAt(
          DateTime.now(),
        ) &&
        alternative.isOpenAt(
          DateTime.now(),
        )) {
      reasons.add(
        'Currently open',
      );
    }

    return reasons;
  }

  // ============================================================
  // CROWD RANK USED FOR ALTERNATIVES
  // ============================================================

  int _alternativeCrowdRank(
      String value,
      ) =>
      switch (value.toLowerCase()) {
        'low' => 0,
        'moderate' || 'medium' => 1,
        'high' => 2,
        'critical' => 3,
        _ => 4,
      };

  // ============================================================
  // RECORD RECOMMENDATION IMPRESSIONS
  // ============================================================

  Future<void> _recordImpressions(
      Iterable<RecommendationResult> results,
      ) async {
    if (currentUserId == null) {
      return;
    }

    try {
      await _client
          .from(
        'recommendation_impressions',
      )
          .insert(
        results
            .map(
              (result) => {
            'tourist_id':
            currentUserId,
            'attraction_id':
            result.attraction.id,
            'slot_id':
            result.recommendedSlot?.id,
            'recommendation_score':
            result.score,
            'reason':
            result.reasons.join('. '),
            'context': {
              'distance_km':
              result.attraction.distanceKm,
              'crowd_source':
              'slot_occupancy_estimate',
            },
          },
        )
            .toList(),
      );
    } catch (_) {
      // Recommendations remain usable
      // if logging temporarily fails.
    }
  }
}
