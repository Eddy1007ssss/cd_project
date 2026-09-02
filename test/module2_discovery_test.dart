import 'package:cd_project/models/attraction.dart';
import 'package:cd_project/models/preference_profile.dart';
import 'package:cd_project/data/module2_demo_data.dart';
import 'package:cd_project/services/location_service.dart';
import 'package:cd_project/services/recommendation_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('anonymous Module 2 demo contains approved bookable attractions', () {
    final attractions = module2DemoAttractions();

    expect(attractions, hasLength(3));
    expect(
      attractions.every((item) => item.listingStatus == 'approved'),
      isTrue,
    );
    expect(attractions.every((item) => item.availableSlots.isNotEmpty), isTrue);
    expect(
      module2DemoInterestTags.keys,
      containsAll(attractions.map((item) => item.id)),
    );
  });

  test('parses the shared Module 1 attraction and slot column names', () {
    final attraction = Attraction.fromMap(_map());

    expect(attraction.name, 'Merdeka Heritage Walk');
    expect(attraction.entrancePriceMyr, 25);
    expect(attraction.locationName, 'Kuala Lumpur');
    expect(attraction.availableSlots.single.remainingCapacity, 30);
    expect(attraction.estimatedCrowdLevel, 'Low');
    expect(attraction.isAccessible, isTrue);
  });

  test(
    'search and filters use derived distance, price, crowd and facilities',
    () {
      final attraction = Attraction.fromMap(_map()).copyWithDistance(2.4);

      expect(
        attractionMatches(
          attraction: attraction,
          keyword: 'heritage',
          filters: const AttractionFilters(
            maximumPrice: 30,
            maximumDistanceKm: 3,
            crowdLevel: 'Low',
            requiredFacility: 'wheelchair',
          ),
        ),
        isTrue,
      );
      expect(
        attractionMatches(
          attraction: attraction,
          filters: const AttractionFilters(maximumPrice: 10),
        ),
        isFalse,
      );
    },
  );

  test('Haversine distance and travel estimate are deterministic', () {
    final distance = LocationService.distanceKm(
      firstLatitude: 3.1478,
      firstLongitude: 101.6937,
      secondLatitude: 3.1415,
      secondLongitude: 101.6890,
    );

    expect(distance, inInclusiveRange(.7, 1.0));
    expect(
      LocationService.estimatedTravelMinutes(distance),
      greaterThanOrEqualTo(16),
    );
  });

  test('recommendations are grounded in preferences and completed visits', () {
    final attraction = Attraction.fromMap(_map()).copyWithDistance(2);
    const preferences = PreferenceProfile(
      touristId: 'tourist',
      interests: ['history'],
      maxBudgetMyr: 40,
      travelRadiusKm: 10,
      preferredCrowdLevel: 'moderate',
      requiredFacilities: ['Restrooms'],
    );

    final result = RecommendationEngine.score(
      attraction: attraction,
      preferences: preferences,
      tags: const ['history', 'culture'],
      previousCategories: const {'historical landmark'},
    );

    expect(result.percentage, 100);
    expect(result.reasons, anyElement(contains('interests')));
    expect(result.reasons, anyElement(contains('completed')));
    expect(result.recommendedSlot, isNotNull);
  });

  test('full and closed slots cannot be recommended', () {
    final map = _map();
    map['attraction_slots'] = [
      {
        'id': 'closed',
        'starts_at': DateTime.now()
            .add(const Duration(days: 1))
            .toUtc()
            .toIso8601String(),
        'ends_at': DateTime.now()
            .add(const Duration(days: 1, hours: 1))
            .toUtc()
            .toIso8601String(),
        'maximum_capacity': 20,
        'reserved_capacity': 20,
        'status': 'full',
      },
    ];

    expect(Attraction.fromMap(map).availableSlots, isEmpty);
  });
}

Map<String, dynamic> _map() => {
  'id': 'attraction-1',
  'name': 'Merdeka Heritage Walk',
  'description': 'Historic architecture and guided culture walk.',
  'category': 'Historical Landmark',
  'location_name': 'Kuala Lumpur',
  'address': 'Dataran Merdeka',
  'latitude': 3.1478,
  'longitude': 101.6937,
  'entrance_price_myr': 25,
  'facilities': ['Restrooms', 'Wheelchair access'],
  'visitor_guidelines': 'Arrive early.',
  'attraction_rules': 'Stay with the guide.',
  'attraction_type': 'outdoor',
  'maximum_capacity': 120,
  'listing_status': 'approved',
  'cover_image_url': null,
  'attraction_images': [],
  'operating_hours': [
    {
      'day_of_week': 0,
      'is_closed': false,
      'opens_at': '09:00:00',
      'closes_at': '18:00:00',
      'note': null,
    },
  ],
  'attraction_slots': [
    {
      'id': 'slot-1',
      'starts_at': DateTime.now()
          .add(const Duration(days: 1))
          .toUtc()
          .toIso8601String(),
      'ends_at': DateTime.now()
          .add(const Duration(days: 1, hours: 1))
          .toUtc()
          .toIso8601String(),
      'maximum_capacity': 40,
      'reserved_capacity': 10,
      'status': 'open',
    },
  ],
};
