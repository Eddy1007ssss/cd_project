import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

class LocationPoint {
  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.label,
    this.isFallback = false,
  });

  final double latitude;
  final double longitude;
  final String label;
  final bool isFallback;
}

class BookingLocationAnchor {
  const BookingLocationAnchor({
    required this.attractionId,
    required this.attractionName,
    required this.endsAt,
    required this.location,
  });

  final String attractionId;
  final String attractionName;
  final DateTime endsAt;
  final LocationPoint location;
}

class LocationService {
  static const fallback = LocationPoint(
    latitude: 3.1478,
    longitude: 101.6937,
    label: 'Dataran Merdeka demo origin',
    isFallback: true,
  );

  Future<LocationPoint> currentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return fallback;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return fallback;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      return LocationPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        label: 'Your current location',
      );
    } catch (_) {
      return fallback;
    }
  }

  static double distanceKm({
    required double firstLatitude,
    required double firstLongitude,
    required double secondLatitude,
    required double secondLongitude,
  }) {
    double radians(double value) => value * math.pi / 180;
    final latitudeDelta = radians(secondLatitude - firstLatitude);
    final longitudeDelta = radians(secondLongitude - firstLongitude);
    final value =
        math.pow(math.sin(latitudeDelta / 2), 2) +
        math.cos(radians(firstLatitude)) *
            math.cos(radians(secondLatitude)) *
            math.pow(math.sin(longitudeDelta / 2), 2);
    return 6371 * 2 * math.asin(math.sqrt(value));
  }

  static int estimatedTravelMinutes(double distanceKm) =>
      (distanceKm / 30 * 60).ceil() + 15;
}
