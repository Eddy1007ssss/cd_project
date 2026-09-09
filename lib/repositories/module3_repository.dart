import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/module3_models.dart';
import '../models/saved_itinerary.dart';

const _slotSelection =
    'id, attraction_id, starts_at, ends_at, maximum_capacity, '
    'reserved_capacity, status, attraction:attractions!inner('
    'id, name, category, location_name, latitude, longitude, '
    'cover_image_url, check_in_method, geofence_radius_m)';

const _bookingSelection =
    'id, booking_code, qr_token, visitor_count, status, '
    'created_at, completed_at, '
    'slot:attraction_slots!inner($_slotSelection), '
    'check_in:attraction_check_ins(checked_in_at, checked_out_at)';

class Module3Repository {
  Module3Repository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;

    if (id == null) {
      throw const AuthException('Please sign in as a tourist.');
    }

    return id;
  }

  Future<List<AttractionSlot>> fetchSlots({
    required String attractionId,
    required DateTime date,
  }) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day + 1);

    final rows = await _client
        .from('attraction_slots')
        .select(_slotSelection)
        .eq('attraction_id', attractionId)
        .gte('starts_at', start.toUtc().toIso8601String())
        .lt('starts_at', end.toUtc().toIso8601String())
        .order('starts_at');

    return rows.map(AttractionSlot.fromMap).toList();
  }

  Future<List<AttractionSlot>> fetchRescheduleSlots(
    TourBooking booking, {
    String? attractionId,
  }) async {
    final rows = await _client
        .from('attraction_slots')
        .select(_slotSelection)
        .eq('attraction_id', attractionId ?? booking.slot.attractionId)
        .eq('status', 'open')
        .neq('id', booking.slot.id)
        .gt('starts_at', DateTime.now().toUtc().toIso8601String())
        .order('starts_at')
        .limit(1000);

    return rows
        .map(AttractionSlot.fromMap)
        .where(
          (slot) =>
              slot.isBookable && slot.remainingCapacity >= booking.visitorCount,
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchRescheduleAttractions() async =>
      await _client
          .from('attractions')
          .select('id, name')
          .eq('listing_status', 'approved')
          .order('name');

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
        .select(_bookingSelection)
        .eq('tourist_id', _userId)
        .order('created_at', ascending: false);

    return rows
        .map(
          (row) => TourBooking.tryFromMap(Map<String, dynamic>.from(row)),
        )
        .whereType<TourBooking>()
        .toList();
  }

  Future<TourBooking> fetchBooking(String bookingId) async {
    final row = await _client
        .from('bookings')
        .select(_bookingSelection)
        .eq('id', bookingId)
        .eq('tourist_id', _userId)
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

  Future<List<SavedItinerary>> fetchItineraries() async {
    final rows = await _client.from('itineraries')
        .select('id, title, itinerary_date, itinerary_items(booking_id, position)')
        .eq('tourist_id', _userId).order('updated_at', ascending: false);
    return rows.map(SavedItinerary.fromMap).toList();
  }

  Future<void> deleteItinerary(String id) async {
    await _client.from('itineraries').delete().eq('id', id).eq('tourist_id', _userId);
  }

  Future<String> saveItinerary({
    required String title,
    required ItineraryPlan plan,
    String? itineraryId,
  }) async {
    if (plan.bookings.isEmpty) {
      throw const FormatException('Select at least one booking.');
    }
    final result = await _client.rpc('save_my_itinerary', params: {
      'p_itinerary_id': itineraryId,
      'p_title': title.trim(),
      'p_booking_ids': plan.bookings.map((b) => b.id).toList(),
      'p_travel_minutes': plan.legs.map((leg) => leg.travelMinutes).toList(),
      'p_distances_km': plan.legs.map((leg) => leg.distanceKm).toList(),
      'p_uses_road_routes': plan.usesRoadRoutes,
    });
    return result as String;
  }

  Map<String, dynamic> _singleMap(Object? result) {
    if (result is Map<String, dynamic>) {
      return result;
    }

    if (result is Map) {
      return result.cast<String, dynamic>();
    }

    if (result is List && result.isNotEmpty && result.first is Map) {
      return (result.first as Map).cast<String, dynamic>();
    }

    throw const FormatException('The server returned an invalid booking.');
  }
}

String bookingErrorMessage(Object error) {
  final message = error.toString();

  if (message.contains('INSUFFICIENT_CAPACITY')) {
    return 'There are not enough remaining spaces. '
        'Choose another slot or fewer visitors.';
  }

  if (message.contains('BOOKING_OVERLAP')) {
    return 'This visit overlaps one of your confirmed bookings.';
  }

  if (message.contains('INSUFFICIENT_TRAVEL_TIME')) {
    return 'There is not enough travel time from your adjacent booking. '
        'Choose a later slot.';
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
