import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/module3_models.dart';

const _slotSelection =
    'id, attraction_id, starts_at, ends_at, maximum_capacity, '
    'reserved_capacity, status, attraction:attractions('
    'id, name, category, location_name, latitude, longitude, cover_image_url)';

class Module3Repository {
  Module3Repository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthException('Please sign in as a tourist.');
    return id;
  }

  Future<List<AttractionSlot>> fetchSlots({
    required String attractionId,
    required DateTime date,
  }) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final rows = await _client
        .from('attraction_slots')
        .select(_slotSelection)
        .eq('attraction_id', attractionId)
        .gte('starts_at', start.toUtc().toIso8601String())
        .lt('starts_at', end.toUtc().toIso8601String())
        .order('starts_at');
    return rows.map(AttractionSlot.fromMap).toList();
  }

  Future<List<AttractionSlot>> fetchRescheduleSlots(TourBooking booking) async {
    final rows = await _client
        .from('attraction_slots')
        .select(_slotSelection)
        .eq('attraction_id', booking.slot.attractionId)
        .neq('id', booking.slot.id)
        .gt('starts_at', DateTime.now().toUtc().toIso8601String())
        .order('starts_at')
        .limit(20);
    return rows
        .map(AttractionSlot.fromMap)
        .where(
          (slot) =>
              slot.isBookable && slot.remainingCapacity >= booking.visitorCount,
        )
        .toList();
  }

  Future<TourBooking> createBooking({
    required String slotId,
    required int visitors,
  }) async {
    final result = await _client.rpc(
      'create_booking',
      params: {'target_slot_id': slotId, 'requested_visitors': visitors},
    );
    final map = _singleMap(result);
    return fetchBooking(map['id'] as String);
  }

  Future<List<TourBooking>> fetchBookings() async {
    final rows = await _client
        .from('bookings')
        .select(
          'id, booking_code, qr_token, visitor_count, status, created_at, '
          'slot:attraction_slots($_slotSelection)',
        )
        .eq('tourist_id', _userId)
        .order('created_at', ascending: false);
    return rows.map(TourBooking.fromMap).toList();
  }

  Future<TourBooking> fetchBooking(String bookingId) async {
    final row = await _client
        .from('bookings')
        .select(
          'id, booking_code, qr_token, visitor_count, status, created_at, '
          'slot:attraction_slots($_slotSelection)',
        )
        .eq('id', bookingId)
        .single();
    return TourBooking.fromMap(row);
  }

  Future<TourBooking> cancelBooking(String bookingId) async {
    await _client.rpc(
      'cancel_booking',
      params: {'target_booking_id': bookingId},
    );
    return fetchBooking(bookingId);
  }

  Future<TourBooking> rescheduleBooking({
    required String bookingId,
    required String newSlotId,
  }) async {
    await _client.rpc(
      'reschedule_booking',
      params: {'target_booking_id': bookingId, 'new_slot_id': newSlotId},
    );
    return fetchBooking(bookingId);
  }

  Future<String> saveItinerary({
    required String title,
    required ItineraryPlan plan,
  }) async {
    if (plan.bookings.isEmpty) {
      throw const FormatException('Select at least one booking.');
    }
    final itinerary = await _client
        .from('itineraries')
        .insert({
          'tourist_id': _userId,
          'title': title.trim(),
          'itinerary_date': plan.bookings.first.slot.startsAt
              .toIso8601String()
              .substring(0, 10),
          'status': plan.hasConflict ? 'conflict_detected' : 'conflict_free',
        })
        .select('id')
        .single();
    final itineraryId = itinerary['id'] as String;
    final items = <Map<String, dynamic>>[];
    for (var index = 0; index < plan.bookings.length; index++) {
      final leg = index == 0 ? null : plan.legs[index - 1];
      items.add({
        'itinerary_id': itineraryId,
        'booking_id': plan.bookings[index].id,
        'position': index,
        'travel_minutes_from_previous': leg?.travelMinutes,
        'distance_km_from_previous': leg?.distanceKm,
        'safety_buffer_minutes': 15,
      });
    }
    await _client.from('itinerary_items').insert(items);
    return itineraryId;
  }

  Map<String, dynamic> _singleMap(dynamic result) {
    if (result is Map<String, dynamic>) return result;
    if (result is List && result.isNotEmpty && result.first is Map) {
      return (result.first as Map).cast<String, dynamic>();
    }
    throw const FormatException('The server returned an invalid booking.');
  }
}

String bookingErrorMessage(Object error) {
  final message = error.toString();
  if (message.contains('INSUFFICIENT_CAPACITY')) {
    return 'There are not enough remaining spaces. Choose another slot or fewer visitors.';
  }
  if (message.contains('BOOKING_OVERLAP')) {
    return 'This visit overlaps one of your confirmed bookings.';
  }
  if (message.contains('INSUFFICIENT_TRAVEL_TIME')) {
    return 'There is not enough travel time from your adjacent booking. Choose a later slot.';
  }
  if (message.contains('ATTRACTION_CLOSED')) {
    return 'The attraction is closed or under maintenance during this slot.';
  }
  if (message.contains('SLOT_UNAVAILABLE') ||
      message.contains('ATTRACTION_UNAVAILABLE')) {
    return 'This slot is no longer available. Please select another slot.';
  }
  if (message.contains('BOOKING_NOT_ACTIVE')) {
    return 'Only a confirmed booking can be changed.';
  }
  if (message.contains('Tourist access required')) {
    return 'Please sign in using a tourist account.';
  }
  return 'Something went wrong while updating the booking. Please try again.';
}
