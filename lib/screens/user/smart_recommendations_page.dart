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

  // Initially show only 10 recommendations.
  int _visibleCount = 10;

  @override
  void initState() {
    super.initState();
    _results = _load();
  }

  // ============================================================
  // LOAD RECOMMENDATIONS
  // ============================================================

  Future<List<RecommendationResult>> _load() async {
    final location = await LocationService().currentLocation();

    return _service.getRecommendations(
      origin: location,
    );
  }

  // ============================================================
  // RELOAD RECOMMENDATIONS
  // ============================================================

  void _reload() {
    setState(() {
      // Reset back to first 10 whenever recommendations reload.
      _visibleCount = 10;

      _results = _load();
    });
  }

  // ============================================================
  // OPEN PREFERENCE PAGE
  // ============================================================

  Future<void> _openPreferences() async {
    await Navigator.pushNamed(
      context,
      DiscoveryPreferencesPage.routeName,
    );

    if (mounted) {
      _reload();
    }
  }

  // ============================================================
  // SHOW MORE
  // ============================================================

  void _showMore(int totalResults) {
    setState(() {
      final nextCount = _visibleCount + 10;

      if (nextCount > totalResults) {
        _visibleCount = totalResults;
      } else {
        _visibleCount = nextCount;
      }
    });
  }

  // ============================================================
  // BUILD PAGE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Smart Recommendations',
        ),
        actions: [
          IconButton(
            tooltip: 'Edit preferences',
            onPressed: _openPreferences,
            icon: const Icon(
              Icons.tune,
            ),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          _reload();

          await _results;
        },

        child: FutureBuilder<List<RecommendationResult>>(
          future: _results,

          builder: (context, snapshot) {
            // ==================================================
            // LOADING
            // ==================================================

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            // ==================================================
            // ERROR
            // ==================================================

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 50),

                  const Icon(
                    Icons.person_off_outlined,
                    size: 54,
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Recommendations need a signed-in tourist '
                        'and discovery preferences.',
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                    ),
                  ),

                  const SizedBox(height: 20),

                  FilledButton(
                    onPressed: _openPreferences,
                    child: const Text(
                      'Set Preferences',
                    ),
                  ),
                ],
              );
            }

            // ==================================================
            // RESULTS
            // ==================================================

            final results = snapshot.data ?? const [];

            final shownCount = _visibleCount > results.length
                ? results.length
                : _visibleCount;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                // ==================================================
                // INFORMATION CARD
                // ==================================================

                const Card(
                  color: Color(0xFFF2F3FF),
                  child: ListTile(
                    leading: Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF79571E),
                    ),
                    title: Text(
                      'Personalised Recommendations',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      'Attractions are ranked from the highest '
                          'recommendation score to the lowest using '
                          'your preferences and current attraction data.',
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ==================================================
                // NUMBER OF RESULTS
                // ==================================================

                if (results.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.format_list_numbered,
                          size: 18,
                        ),

                        const SizedBox(width: 6),

                        Expanded(
                          child: Text(
                            'Showing $shownCount of ${results.length} '
                                'recommended attractions',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 6),

                // ==================================================
                // NO RESULTS
                // ==================================================

                if (results.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 42,
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            'No suitable approved attractions '
                                'are currently available.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            'Try changing your discovery preferences '
                                'or increasing your travel radius.',
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 16),

                          OutlinedButton.icon(
                            onPressed: _openPreferences,
                            icon: const Icon(
                              Icons.tune,
                            ),
                            label: const Text(
                              'Edit Preferences',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ==================================================
                // RECOMMENDATION CARDS
                // ==================================================

                ...List.generate(
                  shownCount,
                      (index) {
                    final result = results[index];

                    // Ranking starts from #1.
                    final rank = index + 1;

                    return _RecommendationCard(
                      rank: rank,
                      result: result,

                      onDetails: () {
                        Navigator.pushNamed(
                          context,
                          AttractionDetailsPage.routeName,
                          arguments: result.attraction.id,
                        );
                      },

                      onBook: result.recommendedSlot == null
                          ? null
                          : () {
                        Navigator.pushNamed(
                          context,
                          TimeSlotSelectionPage.routeName,
                          arguments: {
                            'attractionId':
                            result.attraction.id,
                            'attractionName':
                            result.attraction.name,
                            'category':
                            result.attraction.category,
                            'locationName':
                            result.attraction.locationName,
                            'preselectedSlotId':
                            result.recommendedSlot!.id,
                          },
                        );
                      },
                    );
                  },
                ),

                // ==================================================
                // SHOW MORE BUTTON
                // ==================================================

                if (shownCount < results.length)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 4,
                      bottom: 12,
                    ),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showMore(
                          results.length,
                        );
                      },
                      icon: const Icon(
                        Icons.expand_more,
                      ),
                      label: Text(
                        'Show More Recommendations '
                            '(${results.length - shownCount} remaining)',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(
                          15,
                        ),
                      ),
                    ),
                  ),

                // ==================================================
                // ALL RESULTS SHOWN
                // ==================================================

                if (results.isNotEmpty &&
                    shownCount == results.length)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 6,
                      bottom: 20,
                    ),
                    child: Center(
                      child: Text(
                        'All ${results.length} recommendations shown',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ================================================================
// RECOMMENDATION CARD
// ================================================================

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.rank,
    required this.result,
    required this.onDetails,
    this.onBook,
  });

  final int rank;

  final RecommendationResult result;

  final VoidCallback onDetails;

  final VoidCallback? onBook;

  @override
  Widget build(BuildContext context) {
    final attraction = result.attraction;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(
        bottom: 14,
      ),

      child: Padding(
        padding: const EdgeInsets.all(14),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====================================================
            // RANK + NAME + SCORE
            // ====================================================

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ranking number
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFF2F3FF,
                    ),
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                  ),
                  child: Text(
                    '#$rank',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attraction.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        attraction.category,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Recommendation score
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(
                    0xFFFFD08B,
                  ),
                  child: Text(
                    '${result.percentage}%',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ====================================================
            // BASIC INFORMATION
            // ====================================================

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.payments_outlined,
                  label:
                  'RM${attraction.entrancePriceMyr.toStringAsFixed(0)}',
                ),

                if (attraction.distanceKm != null)
                  _InfoChip(
                    icon: Icons.location_on_outlined,
                    label:
                    '${attraction.distanceKm!.toStringAsFixed(1)} km',
                  ),

                _InfoChip(
                  icon: Icons.groups_outlined,
                  label:
                  '${attraction.crowdLevel} live crowd',
                ),

                _InfoChip(
                  icon: Icons.place_outlined,
                  label: attraction.attractionType,
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ====================================================
            // TOP REASONS
            // ====================================================

            const Text(
              'Top reasons',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 7),

            ...result.reasons.take(3).map(
                  (reason) {
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: 5,
                  ),
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
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // ====================================================
            // WHY RECOMMENDED BUTTON
            // ====================================================

            TextButton.icon(
              onPressed: () {
                _showRecommendationReasons(
                  context,
                  result,
                  rank,
                );
              },
              icon: const Icon(
                Icons.lightbulb_outline,
              ),
              label: const Text(
                'Why Recommended?',
              ),
            ),

            // ====================================================
            // SLOT INFORMATION
            // ====================================================

            if (result.recommendedSlot != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(
                  top: 4,
                ),
                padding: const EdgeInsets.all(
                  10,
                ),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFFFF7EB,
                  ),
                  borderRadius: BorderRadius.circular(
                    8,
                  ),
                ),

                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 18,
                      color: Color(
                        0xFF79571E,
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        'Suggested slot: '
                            '${_clock(result.recommendedSlot!.startsAt)}'
                            ' • '
                            '${result.recommendedSlot!.remainingCapacity} '
                            'spaces available',
                        style: const TextStyle(
                          color: Color(
                            0xFF79571E,
                          ),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // ====================================================
            // ACTION BUTTONS
            // ====================================================

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDetails,
                    icon: const Icon(
                      Icons.info_outline,
                    ),
                    label: const Text(
                      'Details',
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: FilledButton.icon(
                    onPressed: onBook,
                    icon: const Icon(
                      Icons.calendar_month,
                    ),
                    label: const Text(
                      'View Slot',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// INFORMATION CHIP
// ================================================================

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
          ),

          const SizedBox(width: 4),

          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// WHY RECOMMENDED BOTTOM SHEET
// ================================================================

void _showRecommendationReasons(
    BuildContext context,
    RecommendationResult result,
    int rank,
    ) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,

    builder: (context) {
      return SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              4,
              20,
              28,
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================================================
                // TITLE
                // ==================================================

                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Color(
                        0xFF79571E,
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        'Why ${result.attraction.name}?',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ==================================================
                // RANK
                // ==================================================

                Text(
                  'Ranked #$rank',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                // ==================================================
                // SCORE
                // ==================================================

                Text(
                  '${result.percentage}% recommendation match',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(
                      0xFF79571E,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Recommendation reasons',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 12),

                // ==================================================
                // ALL REASONS
                // ==================================================

                ...result.reasons.map(
                      (reason) {
                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: 12,
                      ),

                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              reason,
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 10),

                // ==================================================
                // CLOSE
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                      );
                    },
                    child: const Text(
                      'Close',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// ================================================================
// FORMAT TIME
// ================================================================

String _clock(DateTime value) {
  final hour = value.hour.toString().padLeft(
    2,
    '0',
  );

  final minute = value.minute.toString().padLeft(
    2,
    '0',
  );

  return '$hour:$minute';
}
