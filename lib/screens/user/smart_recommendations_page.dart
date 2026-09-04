import 'package:flutter/material.dart';

import '../../models/recommendation_result.dart';
import '../../services/attraction_service.dart';
import '../../services/location_service.dart';
import 'attraction_details_page.dart';
import 'discovery_preferences_page.dart';
import 'time_slot_selection_page.dart';

class SmartRecommendationsPage extends StatefulWidget {
  const SmartRecommendationsPage({super.key});
  static const routeName = '/smart-recommendations';
  @override
  State<SmartRecommendationsPage> createState() =>
      _SmartRecommendationsPageState();
}

class _SmartRecommendationsPageState extends State<SmartRecommendationsPage> {
  final _service = AttractionService();
  late Future<List<RecommendationResult>> _results;

  @override
  void initState() {
    super.initState();
    _results = _load();
  }

  Future<List<RecommendationResult>> _load() async => _service
      .getRecommendations(origin: await LocationService().currentLocation());
  void _reload() => setState(() => _results = _load());

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Smart Recommendations'),
      actions: [
        IconButton(
          tooltip: 'Edit preferences',
          onPressed: () async {
            await Navigator.pushNamed(
              context,
              DiscoveryPreferencesPage.routeName,
            );
            _reload();
          },
          icon: const Icon(Icons.tune),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: () async => _reload(),
      child: FutureBuilder<List<RecommendationResult>>(
        future: _results,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Icon(Icons.person_off_outlined, size: 54),
                const SizedBox(height: 12),
                const Text(
                  'Recommendations need a signed-in tourist and Module 2 preferences.',
                  textAlign: TextAlign.center,
                ),
                Text(
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11),
                ),
                FilledButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    DiscoveryPreferencesPage.routeName,
                  ),
                  child: const Text('Set preferences'),
                ),
              ],
            );
          }
          final results = snapshot.data ?? const [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Card(
                color: Color(0xFFF2F3FF),
                child: ListTile(
                  leading: Icon(Icons.auto_awesome, color: Color(0xFF79571E)),
                  title: Text(
                    'Explainable matches',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    'Scores use preferences, distance, slot availability, estimated crowd and completed visits.',
                  ),
                ),
              ),
              if (results.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No suitable approved attractions are currently available.',
                    ),
                  ),
                ),
              ...results
                  .take(8)
                  .map(
                    (result) => _RecommendationCard(
                      result: result,
                      onDetails: () => Navigator.pushNamed(
                        context,
                        AttractionDetailsPage.routeName,
                        arguments: result.attraction.id,
                      ),
                      onBook: result.recommendedSlot == null
                          ? null
                          : () => Navigator.pushNamed(
                              context,
                              TimeSlotSelectionPage.routeName,
                              arguments: {
                                'attractionId': result.attraction.id,
                                'attractionName': result.attraction.name,
                                'category': result.attraction.category,
                                'locationName': result.attraction.locationName,
                                'preselectedSlotId': result.recommendedSlot!.id,
                              },
                            ),
                    ),
                  ),
            ],
          );
        },
      ),
    ),
  );
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.result,
    required this.onDetails,
    this.onBook,
  });
  final RecommendationResult result;
  final VoidCallback onDetails;
  final VoidCallback? onBook;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFFFD08B),
                child: Text('${result.percentage}%'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.attraction.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...result.reasons
              .take(4)
              .map(
                (reason) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          reason,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (result.recommendedSlot != null)
            Text(
              'Suggested: ${_clock(result.recommendedSlot!.startsAt)} · ${result.recommendedSlot!.remainingCapacity} spaces',
              style: const TextStyle(
                color: Color(0xFF79571E),
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton(
                onPressed: onDetails,
                child: const Text('Details'),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: onBook, child: const Text('View slot')),
            ],
          ),
        ],
      ),
    ),
  );
}

String _clock(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
