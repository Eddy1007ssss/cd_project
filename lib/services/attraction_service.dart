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
    interests: ['history', 'nature', 'culture'],
    maxBudgetMyr: 40,
    preferredLocation: 'Dataran Merdeka, Kuala Lumpur',
    preferredLatitude: 3.1478,
    preferredLongitude: 101.6937,
    travelRadiusKm: 15,
    preferredCrowdLevel: 'moderate',
    requiredFacilities: ['Restrooms'],
  );

  String? get currentUserId => _client.auth.currentUser?.id;
  bool get isDemoMode => currentUserId == null;

  Future<List<Attraction>> getApprovedAttractions({
    LocationPoint? origin,
  }) async {
    if (isDemoMode) {
      return module2DemoAttractions()
          .map((attraction) => _withDistance(attraction, origin))
          .toList();
    }
    final rows = await _client
        .from('attractions')
        .select(_attractionSelection)
        .eq('listing_status', 'approved')
        .order('name');
    return rows
        .map(Attraction.fromMap)
        .map((attraction) => _withDistance(attraction, origin))
        .toList();
  }

  Future<Attraction?> getAttractionById(
    String id, {
    LocationPoint? origin,
  }) async {
    if (isDemoMode) {
      final attractions = await getApprovedAttractions(origin: origin);
      return attractions.where((attraction) => attraction.id == id).firstOrNull;
    }
    final row = await _client
        .from('attractions')
        .select(_attractionSelection)
        .eq('id', id)
        .eq('listing_status', 'approved')
        .maybeSingle();
    return row == null ? null : _withDistance(Attraction.fromMap(row), origin);
  }

  Future<List<Attraction>> searchAndFilter({
    String keyword = '',
    AttractionFilters filters = const AttractionFilters(),
    LocationPoint? origin,
  }) async {
    final attractions = await getApprovedAttractions(origin: origin);
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

  Future<PreferenceProfile> getPreferences({
    LocationPoint? defaultOrigin,
  }) async {
    if (isDemoMode) return _demoPreferences;
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
    if (row != null) return PreferenceProfile.fromMap(row);
    return PreferenceProfile(
      touristId: userId,
      preferredLatitude: defaultOrigin?.latitude,
      preferredLongitude: defaultOrigin?.longitude,
      preferredLocation: defaultOrigin?.label,
    );
  }

  Future<void> savePreferences(PreferenceProfile preferences) async {
    if (isDemoMode) {
      _demoPreferences = preferences;
      return;
    }
    if (preferences.touristId != currentUserId) {
      throw const AuthException('You can only update your own preferences.');
    }
    await _client
        .from('tourist_discovery_preferences')
        .upsert(preferences.toMap());
  }

  Future<List<RecommendationResult>> getRecommendations({
    required LocationPoint origin,
  }) async {
    final preferences = await getPreferences(defaultOrigin: origin);
    final attractions = await getApprovedAttractions(origin: origin);
    final tags = isDemoMode
        ? module2DemoInterestTags
        : await _getInterestTags();
    final previousCategories = await _getCompletedVisitCategories();
    final results =
        attractions
            .map(
              (attraction) => RecommendationEngine.score(
                attraction: attraction,
                preferences: preferences,
                tags: tags[attraction.id] ?? const [],
                previousCategories: previousCategories,
              ),
            )
            .toList()
          ..sort((a, b) => b.score.compareTo(a.score));
    await _recordImpressions(results.take(5));
    return results;
  }

  Future<List<Attraction>> getNearby(LocationPoint origin) async {
    final attractions = await getApprovedAttractions(origin: origin);
    return attractions.where((item) => item.distanceKm != null).toList()
      ..sort((a, b) => a.distanceKm!.compareTo(b.distanceKm!));
  }

  Future<BookingLocationAnchor?> getUpcomingBookingAnchor() async {
    if (currentUserId == null) return null;
    try {
      final rows = await _client
          .from('bookings')
          .select(
            'slot:attraction_slots(starts_at, ends_at, '
            'attraction:attractions(id, name, latitude, longitude))',
          )
          .eq('tourist_id', currentUserId!)
          .eq('status', 'confirmed');
      final anchors = <BookingLocationAnchor>[];
      for (final row in rows) {
        final slot = (row['slot'] as Map).cast<String, dynamic>();
        final startsAt = DateTime.parse(slot['starts_at'] as String).toLocal();
        final attraction = (slot['attraction'] as Map).cast<String, dynamic>();
        final latitude = (attraction['latitude'] as num?)?.toDouble();
        final longitude = (attraction['longitude'] as num?)?.toDouble();
        if (startsAt.isAfter(DateTime.now()) &&
            latitude != null &&
            longitude != null) {
          anchors.add(
            BookingLocationAnchor(
              attractionId: attraction['id'] as String,
              attractionName: attraction['name'] as String,
              endsAt: DateTime.parse(slot['ends_at'] as String).toLocal(),
              location: LocationPoint(
                latitude: latitude,
                longitude: longitude,
                label: attraction['name'] as String,
              ),
            ),
          );
        }
      }
      anchors.sort((a, b) => a.endsAt.compareTo(b.endsAt));
      return anchors.isEmpty ? null : anchors.first;
    } catch (_) {
      return null;
    }
  }

  bool fitsAfterBooking(Attraction attraction, BookingLocationAnchor anchor) {
    if (attraction.id == anchor.attractionId || attraction.distanceKm == null) {
      return false;
    }
    final earliest = anchor.endsAt.add(
      Duration(
        minutes: LocationService.estimatedTravelMinutes(attraction.distanceKm!),
      ),
    );
    return attraction.availableSlots.any(
      (slot) =>
          slot.startsAt.year == anchor.endsAt.year &&
          slot.startsAt.month == anchor.endsAt.month &&
          slot.startsAt.day == anchor.endsAt.day &&
          !slot.startsAt.isBefore(earliest),
    );
  }

  String publicImageUrl(String path) => path.startsWith('http')
      ? path
      : _client.storage.from('attraction-images').getPublicUrl(path);

  Attraction _withDistance(Attraction attraction, LocationPoint? origin) {
    if (origin == null ||
        attraction.latitude == null ||
        attraction.longitude == null) {
      return attraction;
    }
    return attraction.copyWithDistance(
      LocationService.distanceKm(
        firstLatitude: origin.latitude,
        firstLongitude: origin.longitude,
        secondLatitude: attraction.latitude!,
        secondLongitude: attraction.longitude!,
      ),
    );
  }

  Future<Map<String, List<String>>> _getInterestTags() async {
    try {
      final rows = await _client
          .from('attraction_interest_tags')
          .select('attraction_id, tag');
      final result = <String, List<String>>{};
      for (final row in rows) {
        result
            .putIfAbsent(row['attraction_id'] as String, () => [])
            .add(row['tag'] as String);
      }
      return result;
    } catch (_) {
      return const {};
    }
  }

  Future<Set<String>> _getCompletedVisitCategories() async {
    if (currentUserId == null) return const {};
    try {
      final rows = await _client
          .from('bookings')
          .select('slot:attraction_slots(attraction:attractions(category))')
          .eq('tourist_id', currentUserId!)
          .eq('status', 'completed');
      return rows.map((row) {
        final slot = (row['slot'] as Map).cast<String, dynamic>();
        final attraction = (slot['attraction'] as Map).cast<String, dynamic>();
        return (attraction['category'] as String).toLowerCase();
      }).toSet();
    } catch (_) {
      return const {};
    }
  }

  Future<void> _recordImpressions(
    Iterable<RecommendationResult> results,
  ) async {
    if (currentUserId == null) return;
    try {
      await _client
          .from('recommendation_impressions')
          .insert(
            results
                .map(
                  (result) => {
                    'tourist_id': currentUserId,
                    'attraction_id': result.attraction.id,
                    'slot_id': result.recommendedSlot?.id,
                    'recommendation_score': result.score,
                    'reason': result.reasons.join('. '),
                    'context': {
                      'distance_km': result.attraction.distanceKm,
                      'crowd_source': 'slot_occupancy_estimate',
                    },
                  },
                )
                .toList(),
          );
    } catch (_) {
      // Recommendations remain usable if audit logging is temporarily unavailable.
    }
  }
}
