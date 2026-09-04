import 'package:cd_project/models/engagement_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('VisitOption parses the shared booking relationship shape', () {
    final visit = VisitOption.fromMap({
      'id': 'booking-1',
      'booking_code': 'TF-ABC',
      'slot': {
        'starts_at': '2026-09-03T08:00:00Z',
        'attraction': {'id': 'attraction-1', 'name': 'National Museum'},
      },
    });

    expect(visit.bookingId, 'booking-1');
    expect(visit.bookingCode, 'TF-ABC');
    expect(visit.attractionName, 'National Museum');
  });

  test('FeedbackEntry parses ratings, tags, and joined labels', () {
    final feedback = FeedbackEntry.fromMap({
      'id': 'feedback-1',
      'overall_rating': 5,
      'crowd_comfort': 4,
      'tags': ['Clean', 'Friendly staff'],
      'comment': 'Excellent visit.',
      'created_at': '2026-09-03T08:00:00Z',
      'booking': {'booking_code': 'TF-ABC'},
      'attraction': {'name': 'National Museum'},
    });

    expect(feedback.overallRating, 5);
    expect(feedback.tags, contains('Clean'));
    expect(feedback.bookingCode, 'TF-ABC');
  });

  test('CrowdSnapshot clamps available capacity and calculates occupancy', () {
    const snapshot = CrowdSnapshot(
      attractionName: 'National Museum',
      currentVisitors: 12,
      maximumCapacity: 20,
      recentArrivals: 3,
    );

    expect(snapshot.availableCapacity, 8);
    expect(snapshot.occupancy, 0.6);
  });

  test('StaffBookingVerification parses every service status', () {
    const wireStatuses = {
      'valid': StaffBookingStatus.valid,
      'invalid': StaffBookingStatus.invalid,
      'already_used': StaffBookingStatus.alreadyUsed,
      'wrong_attraction': StaffBookingStatus.wrongAttraction,
      'wrong_slot': StaffBookingStatus.wrongSlot,
      'checked_in': StaffBookingStatus.checkedIn,
    };

    for (final entry in wireStatuses.entries) {
      final result = StaffBookingVerification.fromMap({
        'status': entry.key,
        'booking_id': 'booking-1',
        'booking_code': 'TF-ABC',
        'visitor_name': 'Alyssa Loh',
        'visitor_count': 2,
        'attraction_name': 'National Museum',
        'starts_at': '2026-09-04T08:00:00Z',
        'ends_at': '2026-09-04T09:00:00Z',
        'current_visitor_count': 12,
      });

      expect(result.status, entry.value);
      expect(result.bookingCode, 'TF-ABC');
      expect(result.visitorCount, 2);
      expect(result.currentVisitorCount, 12);
    }
  });

  test('only a valid staff verification can be confirmed', () {
    final valid = StaffBookingVerification.fromMap(const {'status': 'valid'});
    final used = StaffBookingVerification.fromMap(const {
      'status': 'already_used',
    });

    expect(valid.canCheckIn, isTrue);
    expect(used.canCheckIn, isFalse);
  });
}
