import '../models/attraction.dart';

const module2DemoTouristId = 'module2-demo-tourist';

List<Attraction> module2DemoAttractions() {
  final tomorrow = DateTime.now().add(
    const Duration(days: 1),
  );

  DateTime at(
      int dayOffset,
      int hour, [
        int minute = 0,
      ]) {
    final date = tomorrow.add(
      Duration(days: dayOffset),
    );

    return DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }

  Map<String, dynamic> slot(
      String id,
      DateTime startsAt,
      int capacity,
      int reserved,
      ) =>
      {
        'id': id,
        'starts_at':
        startsAt.toUtc().toIso8601String(),
        'ends_at': startsAt
            .add(
          const Duration(
            hours: 1,
            minutes: 30,
          ),
        )
            .toUtc()
            .toIso8601String(),
        'maximum_capacity': capacity,
        'reserved_capacity': reserved,
        'status':
        reserved >= capacity ? 'full' : 'open',
      };

  List<Map<String, dynamic>> dailyHours(
      String opens,
      String closes,
      ) =>
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
    String locationName = 'Kuala Lumpur',
  }) =>
      {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'location_name': locationName,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'entrance_price_myr': price,
        'facilities': facilities,
        'visitor_guidelines':
        'Arrive 15 minutes before your selected time slot.',
        'attraction_rules':
        'Follow staff instructions and keep the area clean.',
        'attraction_type': type,
        'maximum_capacity': capacity,
        'listing_status': 'approved',
        'cover_image_url': null,
        'attraction_images':
        <Map<String, dynamic>>[],
        'operating_hours':
        dailyHours(
          '09:00:00',
          '18:00:00',
        ),
        'attraction_slots': slots,
      };

  return [
    // ==========================================================
    // 1. MERDEKA HERITAGE WALK
    // ==========================================================

    Attraction.fromMap(
      attraction(
        id:
        '10000000-0000-0000-0000-000000000001',
        name:
        'Merdeka Heritage Walk',
        description:
        'A guided visit around Dataran Merdeka and Kuala Lumpur colonial-era landmarks.',
        category:
        'Historical Landmark',
        address:
        'Dataran Merdeka, Jalan Raja, 50050 Kuala Lumpur',
        latitude: 3.1478,
        longitude: 101.6937,
        price: 25,
        facilities: const [
          'Restrooms',
          'Wheelchair access',
          'Prayer room',
        ],
        type: 'outdoor',
        capacity: 120,
        slots: [
          slot(
            'demo-slot-1',
            at(0, 9),
            40,
            8,
          ),
          slot(
            'demo-slot-2',
            at(0, 11),
            30,
            18,
          ),
          slot(
            'demo-slot-3',
            at(1, 14),
            40,
            5,
          ),
        ],
      ),
    ),

    // ==========================================================
    // 2. ISLAMIC ARTS MUSEUM
    // ==========================================================

    Attraction.fromMap(
      attraction(
        id:
        '10000000-0000-0000-0000-000000000002',
        name:
        'Islamic Arts Museum Malaysia',
        description:
        'An indoor collection of Islamic decorative arts near Perdana Botanical Gardens.',
        category: 'Museum',
        address:
        'Jalan Lembah Perdana, 50480 Kuala Lumpur',
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
          slot(
            'demo-slot-4',
            at(0, 10),
            60,
            45,
          ),
          slot(
            'demo-slot-5',
            at(1, 12),
            60,
            20,
          ),
        ],
      ),
    ),

    // ==========================================================
    // 3. KL FOREST ECO PARK
    // ==========================================================

    Attraction.fromMap(
      attraction(
        id:
        '10000000-0000-0000-0000-000000000003',
        name:
        'KL Forest Eco Park',
        description:
        'A city-centre rainforest experience with canopy walks and native Malaysian flora.',
        category: 'Nature',
        address:
        'Jalan Puncak, 50250 Kuala Lumpur',
        latitude: 3.1529,
        longitude: 101.7048,
        price: 10,
        facilities: const [
          'Restrooms',
          'Parking',
        ],
        type: 'outdoor',
        capacity: 150,
        slots: [
          slot(
            'demo-slot-6',
            at(0, 16),
            50,
            12,
          ),
          slot(
            'demo-slot-7',
            at(1, 9),
            50,
            46,
          ),
        ],
      ),
    ),

    // ==========================================================
    // 4. PERDANA BOTANICAL GARDEN
    // ==========================================================

    Attraction.fromMap(
      attraction(
        id:
        '10000000-0000-0000-0000-000000000004',
        name:
        'Perdana Botanical Garden',
        description:
        'A large outdoor garden featuring landscaped areas, walking paths and relaxing green spaces.',
        category: 'Nature',
        address:
        'Jalan Kebun Bunga, Tasik Perdana, Kuala Lumpur',
        latitude: 3.1430,
        longitude: 101.6847,
        price: 0,
        facilities: const [
          'Restrooms',
          'Wheelchair access',
          'Parking',
          'Cafe',
        ],
        type: 'outdoor',
        capacity: 300,
        slots: [
          slot(
            'demo-slot-8',
            at(0, 9),
            100,
            20,
          ),
          slot(
            'demo-slot-9',
            at(0, 14),
            100,
            65,
          ),
          slot(
            'demo-slot-10',
            at(1, 10),
            100,
            10,
          ),
        ],
      ),
    ),

    // ==========================================================
    // 5. NATIONAL HERITAGE MUSEUM
    // ==========================================================

    Attraction.fromMap(
      attraction(
        id:
        '10000000-0000-0000-0000-000000000005',
        name:
        'National Heritage Museum',
        description:
        'An indoor museum featuring exhibitions about Malaysian history, culture and national heritage.',
        category: 'Museum',
        address:
        'Jalan Damansara, Kuala Lumpur',
        latitude: 3.1379,
        longitude: 101.6870,
        price: 5,
        facilities: const [
          'Restrooms',
          'Wheelchair access',
          'Cafe',
          'Parking',
        ],
        type: 'indoor',
        capacity: 200,
        slots: [
          slot(
            'demo-slot-11',
            at(0, 9),
            80,
            15,
          ),
          slot(
            'demo-slot-12',
            at(0, 13),
            80,
            50,
          ),
          slot(
            'demo-slot-13',
            at(1, 11),
            80,
            25,
          ),
        ],
      ),
    ),

    // ==========================================================
    // 6. CENTRAL MARKET CULTURAL CENTRE
    // ==========================================================

    Attraction.fromMap(
      attraction(
        id:
        '10000000-0000-0000-0000-000000000006',
        name:
        'Central Market Cultural Centre',
        description:
        'A cultural attraction featuring local arts, crafts, food and Malaysian cultural experiences.',
        category: 'Culture',
        address:
        'Jalan Hang Kasturi, 50050 Kuala Lumpur',
        latitude: 3.1459,
        longitude: 101.6954,
        price: 0,
        facilities: const [
          'Restrooms',
          'Wheelchair access',
          'Food court',
          'Prayer room',
        ],
        type: 'indoor',
        capacity: 250,
        slots: [
          slot(
            'demo-slot-14',
            at(0, 10),
            100,
            35,
          ),
          slot(
            'demo-slot-15',
            at(0, 15),
            100,
            75,
          ),
        ],
      ),
    ),

    // ==========================================================
    // 7. KL SCIENCE DISCOVERY CENTRE
    // ==========================================================

    Attraction.fromMap(
      attraction(
        id:
        '10000000-0000-0000-0000-000000000007',
        name:
        'KL Science Discovery Centre',
        description:
        'An interactive indoor attraction offering science and technology activities for visitors and families.',
        category: 'Science',
        address:
        'Kuala Lumpur City Centre, Kuala Lumpur',
        latitude: 3.1579,
        longitude: 101.7116,
        price: 80,
        facilities: const [
          'Restrooms',
          'Wheelchair access',
          'Cafe',
          'Parking',
        ],
        type: 'indoor',
        capacity: 220,
        slots: [
          slot(
            'demo-slot-16',
            at(0, 10),
            70,
            30,
          ),
          slot(
            'demo-slot-17',
            at(1, 14),
            70,
            15,
          ),
        ],
      ),
    ),

    // ==========================================================
    // 8. LAKE GARDENS FAMILY PARK
    // ==========================================================

    Attraction.fromMap(
      attraction(
        id:
        '10000000-0000-0000-0000-000000000008',
        name:
        'Lake Gardens Family Park',
        description:
        'An outdoor family recreation area suitable for walking, picnics and relaxing activities.',
        category: 'Family',
        address:
        'Tasik Perdana, Kuala Lumpur',
        latitude: 3.1424,
        longitude: 101.6860,
        price: 0,
        facilities: const [
          'Restrooms',
          'Wheelchair access',
          'Parking',
          'Playground',
        ],
        type: 'outdoor',
        capacity: 350,
        slots: [
          slot(
            'demo-slot-18',
            at(0, 9),
            120,
            25,
          ),
          slot(
            'demo-slot-19',
            at(0, 15),
            120,
            40,
          ),
        ],
      ),
    ),

    // ==========================================================
    // 9. CITY ART GALLERY
    // ==========================================================

    Attraction.fromMap(
      attraction(
        id:
        '10000000-0000-0000-0000-000000000009',
        name:
        'City Art Gallery',
        description:
        'An indoor gallery showcasing contemporary art, photography and local creative works.',
        category: 'Art',
        address:
        'Jalan Binjai, Kuala Lumpur',
        latitude: 3.1591,
        longitude: 101.7180,
        price: 15,
        facilities: const [
          'Restrooms',
          'Wheelchair access',
          'Cafe',
        ],
        type: 'indoor',
        capacity: 100,
        slots: [
          slot(
            'demo-slot-20',
            at(0, 11),
            40,
            10,
          ),
          slot(
            'demo-slot-21',
            at(1, 14),
            40,
            32,
          ),
        ],
      ),
    ),

    // ==========================================================
    // 10. RIVER OF LIFE HERITAGE TRAIL
    // ==========================================================

    Attraction.fromMap(
      attraction(
        id:
        '10000000-0000-0000-0000-000000000010',
        name:
        'River of Life Heritage Trail',
        description:
        'An outdoor heritage walking route connecting historical buildings and riverfront scenery.',
        category:
        'Historical Landmark',
        address:
        'Jalan Benteng, Kuala Lumpur',
        latitude: 3.1475,
        longitude: 101.6953,
        price: 0,
        facilities: const [
          'Restrooms',
          'Wheelchair access',
        ],
        type: 'outdoor',
        capacity: 120,

        // Both slots intentionally full.
        // Useful for testing alternative attraction suggestions.
        slots: [
          slot(
            'demo-slot-22',
            at(0, 10),
            40,
            40,
          ),
          slot(
            'demo-slot-23',
            at(1, 14),
            40,
            40,
          ),
        ],
      ),
    ),
  ];
}

// ================================================================
// DEMO INTEREST TAGS
// ================================================================

const module2DemoInterestTags =
<String, List<String>>{
  '10000000-0000-0000-0000-000000000001': [
    'architecture',
    'culture',
    'history',
    'walking',
  ],

  '10000000-0000-0000-0000-000000000002': [
    'art',
    'culture',
    'family',
    'history',
  ],

  '10000000-0000-0000-0000-000000000003': [
    'nature',
    'photography',
    'walking',
    'adventure',
  ],

  '10000000-0000-0000-0000-000000000004': [
    'nature',
    'family',
    'photography',
    'walking',
  ],

  '10000000-0000-0000-0000-000000000005': [
    'history',
    'culture',
    'family',
    'education',
  ],

  '10000000-0000-0000-0000-000000000006': [
    'culture',
    'art',
    'food',
    'shopping',
    'family',
  ],

  '10000000-0000-0000-0000-000000000007': [
    'science',
    'technology',
    'education',
    'family',
  ],

  '10000000-0000-0000-0000-000000000008': [
    'family',
    'nature',
    'walking',
    'relaxation',
  ],

  '10000000-0000-0000-0000-000000000009': [
    'art',
    'culture',
    'photography',
  ],

  '10000000-0000-0000-0000-000000000010': [
    'history',
    'culture',
    'photography',
    'walking',
  ],
};