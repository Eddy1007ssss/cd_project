import 'dart:math' as math;

enum BookingStatus { confirmed, cancelled, completed }

class AttractionSlot {
  const AttractionSlot({
    required this.id,
    required this.attractionId,
    required this.attractionName,
    required this.category,
    required this.locationName,
    required this.startsAt,
    required this.endsAt,
    required this.maximumCapacity,
    required this.reservedCapacity,
    required this.status,
    this.latitude,
    this.longitude,
    this.coverImageUrl,
  });

  final String id;
  final String attractionId;
  final String attractionName;
  final String category;
  final String locationName;
  final DateTime startsAt;
  final DateTime endsAt;
  final int maximumCapacity;
  final int reservedCapacity;
  final String status;
  final double? latitude;
  final double? longitude;
  final String? coverImageUrl;

  int get remainingCapacity => maximumCapacity - reservedCapacity;

  bool get isBookable =>
      status == 'open' &&
      remainingCapacity > 0 &&
      startsAt.isAfter(DateTime.now());

  factory AttractionSlot.fromMap(Map<String, dynamic> map) {
    final attraction =
        (map['attraction'] as Map?)?.cast<String, dynamic>() ??
        (map['attractions'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    return AttractionSlot(
      id: map['id'] as String,
      attractionId: (map['attraction_id'] ?? attraction['id'] ?? '') as String,
      attractionName: attraction['name'] as String? ?? 'Attraction',
      category: attraction['category'] as String? ?? 'Attraction',
      locationName: attraction['location_name'] as String? ?? 'Malaysia',
      startsAt: DateTime.parse(map['starts_at'] as String).toLocal(),
      endsAt: DateTime.parse(map['ends_at'] as String).toLocal(),
      maximumCapacity: map['maximum_capacity'] as int,
      reservedCapacity: map['reserved_capacity'] as int? ?? 0,
      status: map['status'] as String,
      latitude: (attraction['latitude'] as num?)?.toDouble(),
      longitude: (attraction['longitude'] as num?)?.toDouble(),
      coverImageUrl: attraction['cover_image_url'] as String?,
    );
  }
}

class TourBooking {
  const TourBooking({
    required this.id,
    required this.bookingCode,
    required this.qrToken,
    required this.visitorCount,
    required this.status,
    required this.slot,
    required this.createdAt,
  });

  final String id;
  final String bookingCode;
  final String qrToken;
  final int visitorCount;
  final BookingStatus status;
  final AttractionSlot slot;
  final DateTime createdAt;

  bool get isUpcoming =>
      status == BookingStatus.confirmed &&
      slot.startsAt.isAfter(DateTime.now());

  factory TourBooking.fromMap(Map<String, dynamic> map) {
    final rawSlot =
        (map['slot'] as Map?)?.cast<String, dynamic>() ??
        (map['attraction_slots'] as Map?)?.cast<String, dynamic>();
    if (rawSlot == null) {
      throw const FormatException(
        'Booking response does not include its slot.',
      );
    }
    return TourBooking(
      id: map['id'] as String,
      bookingCode: map['booking_code'] as String,
      qrToken: map['qr_token'] as String,
      visitorCount: map['visitor_count'] as int,
      status: BookingStatus.values.byName(map['status'] as String),
      slot: AttractionSlot.fromMap(rawSlot),
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }
}

class ItineraryLeg {
  const ItineraryLeg({required this.distanceKm, required this.travelMinutes});

  final double distanceKm;
  final int travelMinutes;
}

class ItineraryPlan {
  const ItineraryPlan({
    required this.bookings,
    required this.legs,
    required this.hasConflict,
  });

  final List<TourBooking> bookings;
  final List<ItineraryLeg> legs;
  final bool hasConflict;

  static ItineraryPlan build(Iterable<TourBooking> selectedBookings) {
    final bookings = selectedBookings.toList()
      ..sort((a, b) => a.slot.startsAt.compareTo(b.slot.startsAt));
    final legs = <ItineraryLeg>[];
    var conflict = false;
    for (var index = 1; index < bookings.length; index++) {
      final previous = bookings[index - 1].slot;
      final current = bookings[index].slot;
      final distance = _distanceKm(previous, current);
      final travelMinutes = distance == null
          ? 45
          : (distance / 30 * 60).ceil() + 15;
      legs.add(
        ItineraryLeg(distanceKm: distance ?? 0, travelMinutes: travelMinutes),
      );
      final availableMinutes = current.startsAt
          .difference(previous.endsAt)
          .inMinutes;
      if (availableMinutes < travelMinutes) conflict = true;
    }
    return ItineraryPlan(bookings: bookings, legs: legs, hasConflict: conflict);
  }

  static double? _distanceKm(AttractionSlot first, AttractionSlot second) {
    if (first.latitude == null ||
        first.longitude == null ||
        second.latitude == null ||
        second.longitude == null) {
      return null;
    }
    double radians(double degrees) => degrees * math.pi / 180;
    final latitudeDelta = radians(second.latitude! - first.latitude!);
    final longitudeDelta = radians(second.longitude! - first.longitude!);
    final value =
        math.pow(math.sin(latitudeDelta / 2), 2) +
        math.cos(radians(first.latitude!)) *
            math.cos(radians(second.latitude!)) *
            math.pow(math.sin(longitudeDelta / 2), 2);
    return 6371 * 2 * math.asin(math.sqrt(value));
  }
}

String shortDate(DateTime date) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String clockTime(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

String slotTime(AttractionSlot slot) =>
    '${clockTime(slot.startsAt)} – ${clockTime(slot.endsAt)}';
