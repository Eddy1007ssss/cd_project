import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/engagement_models.dart';

const _visitSelection =
    'id, booking_code, slot:attraction_slots(starts_at, '
    'attraction:attractions(id, name))';

abstract interface class StaffCheckInGateway {
  Future<StaffBookingVerification> verifyStaffBooking(
    String bookingCodeOrToken,
  );

  Future<StaffBookingVerification> confirmStaffCheckIn(String bookingId);
}

class EngagementRepository implements StaffCheckInGateway {
  EngagementRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthException('Please sign in to continue.');
    return id;
  }

  Future<List<VisitOption>> fetchCompletedVisitsWithoutFeedback() async {
    final bookings = await _client
        .from('bookings')
        .select(_visitSelection)
        .eq('tourist_id', _userId)
        .eq('status', 'completed')
        .order('created_at', ascending: false);
    final feedback = await _client
        .from('feedback')
        .select('booking_id')
        .eq('tourist_id', _userId);
    final reviewed = feedback.map((row) => row['booking_id'] as String).toSet();
    return bookings
        .map(VisitOption.fromMap)
        .where((visit) => !reviewed.contains(visit.bookingId))
        .toList();
  }

  Future<List<VisitOption>> fetchUpcomingVisits() async {
    final rows = await _client
        .from('bookings')
        .select(_visitSelection)
        .eq('tourist_id', _userId)
        .eq('status', 'confirmed')
        .order('created_at', ascending: false);
    return rows.map(VisitOption.fromMap).toList();
  }

  Future<void> submitFeedback({
    required String bookingId,
    required int overallRating,
    required int crowdComfort,
    required List<String> tags,
    required String comment,
  }) async {
    await _client.from('feedback').insert({
      'booking_id': bookingId,
      'overall_rating': overallRating,
      'crowd_comfort': crowdComfort,
      'tags': tags,
      'comment': comment.trim(),
    });
  }

  Future<List<FeedbackEntry>> fetchMyFeedback() async {
    final rows = await _client
        .from('feedback')
        .select(
          'id, overall_rating, crowd_comfort, tags, comment, created_at, '
          'booking:bookings(booking_code), attraction:attractions(name)',
        )
        .eq('tourist_id', _userId)
        .order('created_at', ascending: false);
    return rows.map(FeedbackEntry.fromMap).toList();
  }

  Future<void> submitIssue({
    required String category,
    required String location,
    required String description,
    VisitOption? visit,
  }) async {
    await _client.from('issue_reports').insert({
      'attraction_id': visit?.attractionId,
      'booking_id': visit?.bookingId,
      'category': category,
      'location_note': location.trim(),
      'description': description.trim(),
      'priority': category == 'Safety' ? 'urgent' : 'medium',
    });
  }

  Future<List<IssueReport>> fetchMyReports() async {
    final rows = await _client
        .from('issue_reports')
        .select('*, attraction:attractions(name)')
        .eq('tourist_id', _userId)
        .order('created_at', ascending: false);
    return rows.map(IssueReport.fromMap).toList();
  }

  Future<List<IssueReport>> fetchOperatorReports({String? status}) async {
    var query = _client
        .from('issue_reports')
        .select('*, attraction:attractions(name)');
    if (status != null) query = query.eq('status', status);
    final rows = await query.order('created_at', ascending: false);
    return rows.map(IssueReport.fromMap).toList();
  }

  Future<void> resolveReport(String reportId, String note) async {
    await _client.rpc(
      'resolve_issue_report',
      params: {'target_report_id': reportId, 'note': note.trim()},
    );
  }

  Future<double> checkIn({
    required String bookingId,
    required double latitude,
    required double longitude,
  }) async {
    final result = await _client.rpc(
      'check_in_booking',
      params: {
        'target_booking_id': bookingId,
        'current_latitude': latitude,
        'current_longitude': longitude,
      },
    );
    final map = result is List ? (result.first as Map) : result as Map;
    return (map['distance_m'] as num).toDouble();
  }

  Future<CrowdSnapshot?> fetchCrowdSnapshot() async {
    final profile = await _client
        .from('profiles')
        .select('role')
        .eq('id', _userId)
        .single();
    var attractionQuery = _client
        .from('attractions')
        .select('id, name, maximum_capacity');
    if (profile['role'] != 'administrator') {
      final memberships = await _client
          .from('organization_members')
          .select('organization_id')
          .eq('user_id', _userId)
          .eq('is_active', true);
      final organizationIds = memberships
          .map((row) => row['organization_id'] as String)
          .toList();
      if (organizationIds.isEmpty) return null;
      attractionQuery = attractionQuery.inFilter(
        'organization_id',
        organizationIds,
      );
    }
    final attractions = await attractionQuery.order('name').limit(1);
    if (attractions.isEmpty) return null;
    final attraction = attractions.first;
    final checkIns = await _client
        .from('attraction_check_ins')
        .select('checked_in_at, booking:bookings(visitor_count)')
        .eq('attraction_id', attraction['id'] as String)
        .filter('checked_out_at', 'is', null);
    final cutoff = DateTime.now().subtract(const Duration(minutes: 15));
    var current = 0;
    var recent = 0;
    for (final row in checkIns) {
      final visitors = ((row['booking'] as Map)['visitor_count'] as int);
      current += visitors;
      if (DateTime.parse(row['checked_in_at'] as String).isAfter(cutoff)) {
        recent += visitors;
      }
    }
    return CrowdSnapshot(
      attractionName: attraction['name'] as String,
      currentVisitors: current,
      maximumCapacity: attraction['maximum_capacity'] as int,
      recentArrivals: recent,
    );
  }

  @override
  Future<StaffBookingVerification> verifyStaffBooking(
    String bookingCodeOrToken,
  ) async {
    final result = await _client.rpc(
      'verify_staff_booking',
      params: {'lookup_value': bookingCodeOrToken.trim()},
    );
    return StaffBookingVerification.fromMap(_rpcMap(result));
  }

  @override
  Future<StaffBookingVerification> confirmStaffCheckIn(String bookingId) async {
    final result = await _client.rpc(
      'confirm_staff_check_in',
      params: {'target_booking_id': bookingId},
    );
    return StaffBookingVerification.fromMap(_rpcMap(result));
  }
}

Map<String, dynamic> _rpcMap(Object? result) {
  final value = result is List && result.isNotEmpty ? result.first : result;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  throw const FormatException('The check-in service returned invalid data.');
}
