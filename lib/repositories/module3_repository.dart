import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/module3_models.dart';
import '../models/published_itinerary.dart';
import '../models/saved_itinerary.dart';
import '../services/location_service.dart';

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

  Future<List<AttractionSlot>> fetchRescheduleSlots(TourBooking booking) async {
    final rows = await _client
        .from('attraction_slots')
        .select(_slotSelection)
        .eq('attraction_id', booking.slot.attractionId)
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

  Future<BookingConflictAnalysis> previewBooking({
    required AttractionSlot slot,
    required int visitors,
  }) async {
    final issues = <BookingConflictIssue>[];
    if (slot.status != 'open' || slot.startsAt.isBefore(DateTime.now())) {
      issues.add(
        const BookingConflictIssue(
          title: 'Slot unavailable',
          detail: 'This slot is no longer open for registration.',
        ),
      );
    } else if (slot.remainingCapacity < visitors) {
      issues.add(
        BookingConflictIssue(
          title: 'Insufficient capacity',
          detail:
              'Only ${slot.remainingCapacity} spaces remain for $visitors visitors.',
        ),
      );
    }

    final closures = await _client
        .from('closure_periods')
        .select('closure_type, reason, starts_at, ends_at')
        .eq('attraction_id', slot.attractionId)
        .lt('starts_at', slot.endsAt.toUtc().toIso8601String())
        .gt('ends_at', slot.startsAt.toUtc().toIso8601String());
    if (closures.isNotEmpty) {
      final reason = closures.first['reason']?.toString().trim();
      issues.add(
        BookingConflictIssue(
          title: 'Attraction closed',
          detail: reason?.isNotEmpty == true
              ? reason!
              : 'A closure or maintenance period overlaps this visit.',
        ),
      );
    }

    final bookings =
        (await fetchBookings())
            .where((booking) => booking.status == BookingStatus.confirmed)
            .toList()
          ..sort((a, b) => a.slot.startsAt.compareTo(b.slot.startsAt));
    for (final booking in bookings) {
      final overlaps =
          booking.slot.startsAt.isBefore(slot.endsAt) &&
          booking.slot.endsAt.isAfter(slot.startsAt);
      if (overlaps) {
        issues.add(
          BookingConflictIssue(
            title: 'Booking overlap',
            detail:
                '${booking.slot.attractionName} is already booked from '
                '${clockTime(booking.slot.startsAt)} to ${clockTime(booking.slot.endsAt)}.',
          ),
        );
      }
    }

    final previous = bookings
        .where(
          (booking) =>
              _isSameLocalDay(booking.slot.endsAt, slot.startsAt) &&
              !booking.slot.endsAt.isAfter(slot.startsAt),
        )
        .fold<TourBooking?>(
          null,
          (latest, booking) =>
              latest == null || booking.slot.endsAt.isAfter(latest.slot.endsAt)
              ? booking
              : latest,
        );
    final next = bookings
        .where(
          (booking) =>
              _isSameLocalDay(booking.slot.startsAt, slot.endsAt) &&
              !booking.slot.startsAt.isBefore(slot.endsAt),
        )
        .fold<TourBooking?>(
          null,
          (earliest, booking) =>
              earliest == null ||
                  booking.slot.startsAt.isBefore(earliest.slot.startsAt)
              ? booking
              : earliest,
        );
    if (previous != null) {
      _addTravelIssue(
        issues,
        from: previous.slot,
        to: slot,
        availableMinutes: slot.startsAt
            .difference(previous.slot.endsAt)
            .inMinutes,
      );
    }
    if (next != null) {
      _addTravelIssue(
        issues,
        from: slot,
        to: next.slot,
        availableMinutes: next.slot.startsAt.difference(slot.endsAt).inMinutes,
      );
    }

    final alternatives = issues.any((issue) => issue.blocking)
        ? await _fetchAlternativeSlots(slot, visitors)
        : const <AttractionSlot>[];
    return BookingConflictAnalysis(
      issues: issues,
      alternativeSlots: alternatives,
    );
  }

  void _addTravelIssue(
    List<BookingConflictIssue> issues, {
    required AttractionSlot from,
    required AttractionSlot to,
    required int availableMinutes,
  }) {
    final requiredMinutes = _travelMinutes(from, to);
    if (availableMinutes >= requiredMinutes) return;
    issues.add(
      BookingConflictIssue(
        title: 'Insufficient travel time',
        detail:
            '${from.attractionName} to ${to.attractionName} needs about '
            '$requiredMinutes minutes including a safety buffer, but only '
            '$availableMinutes minutes are available.',
      ),
    );
  }

  int _travelMinutes(AttractionSlot from, AttractionSlot to) {
    if (from.latitude == null ||
        from.longitude == null ||
        to.latitude == null ||
        to.longitude == null)
      return 45;
    final distance = LocationService.distanceKm(
      firstLatitude: from.latitude!,
      firstLongitude: from.longitude!,
      secondLatitude: to.latitude!,
      secondLongitude: to.longitude!,
    );
    return LocationService.estimatedTravelMinutes(distance);
  }

  bool _isSameLocalDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  Future<List<AttractionSlot>> _fetchAlternativeSlots(
    AttractionSlot selected,
    int visitors,
  ) async {
    final rows = await _client
        .from('attraction_slots')
        .select(_slotSelection)
        .eq('attraction_id', selected.attractionId)
        .eq('status', 'open')
        .neq('id', selected.id)
        .gt('starts_at', DateTime.now().toUtc().toIso8601String())
        .order('starts_at')
        .limit(50);
    return rows
        .map(AttractionSlot.fromMap)
        .where((item) => item.remainingCapacity >= visitors)
        .take(3)
        .toList();
  }

  Future<List<TourBooking>> fetchBookings() async {
    final rows = await _client
        .from('bookings')
        .select(_bookingSelection)
        .eq('tourist_id', _userId)
        .order('created_at', ascending: false);

    return rows
        .map((row) => TourBooking.tryFromMap(Map<String, dynamic>.from(row)))
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
    final rows = await _client
        .from('itineraries')
        .select(
          'id, title, itinerary_date, end_date, itinerary_items(booking_id, position)',
        )
        .eq('tourist_id', _userId)
        .order('updated_at', ascending: false);
    final publishedRows = await _client
        .from('published_itineraries')
        .select('source_itinerary_id')
        .eq('owner_id', _userId);
    final publishedIds = publishedRows
        .map((row) => row['source_itinerary_id'] as String)
        .toSet();
    return rows
        .map(SavedItinerary.fromMap)
        .map((item) => item.copyWithPublished(publishedIds.contains(item.id)))
        .toList();
  }

  Future<List<PublishedItinerary>> fetchPublishedItineraries() async {
    final rows = await _client
        .from('published_itineraries')
        .select(
          'id, title, description, author_name, itinerary_date, '
          'published_at, stops:published_itinerary_stops('
          'position, visit_date, starts_at, ends_at, travel_minutes_from_previous, '
          'distance_km_from_previous, attraction:attractions!inner('
          'id, name, category, location_name, cover_image_url, '
          'attraction_images(storage_path, display_order)))',
        )
        .order('published_at', ascending: false);
    return rows.map(PublishedItinerary.fromMap).toList();
  }

  Future<void> publishItinerary({
    required String itineraryId,
    required String description,
    required bool showAuthor,
  }) async {
    await _client.rpc(
      'publish_my_itinerary',
      params: {
        'p_itinerary_id': itineraryId,
        'p_description': description.trim(),
        'p_show_author': showAuthor,
      },
    );
  }

  Future<void> unpublishItinerary(String itineraryId) async {
    await _client.rpc(
      'unpublish_my_itinerary',
      params: {'p_itinerary_id': itineraryId},
    );
  }

  Future<void> deleteItinerary(String id) async {
    await _client
        .from('itineraries')
        .delete()
        .eq('id', id)
        .eq('tourist_id', _userId);
  }

  Future<String> saveItinerary({
    required String title,
    required ItineraryPlan plan,
    String? itineraryId,
  }) async {
    if (plan.bookings.isEmpty) {
      throw const FormatException('Select at least one booking.');
    }
    final result = await _client.rpc(
      'save_my_itinerary',
      params: {
        'p_itinerary_id': itineraryId,
        'p_title': title.trim(),
        'p_booking_ids': plan.bookings.map((b) => b.id).toList(),
        'p_travel_minutes': plan.legs.map((leg) => leg.travelMinutes).toList(),
        'p_distances_km': plan.legs.map((leg) => leg.distanceKm).toList(),
        'p_uses_road_routes': plan.usesRoadRoutes,
      },
    );
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
