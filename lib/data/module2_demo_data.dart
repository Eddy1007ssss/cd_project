import '../models/attraction.dart';

const module2DemoTouristId = 'module2-demo-tourist';

List<Attraction> module2DemoAttractions() {
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  DateTime at(int dayOffset, int hour, [int minute = 0]) {
    final date = tomorrow.add(Duration(days: dayOffset));
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  Map<String, dynamic> slot(
    String id,
    DateTime startsAt,
    int capacity,
    int reserved,
  ) => {
    'id': id,
    'starts_at': startsAt.toUtc().toIso8601String(),
    'ends_at': startsAt
        .add(const Duration(hours: 1, minutes: 30))
        .toUtc()
        .toIso8601String(),
    'maximum_capacity': capacity,
    'reserved_capacity': reserved,
    'status': reserved >= capacity ? 'full' : 'open',
  };

  List<Map<String, dynamic>> dailyHours(String opens, String closes) =>
      List.generate(
        7,
        (day) => {
          'day_of_week': day,
          'is_closed': false,
          'opens_at': opens,
          'closes_at': closes,
          'note': null,
        },
      );

  Map<String, dynamic> attraction({
    required String id,
    required String name,
    required String description,
    required String category,
    required String address,
    required double latitude,
    required double longitude,
    required double price,
    required List<String> facilities,
    required String type,
    required int capacity,
    required List<Map<String, dynamic>> slots,
  }) => {
    'id': id,
    'name': name,
    'description': description,
    'category': category,
    'location_name': 'Kuala Lumpur',
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'entrance_price_myr': price,
    'facilities': facilities,
    'visitor_guidelines': 'Arrive 15 minutes before your selected time slot.',
    'attraction_rules': 'Follow staff instructions and keep the area clean.',
    'attraction_type': type,
    'maximum_capacity': capacity,
    'listing_status': 'approved',
    'cover_image_url': null,
    'attraction_images': <Map<String, dynamic>>[],
    'operating_hours': dailyHours('09:00:00', '18:00:00'),
    'attraction_slots': slots,
  };

  return [
    Attraction.fromMap(
      attraction(
        id: '10000000-0000-0000-0000-000000000001',
        name: 'Merdeka Heritage Walk',
        description:
            'A guided visit around Dataran Merdeka and Kuala Lumpur colonial-era landmarks.',
        category: 'Historical Landmark',
        address: 'Dataran Merdeka, Jalan Raja, 50050 Kuala Lumpur',
        latitude: 3.1478,
        longitude: 101.6937,
        price: 25,
        facilities: const ['Restrooms', 'Wheelchair access', 'Prayer room'],
        type: 'outdoor',
        capacity: 120,
        slots: [
          slot('demo-slot-1', at(0, 9), 40, 8),
          slot('demo-slot-2', at(0, 11), 30, 18),
          slot('demo-slot-3', at(1, 14), 40, 5),
        ],
      ),
    ),
    Attraction.fromMap(
      attraction(
        id: '10000000-0000-0000-0000-000000000002',
        name: 'Islamic Arts Museum Malaysia',
        description:
            'A renowned indoor collection of Islamic decorative arts beside Perdana Botanical Gardens.',
        category: 'Museum',
        address: 'Jalan Lembah Perdana, 50480 Kuala Lumpur',
        latitude: 3.1415,
        longitude: 101.6890,
        price: 20,
        facilities: const [
          'Restrooms',
          'Wheelchair access',
          'Cafe',
          'Prayer room',
        ],
        type: 'indoor',
        capacity: 180,
        slots: [
          slot('demo-slot-4', at(0, 10), 60, 45),
          slot('demo-slot-5', at(1, 12), 60, 20),
        ],
      ),
    ),
    Attraction.fromMap(
      attraction(
        id: '10000000-0000-0000-0000-000000000003',
        name: 'KL Forest Eco Park',
        description:
            'A city-centre rainforest experience with canopy walks and native Malaysian flora.',
        category: 'Nature',
        address: 'Jalan Puncak, 50250 Kuala Lumpur',
        latitude: 3.1529,
        longitude: 101.7048,
        price: 10,
        facilities: const ['Restrooms', 'Parking'],
        type: 'outdoor',
        capacity: 150,
        slots: [
          slot('demo-slot-6', at(0, 16), 50, 12),
          slot('demo-slot-7', at(1, 9), 50, 46),
        ],
      ),
    ),
  ];
}

const module2DemoInterestTags = <String, List<String>>{
  '10000000-0000-0000-0000-000000000001': [
    'architecture',
    'culture',
    'history',
  ],
  '10000000-0000-0000-0000-000000000002': ['art', 'culture', 'family'],
  '10000000-0000-0000-0000-000000000003': ['nature', 'photography', 'walking'],
};
