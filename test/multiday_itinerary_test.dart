import 'package:cd_project/models/module3_models.dart';
import 'package:cd_project/models/published_itinerary.dart';
import 'package:cd_project/services/itinerary_routing_service.dart';
import 'package:flutter_test/flutter_test.dart';

TourBooking visit(String id, int day, int start, int end) => TourBooking(
  id: id, bookingCode: id, qrToken: id, visitorCount: 1,
  status: BookingStatus.confirmed, createdAt: DateTime(2030),
  slot: AttractionSlot(
    id: id, attractionId: id, attractionName: id,
    category: 'Heritage', locationName: 'Malaysia',
    startsAt: DateTime(2030, 1, day, start),
    endsAt: DateTime(2030, 1, day, end),
    maximumCapacity: 10, reservedCapacity: 1, status: 'open',
  ),
);

void main() {
  test('multi-day visits remain chronological and overnight legs are zero', () {
    final plan = ItineraryPlan.build([visit('b', 2, 9, 10), visit('a', 1, 9, 10)]);
    expect(plan.bookings.first.id, 'a');
    expect(plan.legs.single.travelMinutes, 0);
    expect(plan.legs.single.distanceKm, 0);
    expect(plan.hasConflict, isFalse);
  });

  test('same-day insufficient travel time remains a conflict', () {
    final plan = ItineraryPlan.build([visit('a', 1, 9, 10), visit('b', 1, 10, 11)]);
    expect(plan.legs.single.travelMinutes, 45);
    expect(plan.hasConflict, isTrue);
  });

  test('overlapping visits across midnight still conflict', () {
    final plan = ItineraryPlan.build([visit('a', 1, 23, 26), visit('b', 2, 1, 3)]);
    expect(plan.hasConflict, isTrue);
  });

  test('one stop per day requires no external road requests', () async {
    final plan = await ItineraryRoutingService().calculate(ItineraryPlan.build([
      visit('a', 1, 9, 10), visit('b', 2, 9, 10), visit('c', 3, 9, 10),
    ]));
    expect(plan.legs.length, 2);
    expect(plan.legs.every((leg) => leg.travelMinutes == 0), isTrue);
    expect(plan.hasConflict, isFalse);
  });

  test('public stop retains date without a booking identifier', () {
    final stop = PublishedItineraryStop.fromMap({
      'position': 1, 'visit_date': '2030-01-02',
      'starts_at': '09:00:00', 'ends_at': '10:00:00',
    });
    expect(stop.visitDate, DateTime(2030, 1, 2));
  });
}
