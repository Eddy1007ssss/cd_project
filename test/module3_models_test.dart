import 'package:cd_project/models/module3_models.dart';
import 'package:cd_project/repositories/module3_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AttractionSlot', () {
    test('calculates remaining capacity and blocks a full slot', () {
      final slot = _slot(
        id: 'full',
        startHour: 9,
        endHour: 10,
        maximum: 20,
        reserved: 20,
        status: 'full',
      );

      expect(slot.remainingCapacity, 0);
      expect(slot.isBookable, isFalse);
    });
  });

  group('ItineraryPlan', () {
    test('sorts visits and detects insufficient travel time', () {
      final later = _booking(
        'later',
        _slot(id: 'b', startHour: 10, endHour: 11, latitude: 3.30),
      );
      final earlier = _booking(
        'earlier',
        _slot(id: 'a', startHour: 9, endHour: 9, endMinute: 50, latitude: 3.10),
      );

      final plan = ItineraryPlan.build([later, earlier]);

      expect(plan.bookings.first.id, 'earlier');
      expect(plan.hasConflict, isTrue);
      expect(plan.legs.single.travelMinutes, greaterThan(15));
    });

    test('marks a suitably spaced itinerary conflict-free', () {
      final first = _booking(
        'first',
        _slot(id: 'a', startHour: 9, endHour: 10),
      );
      final second = _booking(
        'second',
        _slot(id: 'b', startHour: 12, endHour: 13),
      );

      final plan = ItineraryPlan.build([first, second]);

      expect(plan.hasConflict, isFalse);
      expect(plan.legs.single.travelMinutes, greaterThanOrEqualTo(15));
    });
  });

  test('maps backend booking conflicts to a useful tourist message', () {
    expect(
      bookingErrorMessage(Exception('INSUFFICIENT_TRAVEL_TIME')),
      contains('travel time'),
    );
    expect(
      bookingErrorMessage(Exception('INSUFFICIENT_CAPACITY')),
      contains('remaining spaces'),
    );
  });
}

AttractionSlot _slot({
  required String id,
  required int startHour,
  required int endHour,
  int startMinute = 0,
  int endMinute = 0,
  int maximum = 30,
  int reserved = 0,
  String status = 'open',
  double latitude = 3.15,
}) => AttractionSlot(
  id: id,
  attractionId: id,
  attractionName: 'Demo $id',
  category: 'Demo',
  locationName: 'Kuala Lumpur',
  startsAt: DateTime(2030, 1, 1, startHour, startMinute),
  endsAt: DateTime(2030, 1, 1, endHour, endMinute),
  maximumCapacity: maximum,
  reservedCapacity: reserved,
  status: status,
  latitude: latitude,
  longitude: 101.69,
);

TourBooking _booking(String id, AttractionSlot slot) => TourBooking(
  id: id,
  bookingCode: 'TF-$id',
  qrToken: id,
  visitorCount: 1,
  status: BookingStatus.confirmed,
  slot: slot,
  createdAt: DateTime(2029),
);
