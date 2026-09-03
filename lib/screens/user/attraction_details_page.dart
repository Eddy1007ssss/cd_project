import 'package:flutter/material.dart';

import '../../models/attraction.dart';
import '../../services/attraction_service.dart';
import '../../services/location_service.dart';
import '../../widgets/navigation/user_bottom_navigation_bar.dart';
import 'smart_recommendations_page.dart';
import 'time_slot_selection_page.dart';

class AttractionDetailsPage extends StatefulWidget {
  const AttractionDetailsPage({super.key});
  static const routeName = '/user/attraction-details';

  @override
  State<AttractionDetailsPage> createState() => _AttractionDetailsPageState();
}

class _AttractionDetailsPageState extends State<AttractionDetailsPage> {
  final _service = AttractionService();
  Future<Attraction?>? _attraction;
  String? _id;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final value = ModalRoute.of(context)?.settings.arguments;
    final id = value is String
        ? value
        : value is Map
        ? value['attractionId'] as String?
        : null;
    if (id != null && id != _id) {
      _id = id;
      _attraction = LocationService().currentLocation().then(
        (origin) => _service.getAttractionById(id, origin: origin),
      );
    }
  }

  void _book(Attraction attraction, {AttractionSlotPreview? slot}) {
    Navigator.pushNamed(
      context,
      TimeSlotSelectionPage.routeName,
      arguments: {
        'attractionId': attraction.id,
        'attractionName': attraction.name,
        'category': attraction.category,
        'locationName': attraction.locationName,
        if (slot != null) 'preselectedSlotId': slot.id,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_id == null) {
      return const Scaffold(
        body: Center(child: Text('No attraction selected.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Attraction Details')),
      body: FutureBuilder<Attraction?>(
        future: _attraction,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load attraction: ${snapshot.error}'),
            );
          }
          final attraction = snapshot.data;
          if (attraction == null) {
            return const Center(
              child: Text('This attraction is not available to tourists.'),
            );
          }
          final images = <String>[
            if (attraction.coverImageUrl != null) attraction.coverImageUrl!,
            ...attraction.images.map(
              (image) => _service.publicImageUrl(image.path),
            ),
          ];
          return ListView(
            padding: const EdgeInsets.only(bottom: 28),
            children: [
              if (images.isEmpty)
                Container(
                  height: 220,
                  color: const Color(0xFFFFE2B5),
                  child: const Icon(Icons.place_outlined, size: 70),
                )
              else
                SizedBox(
                  height: 230,
                  child: PageView.builder(
                    itemCount: images.length,
                    itemBuilder: (_, index) => Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: Color(0xFFFFE2B5),
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attraction.name,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text('${attraction.category} · ${attraction.locationName}'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Chip(
                          label: Text(
                            attraction.entrancePriceMyr == 0
                                ? 'Free entry'
                                : 'RM ${attraction.entrancePriceMyr.toStringAsFixed(2)}',
                          ),
                        ),
                        Chip(
                          label: Text(
                            '${attraction.estimatedCrowdLevel} crowd estimate',
                          ),
                        ),
                        Chip(
                          label: Text(
                            attraction.distanceKm == null
                                ? 'Distance unavailable'
                                : '${attraction.distanceKm!.toStringAsFixed(1)} km away',
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'No ratings yet · Rating data will be supplied by Module 5.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      attraction.description,
                      style: const TextStyle(height: 1.45),
                    ),
                    const SizedBox(height: 18),
                    _Section(title: 'Address', child: Text(attraction.address)),
                    _Section(
                      title: 'Facilities',
                      child: attraction.facilities.isEmpty
                          ? const Text('No facilities listed.')
                          : Wrap(
                              spacing: 7,
                              children: attraction.facilities
                                  .map(
                                    (facility) => Chip(
                                      avatar: const Icon(Icons.check, size: 16),
                                      label: Text(facility),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                    _Section(
                      title: 'Operating hours',
                      child: _HoursList(hours: attraction.operatingHours),
                    ),
                    _Section(
                      title: 'Visitor guidelines',
                      child: Text(
                        attraction.visitorGuidelines ??
                            'No additional guidelines.',
                      ),
                    ),
                    _Section(
                      title: 'Rules',
                      child: Text(
                        attraction.attractionRules ?? 'No additional rules.',
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Available slots',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _book(attraction),
                          child: const Text('See all'),
                        ),
                      ],
                    ),
                    if (attraction.availableSlots.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(14),
                          child: Text('No future open slots are available.'),
                        ),
                      )
                    else
                      ...attraction.availableSlots
                          .take(4)
                          .map(
                            (slot) => Card(
                              color: Colors.white,
                              child: ListTile(
                                leading: const Icon(Icons.schedule),
                                title: Text(
                                  '${_date(slot.startsAt)} · ${_time(slot.startsAt)} – ${_time(slot.endsAt)}',
                                ),
                                subtitle: Text(
                                  '${slot.remainingCapacity} of ${slot.maximumCapacity} spaces remaining · ${_crowd(slot)} estimate',
                                ),
                                trailing: TextButton(
                                  onPressed: () =>
                                      _book(attraction, slot: slot),
                                  child: const Text('Choose'),
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: attraction.availableSlots.isEmpty
                            ? null
                            : () => _book(attraction),
                        icon: const Icon(Icons.confirmation_num_outlined),
                        label: const Text('Choose a Visit Slot'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF79571E),
                          padding: const EdgeInsets.all(15),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        SmartRecommendationsPage.routeName,
                      ),
                      icon: const Icon(Icons.auto_awesome_outlined),
                      label: const Text('View quieter alternatives'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const UserBottomNavigationBar(selectedIndex: 1),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 7),
        child,
      ],
    ),
  );
}

class _HoursList extends StatelessWidget {
  const _HoursList({required this.hours});
  final List<AttractionOperatingHours> hours;
  static const days = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];
  @override
  Widget build(BuildContext context) {
    if (hours.isEmpty) return const Text('Operating hours not provided.');
    return Column(
      children: hours
          .map(
            (item) => Row(
              children: [
                SizedBox(width: 100, child: Text(days[item.dayOfWeek])),
                Text(
                  item.isClosed
                      ? 'Closed'
                      : '${_short(item.opensAt)} – ${_short(item.closesAt)}',
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  String _short(String? value) =>
      value == null ? '--:--' : value.substring(0, 5);
}

String _date(DateTime value) => '${value.day}/${value.month}/${value.year}';
String _time(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
String _crowd(AttractionSlotPreview slot) => slot.occupancyRatio < .4
    ? 'Low'
    : slot.occupancyRatio < .7
    ? 'Moderate'
    : slot.occupancyRatio < .9
    ? 'High'
    : 'Critical';
