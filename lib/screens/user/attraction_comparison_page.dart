import 'package:flutter/material.dart';

import '../../models/attraction.dart';
import '../../widgets/navigation/user_bottom_navigation_bar.dart';
import 'attraction_details_page.dart';

class AttractionComparisonPage extends StatelessWidget {
  const AttractionComparisonPage({super.key});
  static const routeName = '/attraction-comparison';

  @override
  Widget build(BuildContext context) {
    final value = ModalRoute.of(context)?.settings.arguments;
    final attractions = value is List<Attraction>
        ? value
        : const <Attraction>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Compare Attractions')),
      body: attractions.length < 2
          ? const Center(
              child: Text('Select two or three attractions from Discover.'),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: attractions
                    .map(
                      (attraction) => Container(
                        width: 245,
                        margin: const EdgeInsets.only(right: 12),
                        child: Card(
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  attraction.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(attraction.category),
                                const Divider(),
                                _CompareRow(
                                  'Price',
                                  attraction.entrancePriceMyr == 0
                                      ? 'Free'
                                      : 'RM ${attraction.entrancePriceMyr.toStringAsFixed(2)}',
                                ),
                                _CompareRow(
                                  'Distance',
                                  attraction.distanceKm == null
                                      ? 'Unavailable'
                                      : '${attraction.distanceKm!.toStringAsFixed(1)} km',
                                ),
                                _CompareRow(
                                  'Crowd',
                                  '${attraction.estimatedCrowdLevel} estimate',
                                ),
                                _CompareRow('Rating', 'No ratings yet'),
                                _CompareRow(
                                  'Slots',
                                  '${attraction.availableSlots.length} available',
                                ),
                                _CompareRow(
                                  'Hours today',
                                  attraction.isOpenAt(DateTime.now())
                                      ? 'Open now'
                                      : 'Closed now',
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Facilities',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  attraction.facilities.isEmpty
                                      ? 'None listed'
                                      : attraction.facilities.join(', '),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: () => Navigator.pushNamed(
                                      context,
                                      AttractionDetailsPage.routeName,
                                      arguments: attraction.id,
                                    ),
                                    child: const Text('View details'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
      bottomNavigationBar: const UserBottomNavigationBar(selectedIndex: 1),
    );
  }
}

class _CompareRow extends StatelessWidget {
  const _CompareRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 75, child: Text(label)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
