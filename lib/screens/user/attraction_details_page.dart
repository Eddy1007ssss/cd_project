import 'package:flutter/material.dart';

import '../../models/attraction.dart';
import '../../models/recommendation_result.dart';
import '../../services/attraction_service.dart';
import '../../services/location_service.dart';
import '../../widgets/attraction_image.dart';
import 'smart_recommendations_page.dart';
import 'time_slot_selection_page.dart';

class AttractionDetailsPage extends StatefulWidget {
  const AttractionDetailsPage({super.key});

  static const routeName = '/user/attraction-details';

  @override
  State<AttractionDetailsPage> createState() =>
      _AttractionDetailsPageState();
}

class _AttractionDetailsPageState
    extends State<AttractionDetailsPage> {
  final _service = AttractionService();

  final _transportService =
  const _TransportSuggestionService();

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

    final value =
        ModalRoute.of(context)?.settings.arguments;

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

  // ==============================================================
  // LOAD DETAILS
  // ==============================================================

  Future<
      ({
      Attraction? attraction,
      List<String> issues,
      List<RecommendationResult> alternatives,
      })> _loadDetails(String id) async {
    final origin =
    await LocationService().currentLocation();

    final attraction =
    await _service.getAttractionById(
      id,
      origin: origin,
    );

    if (attraction == null) {
      return (
      attraction: null,
      issues: <String>[],
      alternatives:
      <RecommendationResult>[],
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
    alternatives:
    alternativeResult.alternatives,
    );
  }

  // ==============================================================
  // BOOKING
  // ==============================================================

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
        'locationName':
        attraction.locationName,
        if (slot != null)
          'preselectedSlotId': slot.id,
      },
    );
  }

  // ==============================================================
  // OPEN ALTERNATIVE
  // ==============================================================

  void _openAlternative(
      RecommendationResult result,
      ) {
    Navigator.pushNamed(
      context,
      AttractionDetailsPage.routeName,
      arguments: result.attraction.id,
    );
  }

  // ==============================================================
  // PAGE
  // ==============================================================

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
          List<RecommendationResult>
          alternatives,
          })>(
        future: _details,
        builder: (context, snapshot) {
          // ========================================================
          // LOADING
          // ========================================================

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
              CircularProgressIndicator(),
            );
          }

          // ========================================================
          // ERROR
          // ========================================================

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                const EdgeInsets.all(24),
                child: Text(
                  'Could not load attraction: '
                      '${snapshot.error}',
                  textAlign:
                  TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data!;

          final attraction =
              data.attraction;

          final issues = data.issues;

          final alternatives =
              data.alternatives;

          if (attraction == null) {
            return const Center(
              child: Text(
                'This attraction is not available to tourists.',
              ),
            );
          }

          final images = <String>[
            if (attraction.coverImageUrl !=
                null)
              attraction.coverImageUrl!,
            ...attraction.images.map(
                  (image) =>
                  _service.publicImageUrl(
                    image.path,
                  ),
            ),
          ];

          final quietest = attraction.quietestAvailableSlot;

          final transportSuggestions =
          _transportService
              .suggestionsForDistance(
            attraction.distanceKm,
          );

          return ListView(
            padding:
            const EdgeInsets.only(
              bottom: 28,
            ),
            children: [
              // ====================================================
              // ATTRACTION IMAGE
              // ====================================================

              if (images.isEmpty)
                AttractionImageView(
                  attraction: attraction,
                  width: double.infinity,
                  height: 220,
                )
              else
                SizedBox(
                  height: 230,
                  child: PageView.builder(
                    itemCount: images.length,
                    itemBuilder:
                        (context, index) {
                      return Image.network(
                        images[index],
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, _, _) {
                          return AttractionImageView(
                            attraction: attraction,
                            width: double.infinity,
                            height: 230,
                          );
                        },
                      );
                    },
                  ),
                ),

              // ====================================================
              // CONTENT
              // ====================================================

              Padding(
                padding:
                const EdgeInsets.all(
                  16,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    // =================================================
                    // NAME
                    // =================================================

                    Text(
                      attraction.name,
                      style:
                      const TextStyle(
                        fontSize: 25,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      '${attraction.category} · '
                          '${attraction.locationName}',
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    // =================================================
                    // QUICK INFO
                    // =================================================

                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Chip(
                          avatar:
                          const Icon(
                            Icons
                                .payments_outlined,
                            size: 17,
                          ),
                          label: Text(
                            attraction
                                .entrancePriceMyr ==
                                0
                                ? 'Free entry'
                                : 'RM ${attraction.entrancePriceMyr.toStringAsFixed(2)}',
                          ),
                        ),

                        Chip(
                          avatar:
                          const Icon(
                            Icons
                                .groups_outlined,
                            size: 17,
                          ),
                          label: Text(
                            '${attraction.crowdLevel} live crowd · '
                                '${attraction.currentVisitors}/${attraction.maximumCapacity}',
                          ),
                        ),

                        Chip(
                          avatar: const Icon(Icons.star, size: 17),
                          label: Text(attraction.hasRatings
                              ? '${attraction.averageRating.toStringAsFixed(1)}/5 '
                                  '(${attraction.ratingCount})'
                              : 'No ratings yet'),
                        ),

                        Chip(
                          avatar:
                          const Icon(
                            Icons
                                .location_on_outlined,
                            size: 17,
                          ),
                          label: Text(
                            attraction
                                .distanceKm ==
                                null
                                ? 'Distance unavailable'
                                : '${attraction.distanceKm!.toStringAsFixed(1)} km away',
                          ),
                        ),

                        Chip(
                          avatar:
                          const Icon(
                            Icons
                                .place_outlined,
                            size: 17,
                          ),
                          label: Text(
                            attraction
                                .attractionType,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    // =================================================
                    // SUITABILITY WARNING
                    // =================================================

                    if (issues.isNotEmpty) ...[
                      _SuitabilityWarning(
                        issues: issues,
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ===============================================
                      // ALTERNATIVES
                      // ===============================================

                      _SuggestedAlternativesSection(
                        alternatives:
                        alternatives,
                        onTap:
                        _openAlternative,
                      ),

                      const SizedBox(
                        height: 22,
                      ),
                    ],

                    // =================================================
                    // DESCRIPTION
                    // =================================================

                    Text(
                      attraction.description,
                      style:
                      const TextStyle(
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    // =================================================
                    // ADDRESS
                    // =================================================

                    _Section(
                      title: 'Address',
                      child: Text(
                        attraction.address,
                      ),
                    ),

                    // =================================================
                    // TRANSPORT SUGGESTIONS
                    // =================================================

                    _TransportSuggestionsSection(
                      distanceKm:
                      attraction.distanceKm,
                      suggestions:
                      transportSuggestions,
                    ),

                    // =================================================
                    // FACILITIES
                    // =================================================

                    _Section(
                      title: 'Facilities',
                      child: attraction
                          .facilities
                          .isEmpty
                          ? const Text(
                        'No facilities listed.',
                      )
                          : Wrap(
                        spacing: 7,
                        runSpacing: 5,
                        children:
                        attraction
                            .facilities
                            .map(
                              (facility) {
                            return Chip(
                              avatar:
                              const Icon(
                                Icons
                                    .check,
                                size:
                                16,
                              ),
                              label:
                              Text(
                                facility,
                              ),
                            );
                          },
                        ).toList(),
                      ),
                    ),

                    // =================================================
                    // OPERATING HOURS
                    // =================================================

                    _Section(
                      title:
                      'Operating hours',
                      child: _HoursList(
                        hours: attraction
                            .operatingHours,
                      ),
                    ),

                    // =================================================
                    // GUIDELINES
                    // =================================================

                    _Section(
                      title:
                      'Visitor guidelines',
                      child: Text(
                        attraction
                            .visitorGuidelines ??
                            'No additional guidelines.',
                      ),
                    ),

                    // =================================================
                    // RULES
                    // =================================================

                    _Section(
                      title: 'Rules',
                      child: Text(
                        attraction
                            .attractionRules ??
                            'No additional rules.',
                      ),
                    ),

                    // =================================================
                    // AVAILABLE SLOTS
                    // =================================================

                    if (quietest != null)
                      Card(
                        color: const Color(0xFFFFF6E8),
                        child: ListTile(
                          leading: const Icon(Icons.nights_stay_outlined),
                          title: const Text(
                            'Quieter available time',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            '${_date(quietest.startsAt)} · '
                            '${_time(quietest.startsAt)} – ${_time(quietest.endsAt)} · '
                            '${quietest.remainingCapacity} spaces remaining',
                          ),
                          trailing: TextButton(
                            onPressed: () => _book(attraction, slot: quietest),
                            child: const Text('Choose'),
                          ),
                        ),
                      ),

                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                      children: [
                        const Text(
                          'Available slots',
                          style:
                          TextStyle(
                            fontSize: 18,
                            fontWeight:
                            FontWeight
                                .w800,
                          ),
                        ),

                        TextButton(
                          onPressed: () {
                            _book(
                              attraction,
                            );
                          },
                          child:
                          const Text(
                            'See all',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    if (attraction
                        .availableSlots
                        .isEmpty)
                      const Card(
                        child: Padding(
                          padding:
                          EdgeInsets
                              .all(
                            14,
                          ),
                          child: Text(
                            'No future open slots are available.',
                          ),
                        ),
                      )
                    else
                      ...attraction
                          .availableSlots
                          .take(4)
                          .map(
                            (slot) {
                          return Card(
                            color:
                            Colors.white,
                            child:
                            ListTile(
                              leading:
                              const Icon(
                                Icons
                                    .schedule,
                              ),
                              title: Text(
                                '${_date(slot.startsAt)} · '
                                    '${_time(slot.startsAt)} – '
                                    '${_time(slot.endsAt)}',
                              ),
                              subtitle:
                              Text(
                                '${slot.remainingCapacity} of '
                                    '${slot.maximumCapacity} spaces remaining · '
                                    '${_crowd(slot)} estimate',
                              ),
                              trailing:
                              TextButton(
                                onPressed:
                                    () {
                                  _book(
                                    attraction,
                                    slot:
                                    slot,
                                  );
                                },
                                child:
                                const Text(
                                  'Choose',
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(
                      height: 12,
                    ),

                    // =================================================
                    // BOOK BUTTON
                    // =================================================

                    SizedBox(
                      width:
                      double.infinity,
                      child:
                      FilledButton.icon(
                        onPressed: attraction
                            .availableSlots
                            .isEmpty
                            ? null
                            : () {
                          _book(
                            attraction,
                          );
                        },
                        icon:
                        const Icon(
                          Icons
                              .confirmation_num_outlined,
                        ),
                        label:
                        const Text(
                          'Choose a Visit Slot',
                        ),
                        style:
                        FilledButton
                            .styleFrom(
                          backgroundColor:
                          const Color(
                            0xFF79571E,
                          ),
                          padding:
                          const EdgeInsets
                              .all(
                            15,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    // =================================================
                    // SMART RECOMMENDATIONS
                    // =================================================

                    TextButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          SmartRecommendationsPage
                              .routeName,
                        );
                      },
                      icon: const Icon(
                        Icons
                            .auto_awesome_outlined,
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

// =================================================================
// SUITABILITY WARNING
// =================================================================

class _SuitabilityWarning
    extends StatelessWidget {
  const _SuitabilityWarning({
    required this.issues,
  });

  final List<String> issues;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(
          0xFFFFF3E0,
        ),
        borderRadius:
        BorderRadius.circular(12),
        border: Border.all(
          color: const Color(
            0xFFFFCC80,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons
                    .warning_amber_rounded,
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
                  CrossAxisAlignment
                      .start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 17,
                      color:
                      Colors.orange,
                    ),

                    const SizedBox(
                      width: 7,
                    ),

                    Expanded(
                      child: Text(
                        issue,
                        style:
                        const TextStyle(
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

// =================================================================
// SUGGESTED ALTERNATIVES
// =================================================================

class _SuggestedAlternativesSection
    extends StatelessWidget {
  const _SuggestedAlternativesSection({
    required this.alternatives,
    required this.onTap,
  });

  final List<RecommendationResult>
  alternatives;

  final ValueChanged<
      RecommendationResult> onTap;

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
              color:
              Color(0xFF79571E),
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
            color: Color(
              0xFF64748B,
            ),
          ),
        ),

        const SizedBox(height: 12),

        if (alternatives.isEmpty)
          const Card(
            color: Color(
              0xFFFFF7EB,
            ),
            child: Padding(
              padding:
              EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons
                        .search_off_outlined,
                    size: 34,
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Text(
                    'No similar alternative attraction is currently available.',
                    textAlign:
                    TextAlign.center,
                  ),
                  SizedBox(
                    height: 4,
                  ),
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

// =================================================================
// ALTERNATIVE CARD
// =================================================================

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
        BorderRadius.circular(
          12,
        ),
        child: Padding(
          padding:
          const EdgeInsets.all(
            14,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
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
                      BorderRadius
                          .circular(
                        10,
                      ),
                    ),
                    child: Text(
                      '#$rank',
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight
                            .w800,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

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
                            FontWeight
                                .w800,
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
                        FontWeight
                            .w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 10,
              ),

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

                  if (attraction
                      .distanceKm !=
                      null)
                    _MiniInfo(
                      icon: Icons
                          .location_on_outlined,
                      label:
                      '${attraction.distanceKm!.toStringAsFixed(1)} km',
                    ),

                  _MiniInfo(
                    icon: Icons
                        .groups_outlined,
                    label:
                    '${attraction.crowdLevel} live crowd',
                  ),
                ],
              ),

              const SizedBox(
                height: 10,
              ),

              ...result.reasons
                  .take(3)
                  .map(
                    (reason) {
                  return Padding(
                    padding:
                    const EdgeInsets
                        .only(
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
                          color:
                          Colors.green,
                        ),

                        const SizedBox(
                          width: 6,
                        ),

                        Expanded(
                          child: Text(
                            reason,
                            style:
                            const TextStyle(
                              fontSize:
                              11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(
                height: 8,
              ),

              SizedBox(
                width:
                double.infinity,
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

// =================================================================
// TRANSPORT SUGGESTIONS
// =================================================================

class _TransportSuggestionsSection
    extends StatelessWidget {
  const _TransportSuggestionsSection({
    required this.distanceKm,
    required this.suggestions,
  });

  final double? distanceKm;

  final List<_TransportSuggestion>
  suggestions;

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
          const Row(
            children: [
              Icon(
                Icons
                    .directions_outlined,
                color:
                Color(0xFF79571E),
              ),

              SizedBox(width: 8),

              Text(
                'Getting There',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          Text(
            distanceKm == null
                ? 'Transport suggestions are unavailable because the distance could not be calculated.'
                : 'Suggested transport options for approximately '
                '${distanceKm!.toStringAsFixed(1)} km.',
            style: const TextStyle(
              fontSize: 12,
              color:
              Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 10),

          if (suggestions.isEmpty)
            const Card(
              child: Padding(
                padding:
                EdgeInsets.all(14),
                child: Text(
                  'Transport suggestions are currently unavailable.',
                ),
              ),
            )
          else
            ...suggestions.map(
                  (suggestion) =>
                  _TransportCard(
                    suggestion:
                    suggestion,
                  ),
            ),

          if (suggestions.isNotEmpty)
            const Padding(
              padding:
              EdgeInsets.only(
                top: 5,
              ),
              child: Row(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 15,
                    color:
                    Color(
                      0xFF64748B,
                    ),
                  ),

                  SizedBox(width: 6),

                  Expanded(
                    child: Text(
                      'Travel times and fares are estimates only. '
                          'Actual traffic, routes, availability and prices may vary.',
                      style:
                      TextStyle(
                        fontSize: 10,
                        color:
                        Color(
                          0xFF64748B,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// =================================================================
// TRANSPORT CARD
// =================================================================

class _TransportCard
    extends StatelessWidget {
  const _TransportCard({
    required this.suggestion,
  });

  final _TransportSuggestion
  suggestion;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: suggestion.recommended
          ? const Color(
        0xFFFFF5E6,
      )
          : Colors.white,
      child: Padding(
        padding:
        const EdgeInsets.all(
          12,
        ),
        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor:
              suggestion.recommended
                  ? const Color(
                0xFFFFD08B,
              )
                  : const Color(
                0xFFF1F5F9,
              ),
              child: Icon(
                _transportIcon(
                  suggestion.mode,
                ),
                color:
                const Color(
                  0xFF79571E,
                ),
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          suggestion.title,
                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight
                                .w800,
                          ),
                        ),
                      ),

                      if (suggestion
                          .recommended)
                        Container(
                          padding:
                          const EdgeInsets
                              .symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration:
                          BoxDecoration(
                            color:
                            const Color(
                              0xFFFFD08B,
                            ),
                            borderRadius:
                            BorderRadius
                                .circular(
                              20,
                            ),
                          ),
                          child:
                          const Text(
                            'Recommended',
                            style:
                            TextStyle(
                              fontSize: 9,
                              fontWeight:
                              FontWeight
                                  .w800,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Wrap(
                    spacing: 12,
                    runSpacing: 5,
                    children: [
                      _TransportInfo(
                        icon:
                        Icons.schedule,
                        text: suggestion
                            .timeLabel,
                      ),

                      _TransportInfo(
                        icon: Icons
                            .payments_outlined,
                        text: suggestion
                            .fareLabel,
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Text(
                    suggestion.description,
                    style:
                    const TextStyle(
                      fontSize: 11,
                      color:
                      Color(
                        0xFF64748B,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// TRANSPORT INFO
// =================================================================

class _TransportInfo
    extends StatelessWidget {
  const _TransportInfo({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize:
      MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight:
            FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// =================================================================
// TRANSPORT MODEL
// =================================================================

enum _TransportMode {
  walking,
  carEhailing,
  publicTransport,
}

class _TransportSuggestion {
  const _TransportSuggestion({
    required this.mode,
    required this.title,
    required this.estimatedMinutesMin,
    required this.estimatedMinutesMax,
    required this.description,
    this.fareMinMyr,
    this.fareMaxMyr,
    this.recommended = false,
  });

  final _TransportMode mode;

  final String title;

  final int estimatedMinutesMin;

  final int estimatedMinutesMax;

  final double? fareMinMyr;

  final double? fareMaxMyr;

  final String description;

  final bool recommended;

  String get timeLabel {
    if (estimatedMinutesMin ==
        estimatedMinutesMax) {
      return '~$estimatedMinutesMin min';
    }

    return '$estimatedMinutesMin–'
        '$estimatedMinutesMax min';
  }

  String get fareLabel {
    if (fareMinMyr == null ||
        fareMaxMyr == null) {
      return 'Free';
    }

    return 'RM ${fareMinMyr!.toStringAsFixed(0)}–'
        '${fareMaxMyr!.toStringAsFixed(0)}';
  }
}

// =================================================================
// TRANSPORT SERVICE
// =================================================================

class _TransportSuggestionService {
  const _TransportSuggestionService();

  List<_TransportSuggestion>
  suggestionsForDistance(
      double? distanceKm,
      ) {
    if (distanceKm == null ||
        distanceKm.isNaN ||
        distanceKm < 0) {
      return const [];
    }

    final suggestions =
    <_TransportSuggestion>[];

    // =============================================================
    // WALKING
    // =============================================================

    if (distanceKm <= 5) {
      var minMinutes =
      (distanceKm / 4.8 * 60)
          .ceil();

      if (minMinutes < 1) {
        minMinutes = 1;
      }

      var maxMinutes =
      (minMinutes * 1.20)
          .ceil();

      if (maxMinutes <
          minMinutes + 5) {
        maxMinutes =
            minMinutes + 5;
      }

      suggestions.add(
        _TransportSuggestion(
          mode:
          _TransportMode.walking,
          title: 'Walking',
          estimatedMinutesMin:
          minMinutes,
          estimatedMinutesMax:
          maxMinutes,
          description:
          distanceKm <= 1.5
              ? 'A convenient option for this short distance.'
              : 'Suitable if you prefer walking and the route is comfortable.',
          recommended:
          distanceKm <= 1.5,
        ),
      );
    }

    // =============================================================
    // CAR / E-HAILING
    // =============================================================

    final carBase =
    (distanceKm / 28 * 60)
        .ceil();

    var carMin =
        carBase + 5;

    if (carMin < 5) {
      carMin = 5;
    }

    var carMax =
        (carBase * 1.35).ceil() +
            10;

    if (carMax < carMin + 5) {
      carMax = carMin + 5;
    }

    var fareMin =
        4 + (distanceKm * 1.2);

    if (fareMin < 6) {
      fareMin = 6;
    }

    var fareMax =
        7 + (distanceKm * 2);

    if (fareMax <
        fareMin + 3) {
      fareMax = fareMin + 3;
    }

    suggestions.add(
      _TransportSuggestion(
        mode:
        _TransportMode.carEhailing,
        title: 'Car / E-hailing',
        estimatedMinutesMin:
        carMin,
        estimatedMinutesMax:
        carMax,
        fareMinMyr:
        fareMin.toDouble(),
        fareMaxMyr:
        fareMax.toDouble(),
        description:
        'A practical direct travel option, especially for medium or longer distances.',
        recommended:
        distanceKm > 1.5,
      ),
    );

    // =============================================================
    // PUBLIC TRANSPORT
    // =============================================================

    final publicBase =
    (distanceKm / 18 * 60)
        .ceil();

    var publicMin =
        publicBase + 15;

    if (publicMin < 15) {
      publicMin = 15;
    }

    final publicMax =
        publicMin + 20;

    var publicFareMax =
        3 + (distanceKm * 0.3);

    if (publicFareMax < 4) {
      publicFareMax = 4;
    }

    if (publicFareMax > 12) {
      publicFareMax = 12;
    }

    suggestions.add(
      _TransportSuggestion(
        mode: _TransportMode
            .publicTransport,
        title:
        'Public Transport',
        estimatedMinutesMin:
        publicMin,
        estimatedMinutesMax:
        publicMax,
        fareMinMyr: 2,
        fareMaxMyr:
        publicFareMax,
        description:
        'A budget-friendly choice when suitable public transport routes are available.',
      ),
    );

    suggestions.sort(
          (a, b) {
        if (a.recommended &&
            !b.recommended) {
          return -1;
        }

        if (!a.recommended &&
            b.recommended) {
          return 1;
        }

        return a
            .estimatedMinutesMin
            .compareTo(
          b.estimatedMinutesMin,
        );
      },
    );

    return suggestions;
  }
}

IconData _transportIcon(
    _TransportMode mode,
    ) {
  switch (mode) {
    case _TransportMode.walking:
      return Icons.directions_walk;

    case _TransportMode.carEhailing:
      return Icons
          .local_taxi_outlined;

    case _TransportMode.publicTransport:
      return Icons
          .directions_bus_outlined;
  }
}

// =================================================================
// MINI INFO
// =================================================================

class _MiniInfo
    extends StatelessWidget {
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
      const EdgeInsets
          .symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color:
        Colors.grey.shade100,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
      ),
      child: Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
          ),
          const SizedBox(
            width: 4,
          ),
          Text(
            label,
            style:
            const TextStyle(
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

// =================================================================
// SECTION
// =================================================================

class _Section
    extends StatelessWidget {
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
            style:
            const TextStyle(
              fontSize: 17,
              fontWeight:
              FontWeight.w800,
            ),
          ),
          const SizedBox(
            height: 7,
          ),
          child,
        ],
      ),
    );
  }
}

// =================================================================
// HOURS
// =================================================================

class _HoursList
    extends StatelessWidget {
  const _HoursList({
    required this.hours,
  });

  final List<
      AttractionOperatingHours> hours;

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
                    days[
                    item.dayOfWeek],
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

// =================================================================
// HELPERS
// =================================================================

String _date(DateTime value) {
  return '${value.day}/'
      '${value.month}/'
      '${value.year}';
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
