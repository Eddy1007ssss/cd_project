import 'dart:convert';
import 'dart:io';
import '../models/module3_models.dart';

/// Driving routes retain confirmed appointment order. Durations exclude live
/// traffic and include a 15-minute buffer in each ItineraryLeg.
class ItineraryRoutingService {
  Future<ItineraryPlan> calculate(ItineraryPlan plan) async {
    if (plan.bookings.length < 2) return plan;
    final days = <List<TourBooking>>[];
    for (final booking in plan.bookings) {
      if (days.isEmpty || !ItineraryPlan.sameDay(
          days.last.first.slot.startsAt, booking.slot.startsAt)) {
        days.add(<TourBooking>[]);
      }
      days.last.add(booking);
    }
    if (days.length > 1) {
      final legs = <ItineraryLeg>[];
      for (final day in days) {
        if (legs.isNotEmpty || day != days.first) {
          legs.add(const ItineraryLeg(distanceKm: 0, travelMinutes: 0));
        }
        final routed = await calculate(ItineraryPlan.build(day));
        legs.addAll(routed.legs);
      }
      return plan.withRoadLegs(legs);
    }
    final coordinates = plan.bookings.map((booking) {
      final slot = booking.slot;
      if (slot.latitude == null || slot.longitude == null) {
        throw const FormatException('An attraction has no map coordinates.');
      }
      return '${slot.longitude},${slot.latitude}';
    }).join(';');
    const host = String.fromEnvironment('TOURFLOW_ROUTING_URL',
        defaultValue: 'https://router.project-osrm.org');
    final uri = Uri.parse('${host.replaceAll(RegExp(r'/+$'), '')}'
        '/route/v1/driving/$coordinates').replace(queryParameters: {
      'overview': 'false', 'steps': 'false',
    });
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 12));
      final response = await request.close().timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) throw const HttpException('Routing unavailable');
      final body = await response.transform(utf8.decoder).join()
          .timeout(const Duration(seconds: 12));
      return plan.withRoadLegs(parseLegs(jsonDecode(body), plan.bookings.length - 1));
    } finally {
      client.close(force: true);
    }
  }

  static List<ItineraryLeg> parseLegs(Object? data, int expectedCount) {
    if (data is! Map || data['code'] != 'Ok') {
      throw const FormatException('No driving route was found.');
    }
    final routes = data['routes'];
    if (routes is! List || routes.isEmpty || routes.first is! Map) {
      throw const FormatException('The routing response is incomplete.');
    }
    final legs = (routes.first as Map)['legs'];
    if (legs is! List || legs.length != expectedCount) {
      throw const FormatException('The route is missing a journey segment.');
    }
    return legs.map((row) {
      final distance = row is Map ? row['distance'] : null;
      final duration = row is Map ? row['duration'] : null;
      if (distance is! num || duration is! num || !distance.isFinite ||
          !duration.isFinite || distance < 0 || duration < 0) {
        throw const FormatException('Invalid travel distance or duration.');
      }
      return ItineraryLeg(distanceKm: distance / 1000,
          travelMinutes: (duration / 60).ceil() + 15);
    }).toList();
  }
}
