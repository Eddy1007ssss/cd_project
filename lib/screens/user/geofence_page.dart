import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/engagement_models.dart';
import '../../repositories/engagement_repository.dart';
import '../../widgets/tourflow_widgets.dart';

class GeofencePage extends StatefulWidget {
  const GeofencePage({super.key});
  static const routeName = '/geofence';
  @override
  State<GeofencePage> createState() => _GeofencePageState();
}

class _GeofencePageState extends State<GeofencePage> {
  final _repository = EngagementRepository();
  late Future<List<VisitOption>> _visits;
  bool _checkingIn = false;
  double? _distance;

  @override
  void initState() {
    super.initState();
    _visits = _repository.fetchUpcomingVisits();
  }

  @override
  Widget build(BuildContext context) => TourFlowPage(
    title: 'Geofence Check-in',
    role: 'TOURIST',
    selectedNavigationIndex: 2,
    child: FutureBuilder<List<VisitOption>>(
      future: _visits,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ModuleCard(child: Text(snapshot.error.toString()));
        }
        final visits = snapshot.data ?? const [];
        if (visits.isEmpty) {
          return const ModuleCard(
            child: Text('No confirmed bookings are available for check-in.'),
          );
        }
        final visit = visits.first;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ModuleCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    visit.attractionName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text('Booking ${visit.bookingCode}'),
                  const Text(
                    'Your device location is verified securely by Supabase.',
                  ),
                ],
              ),
            ),
            if (_distance != null) ...[
              const SizedBox(height: 12),
              ModuleCard(
                child: Text(
                  'Checked in successfully · ${_distance!.toStringAsFixed(0)} metres from the attraction.',
                  style: const TextStyle(
                    color: TourFlowColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _checkingIn ? null : () => _checkIn(visit),
              icon: const Icon(Icons.my_location),
              label: Text(
                _checkingIn
                    ? 'Checking location…'
                    : 'Verify location and check in',
              ),
            ),
          ],
        );
      },
    ),
  );

  Future<void> _checkIn(VisitOption visit) async {
    setState(() => _checkingIn = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is required for geofence check-in.',
        );
      }
      final position = await Geolocator.getCurrentPosition();
      final distance = await _repository.checkIn(
        bookingId: visit.bookingId,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (mounted) setState(() => _distance = distance);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_checkInMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _checkingIn = false);
    }
  }
}

String _checkInMessage(Object error) {
  final value = error.toString();
  if (value.contains('OUTSIDE_GEOFENCE')) {
    return 'You are outside the attraction check-in area.';
  }
  if (value.contains('CHECK_IN_TIME_INVALID')) {
    return 'Check-in opens two hours before your visit.';
  }
  return value.replaceFirst('Exception: ', '');
}
