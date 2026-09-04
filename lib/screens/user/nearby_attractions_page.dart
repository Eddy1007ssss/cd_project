import 'package:flutter/material.dart';

import '../../models/attraction.dart';
import '../../services/attraction_service.dart';
import '../../services/location_service.dart';
import 'attraction_details_page.dart';

class NearbyAttractionsPage extends StatefulWidget {
  const NearbyAttractionsPage({super.key});
  static const routeName = '/nearby-attractions';
  @override
  State<NearbyAttractionsPage> createState() => _NearbyAttractionsPageState();
}

class _NearbyAttractionsPageState extends State<NearbyAttractionsPage> {
  final _service = AttractionService();
  late Future<(LocationPoint, List<Attraction>, BookingLocationAnchor?)>
  _nearby;
  @override
  void initState() {
    super.initState();
    _nearby = _load();
  }

  Future<(LocationPoint, List<Attraction>, BookingLocationAnchor?)>
  _load() async {
    final anchor = await _service.getUpcomingBookingAnchor();
    final location =
        anchor?.location ?? await LocationService().currentLocation();
    var attractions = await _service.getNearby(location);
    if (anchor != null) {
      attractions = attractions
          .where((attraction) => _service.fitsAfterBooking(attraction, anchor))
          .toList();
    }
    return (location, attractions, anchor);
  }

  void _reload() => setState(() => _nearby = _load());

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Nearby Attractions'),
      actions: [
        IconButton(onPressed: _reload, icon: const Icon(Icons.my_location)),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: () async => _reload(),
      child: FutureBuilder<(LocationPoint, List<Attraction>, BookingLocationAnchor?)>(
        future: _nearby,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ListView(
              children: [
                const SizedBox(height: 140),
                Center(
                  child: Text(
                    'Could not load nearby attractions: ${snapshot.error}',
                  ),
                ),
              ],
            );
          }
          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                height: 170,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F0E4),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.map_rounded,
                        size: 100,
                        color: Color(0xFF8BA17E),
                      ),
                    ),
                    Positioned(
                      top: 38,
                      left: 75,
                      child: Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 36,
                      ),
                    ),
                    Positioned(
                      bottom: 32,
                      right: 80,
                      child: Icon(
                        Icons.location_pin,
                        color: Color(0xFF79571E),
                        size: 36,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                data.$3 == null
                    ? data.$1.label
                    : 'Suggestions after ${data.$3!.attractionName}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              if (data.$3 != null)
                Text(
                  'Starting at ${_clock(data.$3!.endsAt)}. Results have a same-day slot after the estimated journey and 15-minute safety buffer.',
                  style: const TextStyle(fontSize: 11),
                )
              else if (data.$1.isFallback)
                const Text(
                  'Location permission was unavailable, so TourFlow is using its Kuala Lumpur demo origin.',
                  style: TextStyle(fontSize: 11),
                ),
              const SizedBox(height: 12),
              if (data.$2.isEmpty)
                const Card(
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No nearby attraction has a suitable available slot yet.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ...data.$2.map(
                (attraction) => Card(
                  color: Colors.white,
                  child: ListTile(
                    onTap: () => Navigator.pushNamed(
                      context,
                      AttractionDetailsPage.routeName,
                      arguments: attraction.id,
                    ),
                    leading: const CircleAvatar(
                      child: Icon(Icons.place_outlined),
                    ),
                    title: Text(
                      attraction.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '${attraction.distanceKm!.toStringAsFixed(1)} km · about ${LocationService.estimatedTravelMinutes(attraction.distanceKm!)} min including buffer\n${attraction.estimatedCrowdLevel} slot crowd estimate · ${attraction.availableSlots.length} future slots',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );

  String _clock(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour == 0
        ? 12
        : local.hour > 12
        ? local.hour - 12
        : local.hour;
    return '${local.day}/${local.month} $hour:${local.minute.toString().padLeft(2, '0')} ${local.hour >= 12 ? 'PM' : 'AM'}';
  }
}
