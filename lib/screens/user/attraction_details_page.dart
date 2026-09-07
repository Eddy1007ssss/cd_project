import 'package:flutter/material.dart';

import '../../models/attraction.dart';
import '../../models/recommendation_result.dart';
import '../../services/attraction_service.dart';
import '../../services/location_service.dart';
import 'smart_recommendations_page.dart';
import 'time_slot_selection_page.dart';

class AttractionDetailsPage extends StatefulWidget {
  const AttractionDetailsPage({super.key});

  static const routeName = '/user/attraction-details';

  @override
  State<AttractionDetailsPage> createState() =>
      _AttractionDetailsPageState();
}

class _AttractionDetailsPageState extends State<AttractionDetailsPage> {
  final _service = AttractionService();

  Future<
      ({
      Attraction? attraction,
      List<String> issues,
      List<RecommendationResult> alternatives,
      })>? _details;

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
      _details = _loadDetails(id);
    }
  }

  // ============================================================
  // LOAD ATTRACTION + ALTERNATIVES
  // ============================================================

  Future<
      ({
      Attraction? attraction,
      List<String> issues,
      List<RecommendationResult> alternatives,
      })> _loadDetails(String id) async {
    final origin = await LocationService().currentLocation();

    final attraction = await _service.getAttractionById(
      id,
      origin: origin,
    );

    if (attraction == null) {
      return (
      attraction: null,
      issues: <String>[],
      alternatives: <RecommendationResult>[],
      );
    }

    final alternativeResult =
    await _service.getAlternativeAttractions(
      selectedAttraction: attraction,
      origin: origin,
    );

    return (
    attraction: attraction,
    issues: alternativeResult.issues,
    alternatives: alternativeResult.alternatives,
    );
  }

  // ============================================================
  // BOOKING
  // ============================================================

  void _book(
      Attraction attraction, {
        AttractionSlotPreview? slot,
      }) {
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

  // ============================================================
  // OPEN ALTERNATIVE
  // ============================================================

  void _openAlternative(
      RecommendationResult result,
      ) {
    Navigator.pushNamed(
      context,
      AttractionDetailsPage.routeName,
      arguments: result.attraction.id,
    );
  }

  // ============================================================
  // PAGE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_id == null || _details == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'No attraction selected.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Attraction Details',
        ),
      ),
      body: FutureBuilder<
          ({
          Attraction? attraction,
          List<String> issues,
          List<RecommendationResult> alternatives,
          })>(
        future: _details,
        builder: (context, snapshot) {
          // ======================================================
          // LOADING
          // ======================================================

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ======================================================
          // ERROR
          // ======================================================

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load attraction: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data!;

          final attraction = data.attraction;
          final issues = data.issues;
          final alternatives = data.alternatives;

          if (attraction == null) {
            return const Center(
              child: Text(
                'This attraction is not available to tourists.',
              ),
            );
          }

          final images = <String>[
            if (attraction.coverImageUrl != null)
              attraction.coverImageUrl!,
            ...attraction.images.map(
                  (image) => _service.publicImageUrl(
                image.path,
              ),
            ),
          ];

          return ListView(
            padding: const EdgeInsets.only(
              bottom: 28,
            ),
            children: [
              // ==================================================
              // ATTRACTION IMAGES
              // ==================================================

              if (images.isEmpty)
                Container(
                  height: 220,
                  color: const Color(0xFFFFE2B5),
                  child: const Icon(
                    Icons.place_outlined,
                    size: 70,
                  ),
                )
              else
                SizedBox(
                  height: 230,
                  child: PageView.builder(
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) {
                          return const ColoredBox(
                            color: Color(0xFFFFE2B5),
                            child: Icon(
                              Icons.broken_image_outlined,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

              // ==================================================
              // MAIN CONTENT
              // ==================================================

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    // ============================================
                    // ATTRACTION NAME
                    // ============================================

                    Text(
                      attraction.name,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      '${attraction.category} · '
                          '${attraction.locationName}',
                    ),

                    const SizedBox(height: 10),

                    // ============================================
                    // QUICK INFORMATION
                    // ============================================

                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Chip(
                          avatar: const Icon(
                            Icons.payments_outlined,
                            size: 17,
                          ),
                          label: Text(
                            attraction.entrancePriceMyr == 0
                                ? 'Free entry'
                                : 'RM ${attraction.entrancePriceMyr.toStringAsFixed(2)}',
                          ),
                        ),

                        Chip(
                          avatar: const Icon(
                            Icons.groups_outlined,
                            size: 17,
                          ),
                          label: Text(
                            '${attraction.estimatedCrowdLevel} '
                                'crowd estimate',
                          ),
                        ),

                        Chip(
                          avatar: const Icon(
                            Icons.location_on_outlined,
                            size: 17,
                          ),
                          label: Text(
                            attraction.distanceKm == null
                                ? 'Distance unavailable'
                                : '${attraction.distanceKm!.toStringAsFixed(1)} '
                                'km away',
                          ),
                        ),

                        Chip(
                          avatar: const Icon(
                            Icons.place_outlined,
                            size: 17,
                          ),
                          label: Text(
                            attraction.attractionType,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ============================================
                    // SUITABILITY WARNING
                    // ============================================

                    if (issues.isNotEmpty) ...[
                      _SuitabilityWarning(
                        issues: issues,
                      ),

                      const SizedBox(height: 18),

                      // ==========================================
                      // SUGGESTED ALTERNATIVES
                      // NOW DIRECTLY BELOW WARNING
                      // ==========================================

                      _SuggestedAlternativesSection(
                        alternatives: alternatives,
                        onTap: _openAlternative,
                      ),

                      const SizedBox(height: 22),
                    ],

                    // ============================================
                    // DESCRIPTION
                    // ============================================

                    Text(
                      attraction.description,
                      style: const TextStyle(
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ============================================
                    // ADDRESS
                    // ============================================

                    _Section(
                      title: 'Address',
                      child: Text(
                        attraction.address,
                      ),
                    ),

                    // ============================================
                    // FACILITIES
                    // ============================================

                    _Section(
                      title: 'Facilities',
                      child: attraction.facilities.isEmpty
                          ? const Text(
                        'No facilities listed.',
                      )
                          : Wrap(
                        spacing: 7,
                        runSpacing: 5,
                        children:
                        attraction.facilities
                            .map(
                              (facility) {
                            return Chip(
                              avatar: const Icon(
                                Icons.check,
                                size: 16,
                              ),
                              label: Text(
                                facility,
                              ),
                            );
                          },
                        ).toList(),
                      ),
                    ),

                    // ============================================
                    // OPERATING HOURS
                    // ============================================

                    _Section(
                      title: 'Operating hours',
                      child: _HoursList(
                        hours:
                        attraction.operatingHours,
                      ),
                    ),

                    // ============================================
                    // VISITOR GUIDELINES
                    // ============================================

                    _Section(
                      title: 'Visitor guidelines',
                      child: Text(
                        attraction.visitorGuidelines ??
                            'No additional guidelines.',
                      ),
                    ),

                    // ============================================
                    // RULES
                    // ============================================

                    _Section(
                      title: 'Rules',
                      child: Text(
                        attraction.attractionRules ??
                            'No additional rules.',
                      ),
                    ),

                    // ============================================
                    // AVAILABLE SLOTS TITLE
                    // ============================================

                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Available slots',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                            FontWeight.w800,
                          ),
                        ),

                        TextButton(
                          onPressed: () {
                            _book(attraction);
                          },
                          child: const Text(
                            'See all',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // ============================================
                    // SLOT LIST
                    // ============================================

                    if (attraction.availableSlots.isEmpty)
                      const Card(
                        child: Padding(
                          padding:
                          EdgeInsets.all(14),
                          child: Text(
                            'No future open slots are available.',
                          ),
                        ),
                      )
                    else
                      ...attraction.availableSlots
                          .take(4)
                          .map(
                            (slot) {
                          return Card(
                            color: Colors.white,
                            child: ListTile(
                              leading: const Icon(
                                Icons.schedule,
                              ),
                              title: Text(
                                '${_date(slot.startsAt)} · '
                                    '${_time(slot.startsAt)} – '
                                    '${_time(slot.endsAt)}',
                              ),
                              subtitle: Text(
                                '${slot.remainingCapacity} of '
                                    '${slot.maximumCapacity} spaces remaining · '
                                    '${_crowd(slot)} estimate',
                              ),
                              trailing:
                              TextButton(
                                onPressed: () {
                                  _book(
                                    attraction,
                                    slot: slot,
                                  );
                                },
                                child: const Text(
                                  'Choose',
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 12),

                    // ============================================
                    // CHOOSE VISIT SLOT BUTTON
                    // ============================================

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: attraction
                            .availableSlots.isEmpty
                            ? null
                            : () {
                          _book(attraction);
                        },
                        icon: const Icon(
                          Icons
                              .confirmation_num_outlined,
                        ),
                        label: const Text(
                          'Choose a Visit Slot',
                        ),
                        style:
                        FilledButton.styleFrom(
                          backgroundColor:
                          const Color(
                            0xFF79571E,
                          ),
                          padding:
                          const EdgeInsets.all(
                            15,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ============================================
                    // GENERAL SMART RECOMMENDATIONS
                    // ============================================

                    TextButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          SmartRecommendationsPage
                              .routeName,
                        );
                      },
                      icon: const Icon(
                        Icons.auto_awesome_outlined,
                      ),
                      label: const Text(
                        'View All Smart Recommendations',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ================================================================
// SUITABILITY WARNING
// ================================================================

class _SuitabilityWarning extends StatelessWidget {
  const _SuitabilityWarning({
    required this.issues,
  });

  final List<String> issues;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius:
        BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFCC80),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This attraction may not suit your current preferences',
                  style: TextStyle(
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ...issues.map(
                (issue) {
              return Padding(
                padding:
                const EdgeInsets.only(
                  bottom: 6,
                ),
                child: Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 17,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        issue,
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
        ],
      ),
    );
  }
}

// ================================================================
// SUGGESTED ALTERNATIVES SECTION
// ================================================================

class _SuggestedAlternativesSection
    extends StatelessWidget {
  const _SuggestedAlternativesSection({
    required this.alternatives,
    required this.onTap,
  });

  final List<RecommendationResult>
  alternatives;

  final ValueChanged<RecommendationResult>
  onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.swap_horiz_rounded,
              color: Color(0xFF79571E),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Suggested Alternatives',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        const Text(
          'These attractions are similar but may better match '
              'your current preferences.',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),

        const SizedBox(height: 12),

        if (alternatives.isEmpty)
          const Card(
            color: Color(0xFFFFF7EB),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_outlined,
                    size: 34,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No similar alternative attraction is currently available.',
                    textAlign:
                    TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Try changing your date, budget, distance '
                        'or discovery preferences.',
                    textAlign:
                    TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...List.generate(
            alternatives.length,
                (index) {
              final result =
              alternatives[index];

              return _AlternativeCard(
                rank: index + 1,
                result: result,
                onTap: () {
                  onTap(result);
                },
              );
            },
          ),
      ],
    );
  }
}

// ================================================================
// ALTERNATIVE CARD
// ================================================================

class _AlternativeCard
    extends StatelessWidget {
  const _AlternativeCard({
    required this.rank,
    required this.result,
    required this.onTap,
  });

  final int rank;
  final RecommendationResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final attraction =
        result.attraction;

    return Card(
      color: Colors.white,
      margin:
      const EdgeInsets.only(
        bottom: 12,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(12),
        child: Padding(
          padding:
          const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              // ==================================================
              // RANK + NAME + SCORE
              // ==================================================

              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment:
                    Alignment.center,
                    decoration:
                    BoxDecoration(
                      color: const Color(
                        0xFFF2F3FF,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        10,
                      ),
                    ),
                    child: Text(
                      '#$rank',
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        Text(
                          attraction.name,
                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${attraction.category} · '
                              '${attraction.locationName}',
                          style:
                          const TextStyle(
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  CircleAvatar(
                    backgroundColor:
                    const Color(
                      0xFFFFD08B,
                    ),
                    child: Text(
                      '${result.percentage}%',
                      style:
                      const TextStyle(
                        fontSize: 11,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ==================================================
              // BASIC INFORMATION
              // ==================================================

              Wrap(
                spacing: 7,
                runSpacing: 6,
                children: [
                  _MiniInfo(
                    icon: Icons
                        .payments_outlined,
                    label: attraction
                        .entrancePriceMyr ==
                        0
                        ? 'Free'
                        : 'RM${attraction.entrancePriceMyr.toStringAsFixed(0)}',
                  ),

                  if (attraction.distanceKm !=
                      null)
                    _MiniInfo(
                      icon: Icons
                          .location_on_outlined,
                      label:
                      '${attraction.distanceKm!.toStringAsFixed(1)} km',
                    ),

                  _MiniInfo(
                    icon:
                    Icons.groups_outlined,
                    label:
                    '${attraction.estimatedCrowdLevel} crowd',
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ==================================================
              // REASONS
              // ==================================================

              ...result.reasons.take(3).map(
                    (reason) {
                  return Padding(
                    padding:
                    const EdgeInsets.only(
                      bottom: 4,
                    ),
                    child: Row(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        const Icon(
                          Icons
                              .check_circle_outline,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(
                          width: 6,
                        ),
                        Expanded(
                          child: Text(
                            reason,
                            style:
                            const TextStyle(
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child:
                OutlinedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(
                    Icons.arrow_forward,
                  ),
                  label: const Text(
                    'View Alternative',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// SMALL INFO CHIP
// ================================================================

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius:
        BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// SECTION
// ================================================================

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 18,
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight:
              FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          child,
        ],
      ),
    );
  }
}

// ================================================================
// OPERATING HOURS
// ================================================================

class _HoursList extends StatelessWidget {
  const _HoursList({
    required this.hours,
  });

  final List<AttractionOperatingHours>
  hours;

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
    if (hours.isEmpty) {
      return const Text(
        'Operating hours not provided.',
      );
    }

    return Column(
      children: hours.map(
            (item) {
          return Padding(
            padding:
            const EdgeInsets.only(
              bottom: 4,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    days[item.dayOfWeek],
                  ),
                ),
                Text(
                  item.isClosed
                      ? 'Closed'
                      : '${_short(item.opensAt)} – '
                      '${_short(item.closesAt)}',
                ),
              ],
            ),
          );
        },
      ).toList(),
    );
  }

  String _short(String? value) {
    if (value == null ||
        value.length < 5) {
      return '--:--';
    }

    return value.substring(0, 5);
  }
}

// ================================================================
// HELPERS
// ================================================================

String _date(DateTime value) {
  return '${value.day}/${value.month}/${value.year}';
}

String _time(DateTime value) {
  return '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

String _crowd(
    AttractionSlotPreview slot,
    ) {
  if (slot.occupancyRatio < .4) {
    return 'Low';
  }

  if (slot.occupancyRatio < .7) {
    return 'Moderate';
  }

  if (slot.occupancyRatio < .9) {
    return 'High';
  }

  return 'Critical';
}