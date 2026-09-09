import 'package:flutter_test/flutter_test.dart';
import 'package:cd_project/models/booking_value.dart';
import 'package:cd_project/models/saved_itinerary.dart';
import 'package:cd_project/models/user_profile.dart';
import 'package:cd_project/services/itinerary_routing_service.dart';
import 'package:cd_project/widgets/navigation/signed_in_identity.dart';

void main() {
  const profile = UserProfile(id: 'user-a', fullName: 'Alyssa Loh',
    preferredLanguage: 'en', role: UserRole.tourist, status: AccountStatus.active);
  test('sidebar uses the profile belonging to the current session', () {
    final identity = SidebarIdentity.resolve(profile, 'user-a', 'alyssa@example.com');
    expect(identity.name, 'Alyssa Loh');
    expect(identity.email, 'alyssa@example.com');
  });
  test('logout and account switching never display another cached identity', () {
    expect(SidebarIdentity.resolve(profile, null, null).name, 'Guest');
    final identity = SidebarIdentity.resolve(profile, 'user-b', 'b@example.com');
    expect(identity.name, 'Signed-in user');
    expect(identity.email, 'b@example.com');
    expect(identity.avatarUrl, isNull);
  });
  test('recorded booking price survives later attraction price changes', () {
    final value = BookingValue.fromMap({'unit_price_myr': 20,
      'slot': {'attraction': {'entrance_price_myr': 80}}});
    expect(value.unitPrice, 20);
    expect(value.estimated, isFalse);
  });
  test('historical unknown prices are marked estimated and free bookings stay zero', () {
    expect(BookingValue.fromMap({'slot': {'attraction': {'entrance_price_myr': 80}}}).estimated, isTrue);
    expect(BookingValue.fromMap({'unit_price_myr': 0,
      'slot': {'attraction': {'entrance_price_myr': 80}}}).unitPrice, 0);
  });
  test('driving duration converts seconds and adds the buffer exactly once', () {
    final legs = ItineraryRoutingService.parseLegs({'code': 'Ok', 'routes': [
      {'legs': [{'distance': 2300, 'duration': 601}]}
    ]}, 1);
    expect(legs.single.distanceKm, 2.3);
    expect(legs.single.travelMinutes, 26);
  });
  test('missing and malformed routes cannot be called conflict free', () {
    expect(() => ItineraryRoutingService.parseLegs({'code': 'NoRoute'}, 1), throwsFormatException);
    expect(() => ItineraryRoutingService.parseLegs({'code': 'Ok', 'routes': [
      {'legs': [{'distance': -1, 'duration': 60}]}
    ]}, 1), throwsFormatException);
    expect(() => ItineraryRoutingService.parseLegs({'code': 'Ok', 'routes': [
      {'legs': []}
    ]}, 1), throwsFormatException);
  });
  test('saved itinerary restores explicit item order instead of database order', () {
    final saved = SavedItinerary.fromMap({'id': 'plan', 'title': 'My day',
      'itinerary_date': '2030-01-01', 'itinerary_items': [
        {'booking_id': 'second', 'position': 1}, {'booking_id': 'first', 'position': 0}]});
    expect(saved.bookingIds, ['first', 'second']);
  });
}
