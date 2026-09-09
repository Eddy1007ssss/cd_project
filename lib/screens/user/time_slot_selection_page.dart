import 'package:flutter/material.dart';

import '../../models/module3_models.dart';
import '../../repositories/module3_repository.dart';
import 'booking_review_page.dart';

// ==================================================================
// ROUTE ARGUMENTS
// ==================================================================

class TimeSlotSelectionArguments {
  const TimeSlotSelectionArguments({
    required this.attractionId,
    required this.attractionName,
    this.category = 'Attraction',
    this.locationName = 'Malaysia',
    this.preselectedSlotId,
  });

  final String attractionId;
  final String attractionName;
  final String category;
  final String locationName;

  // Used when the tourist presses "Choose"
  // from Attraction Details.
  final String? preselectedSlotId;

  factory TimeSlotSelectionArguments.fromMap(
      Map<dynamic, dynamic> map,
      ) {
    return TimeSlotSelectionArguments(
      attractionId:
      map['attractionId']?.toString() ?? '',
      attractionName:
      map['attractionName']?.toString() ??
          'Attraction',
      category:
      map['category']?.toString() ??
          'Attraction',
      locationName:
      map['locationName']?.toString() ??
          'Malaysia',
      preselectedSlotId:
      map['preselectedSlotId']
          ?.toString(),
    );
  }
}

// ==================================================================
// PAGE
// ==================================================================

class TimeSlotSelectionPage
    extends StatefulWidget {
  const TimeSlotSelectionPage({
    super.key,
  });

  static const routeName =
      '/time-slot-selection';

  @override
  State<TimeSlotSelectionPage>
  createState() =>
      _TimeSlotSelectionPageState();
}

// ==================================================================
// PAGE STATE
// ==================================================================

class _TimeSlotSelectionPageState
    extends State<TimeSlotSelectionPage> {
  final _repository =
  Module3Repository();

  late final List<DateTime> _dates;

  TimeSlotSelectionArguments?
  _arguments;

  late DateTime _selectedDate;

  AttractionSlot? _selectedSlot;

  int _visitors = 1;

  bool _loading = true;

  String? _error;
  String? _notice;

  List<AttractionSlot> _slots =
  const [];

  // =================================================================
  // INITIALIZE
  // =================================================================

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _dates = List.generate(
      7,
          (index) => DateTime(
        now.year,
        now.month,
        now.day + index,
      ),
    );

    _selectedDate = _dates.first;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_arguments != null) {
      return;
    }

    final value =
        ModalRoute.of(context)
            ?.settings
            .arguments;

    // ===============================================================
    // SUPPORT TimeSlotSelectionArguments
    // ===============================================================

    if (value
    is TimeSlotSelectionArguments) {
      _arguments = value;
    }

    // ===============================================================
    // SUPPORT MAP FROM ATTRACTION DETAILS PAGE
    // ===============================================================

    else if (value is Map) {
      final parsed =
      TimeSlotSelectionArguments
          .fromMap(
        value,
      );

      if (parsed
          .attractionId
          .isNotEmpty) {
        _arguments = parsed;
      }
    }

    // ===============================================================
    // DEMO FALLBACK
    // ===============================================================

    _arguments ??=
    const TimeSlotSelectionArguments(
      attractionId:
      '10000000-0000-0000-0000-000000000001',
      attractionName:
      'Merdeka Heritage Walk',
      category:
      'Historical Landmark',
      locationName:
      'Kuala Lumpur',
    );

    _loadInitial();
  }

  // =================================================================
  // INITIAL LOAD
  // =================================================================

  Future<void> _loadInitial() async {
    final preselectedId =
        _arguments!
            .preselectedSlotId;

    // If no slot was selected from the previous page,
    // just load today's slots normally.
    if (preselectedId == null ||
        preselectedId.isEmpty) {
      await _load();
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _notice = null;
      _selectedSlot = null;
    });

    try {
      List<AttractionSlot>?
      firstDaySlots;

      // =============================================================
      // FIND PRESELECTED SLOT WITHIN AVAILABLE 7 DAYS
      // =============================================================

      for (var index = 0;
      index < _dates.length;
      index++) {
        final date =
        _dates[index];

        final result =
        await _repository
            .fetchSlots(
          attractionId:
          _arguments!
              .attractionId,
          date: date,
        );

        if (index == 0) {
          firstDaySlots = result;
        }

        final matchingSlot =
        _findSlotById(
          result,
          preselectedId,
        );

        if (matchingSlot != null) {
          if (!mounted) {
            return;
          }

          setState(() {
            _selectedDate = date;
            _slots = result;
            _selectedSlot =
                matchingSlot;
            _loading = false;

            _adjustVisitorsForSlot(
              matchingSlot,
            );
          });

          return;
        }
      }

      // =============================================================
      // PRESELECTED SLOT NO LONGER AVAILABLE
      // =============================================================

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedDate =
            _dates.first;

        _slots =
            firstDaySlots ??
                const [];

        _selectedSlot =
        null;

        _notice =
        'The previously selected slot is no longer available. '
            'Please choose another available time slot.';

        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error =
        'Could not load slots: $error';

        _loading = false;
      });
    }
  }

  // =================================================================
  // LOAD SLOT FOR SELECTED DATE
  // =================================================================

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _notice = null;
      _selectedSlot = null;
    });

    try {
      final result =
      await _repository.fetchSlots(
        attractionId:
        _arguments!.attractionId,
        date:
        _selectedDate,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _slots = result;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error =
        'Could not load slots: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // =================================================================
  // FIND SLOT
  // =================================================================

  AttractionSlot? _findSlotById(
      List<AttractionSlot> slots,
      String id,
      ) {
    for (final slot in slots) {
      if (slot.id == id) {
        return slot;
      }
    }

    return null;
  }

  // =================================================================
  // SELECT SLOT
  // =================================================================

  void _selectSlot(
      AttractionSlot slot,
      ) {
    setState(() {
      _selectedSlot = slot;

      _adjustVisitorsForSlot(
        slot,
      );
    });
  }

  // =================================================================
  // ADJUST VISITORS BASED ON CAPACITY
  // =================================================================

  void _adjustVisitorsForSlot(
      AttractionSlot slot,
      ) {
    var maximumVisitors =
        slot.remainingCapacity;

    if (maximumVisitors > 10) {
      maximumVisitors = 10;
    }

    if (maximumVisitors < 1) {
      maximumVisitors = 1;
    }

    if (_visitors >
        maximumVisitors) {
      _visitors =
          maximumVisitors;
    }
  }

  // =================================================================
  // MAXIMUM VISITORS
  // =================================================================

  int get _maximumVisitors {
    final slot =
        _selectedSlot;

    if (slot == null) {
      return 10;
    }

    var maximum =
        slot.remainingCapacity;

    if (maximum > 10) {
      maximum = 10;
    }

    if (maximum < 1) {
      maximum = 1;
    }

    return maximum;
  }

  // =================================================================
  // REVIEW BOOKING
  // =================================================================

  void _reviewBooking() {
    final slot =
        _selectedSlot;

    if (slot == null) {
      return;
    }

    Navigator.pushNamed(
      context,
      BookingReviewPage.routeName,
      arguments:
      BookingReviewArguments(
        slot: slot,
        visitors: _visitors,
      ),
    );
  }

  // =================================================================
  // PAGE
  // =================================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final attraction =
    _arguments!;

    return Scaffold(
      appBar: AppBar(
        title:
        const Text(
          'Select a Time Slot',
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _load,

        child: ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),

          padding:
          const EdgeInsets.all(
            16,
          ),

          children: [
            // ========================================================
            // ATTRACTION INFORMATION
            // ========================================================

            Card(
              color:
              const Color(
                0xFFFFF5E6,
              ),
              child:
              Padding(
                padding:
                const EdgeInsets.all(
                  16,
                ),
                child:
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Row(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        const Icon(
                          Icons
                              .place_outlined,
                          color:
                          Color(
                            0xFF79571E,
                          ),
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        Expanded(
                          child:
                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [
                              Text(
                                attraction
                                    .attractionName,
                                style:
                                const TextStyle(
                                  fontSize:
                                  22,
                                  fontWeight:
                                  FontWeight
                                      .w800,
                                ),
                              ),

                              const SizedBox(
                                height: 3,
                              ),

                              Text(
                                '${attraction.category} · '
                                    '${attraction.locationName}',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // ========================================================
            // DATE SELECTION
            // ========================================================

            const Row(
              children: [
                Icon(
                  Icons
                      .calendar_month_outlined,
                  size: 20,
                ),

                SizedBox(
                  width: 7,
                ),

                Text(
                  'Choose your visit date',
                  style:
                  TextStyle(
                    fontSize: 17,
                    fontWeight:
                    FontWeight
                        .w800,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 10,
            ),

            SizedBox(
              height: 52,

              child:
              ListView.separated(
                scrollDirection:
                Axis.horizontal,

                itemCount:
                _dates.length,

                separatorBuilder:
                    (
                    context,
                    index,
                    ) =>
                const SizedBox(
                  width: 8,
                ),

                itemBuilder:
                    (
                    context,
                    index,
                    ) {
                  final date =
                  _dates[index];

                  return ChoiceChip(
                    label:
                    Text(
                      shortDate(
                        date,
                      ).substring(
                        0,
                        shortDate(
                          date,
                        ).length -
                            5,
                      ),
                    ),

                    selected:
                    _sameDay(
                      _selectedDate,
                      date,
                    ),

                    selectedColor:
                    const Color(
                      0xFFFFD08B,
                    ),

                    onSelected:
                        (
                        selected,
                        ) {
                      if (!selected) {
                        return;
                      }

                      setState(() {
                        _selectedDate =
                            date;
                      });

                      _load();
                    },
                  );
                },
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // ========================================================
            // SLOT HEADER
            // ========================================================

            const Row(
              children: [
                Icon(
                  Icons
                      .schedule_outlined,
                  size: 20,
                ),

                SizedBox(
                  width: 7,
                ),

                Text(
                  'Available time slots',
                  style:
                  TextStyle(
                    fontSize: 17,
                    fontWeight:
                    FontWeight
                        .w800,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 10,
            ),

            // ========================================================
            // NOTICE
            // ========================================================

            if (_notice !=
                null) ...[
              Card(
                color:
                const Color(
                  0xFFFFF3E0,
                ),
                child:
                Padding(
                  padding:
                  const EdgeInsets.all(
                    14,
                  ),
                  child:
                  Row(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      const Icon(
                        Icons
                            .info_outline,
                        color:
                        Colors.orange,
                      ),

                      const SizedBox(
                        width: 8,
                      ),

                      Expanded(
                        child:
                        Text(
                          _notice!,
                          style:
                          const TextStyle(
                            fontSize:
                            12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 8,
              ),
            ],

            // ========================================================
            // SLOT CONTENT
            // ========================================================

            if (_loading)

              const Padding(
                padding:
                EdgeInsets.all(
                  28,
                ),
                child:
                Center(
                  child:
                  CircularProgressIndicator(),
                ),
              )

            else if (_error !=
                null)

              _MessageCard(
                message:
                _error!,
                icon:
                Icons.error_outline,
              )

            else if (_slots
                  .isEmpty)

                const _MessageCard(
                  message:
                  'No slots are scheduled for this date. '
                      'Try another day.',
                  icon:
                  Icons
                      .event_busy_outlined,
                )

              else

                ..._slots.map(
                      (
                      slot,
                      ) {
                    final selected =
                        _selectedSlot
                            ?.id ==
                            slot.id;

                    return Card(
                      color: selected
                          ? const Color(
                        0xFFFFF5E6,
                      )
                          : Colors.white,

                      elevation:
                      selected
                          ? 2
                          : 1,

                      child:
                      ListTile(
                        enabled:
                        slot.isBookable,

                        onTap:
                        slot.isBookable
                            ? () {
                          _selectSlot(
                            slot,
                          );
                        }
                            : null,

                        leading:
                        Icon(
                          selected
                              ? Icons
                              .radio_button_checked
                              : Icons
                              .radio_button_unchecked,

                          color: selected
                              ? const Color(
                            0xFF79571E,
                          )
                              : null,
                        ),

                        title:
                        Text(
                          slotTime(
                            slot,
                          ),
                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight
                                .w800,
                          ),
                        ),

                        subtitle:
                        Text(
                          '${slot.status.toUpperCase()} · '
                              '${slot.remainingCapacity} of '
                              '${slot.maximumCapacity} spaces left',
                        ),

                        trailing:
                        _StatusBadge(
                          slot,
                        ),
                      ),
                    );
                  },
                ),

            const SizedBox(
              height: 20,
            ),

            // ========================================================
            // VISITOR SELECTION
            // ========================================================

            const Row(
              children: [
                Icon(
                  Icons
                      .groups_outlined,
                  size: 20,
                ),

                SizedBox(
                  width: 7,
                ),

                Text(
                  'Number of visitors',
                  style:
                  TextStyle(
                    fontSize: 17,
                    fontWeight:
                    FontWeight
                        .w800,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 8,
            ),

            Card(
              color: Colors.white,

              child:
              Padding(
                padding:
                const EdgeInsets.all(
                  12,
                ),

                child:
                Row(
                  children: [
                    const Icon(
                      Icons
                          .group_outlined,
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    Expanded(
                      child:
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          const Text(
                            'Visitors',
                            style:
                            TextStyle(
                              fontWeight:
                              FontWeight
                                  .w700,
                            ),
                          ),

                          Text(
                            _selectedSlot ==
                                null
                                ? 'Maximum 10 visitors'
                                : 'Maximum $_maximumVisitors for this slot',
                            style:
                            const TextStyle(
                              fontSize:
                              11,
                              color:
                              Color(
                                0xFF64748B,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton.outlined(
                      onPressed:
                      _visitors >
                          1
                          ? () {
                        setState(
                              () {
                            _visitors--;
                          },
                        );
                      }
                          : null,
                      icon:
                      const Icon(
                        Icons.remove,
                      ),
                    ),

                    Padding(
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal:
                        12,
                      ),
                      child:
                      Text(
                        '$_visitors',
                        style:
                        const TextStyle(
                          fontSize:
                          20,
                          fontWeight:
                          FontWeight
                              .w800,
                        ),
                      ),
                    ),

                    IconButton.filled(
                      onPressed:
                      _visitors <
                          _maximumVisitors
                          ? () {
                        setState(
                              () {
                            _visitors++;
                          },
                        );
                      }
                          : null,
                      icon:
                      const Icon(
                        Icons.add,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // ========================================================
            // SELECTED SLOT SUMMARY
            // ========================================================

            if (_selectedSlot !=
                null) ...[
              Container(
                padding:
                const EdgeInsets.all(
                  14,
                ),

                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFE8F5E9,
                  ),

                  borderRadius:
                  BorderRadius
                      .circular(
                    12,
                  ),

                  border:
                  Border.all(
                    color:
                    Colors.green
                        .shade200,
                  ),
                ),

                child:
                Row(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

                  children: [
                    const Icon(
                      Icons
                          .check_circle_outline,
                      color:
                      Colors.green,
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    Expanded(
                      child:
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          const Text(
                            'Selected Visit',
                            style:
                            TextStyle(
                              fontWeight:
                              FontWeight
                                  .w800,
                            ),
                          ),

                          const SizedBox(
                            height: 3,
                          ),

                          Text(
                            '${shortDate(_selectedDate)} · '
                                '${slotTime(_selectedSlot!)}',
                          ),

                          Text(
                            '$_visitors visitor'
                                '${_visitors == 1 ? '' : 's'}',
                            style:
                            const TextStyle(
                              fontSize:
                              12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 16,
              ),
            ],

            // ========================================================
            // REVIEW BOOKING
            // ========================================================

            FilledButton.icon(
              onPressed:
              _selectedSlot !=
                  null &&
                  _selectedSlot!
                      .isBookable &&
                  _selectedSlot!
                      .remainingCapacity >=
                      _visitors
                  ? _reviewBooking
                  : null,

              icon:
              const Icon(
                Icons
                    .fact_check_outlined,
              ),

              label:
              Text(
                _selectedSlot ==
                    null
                    ? 'Select a Time Slot First'
                    : 'Review Booking',
              ),

              style:
              FilledButton
                  .styleFrom(
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

            const SizedBox(
              height: 24,
            ),
          ],
        ),
      ),
    );
  }

  // =================================================================
  // SAME DAY
  // =================================================================

  bool _sameDay(
      DateTime first,
      DateTime second,
      ) {
    return first.year ==
        second.year &&
        first.month ==
            second.month &&
        first.day ==
            second.day;
  }
}

// ==================================================================
// MESSAGE CARD
// ==================================================================

class _MessageCard
    extends StatelessWidget {
  const _MessageCard({
    required this.message,
    required this.icon,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Card(
      color: Colors.white,

      child:
      Padding(
        padding:
        const EdgeInsets.all(
          16,
        ),

        child:
        Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            Icon(
              icon,
              color:
              const Color(
                0xFF79571E,
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child:
              Text(
                message,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// STATUS BADGE
// ==================================================================

class _StatusBadge
    extends StatelessWidget {
  const _StatusBadge(
      this.slot,
      );

  final AttractionSlot slot;

  @override
  Widget build(
      BuildContext context,
      ) {
    final ratio =
    slot.maximumCapacity <= 0
        ? 1.0
        : slot.reservedCapacity /
        slot.maximumCapacity;

    late final String label;
    late final Color color;

    // ===============================================================
    // NOT BOOKABLE
    // ===============================================================

    if (!slot.isBookable) {
      label =
          slot.status.toUpperCase();

      color =
          Colors.red;
    }

    // ===============================================================
    // LOW CROWD
    // ===============================================================

    else if (ratio < .4) {
      label = 'LOW';
      color = Colors.green;
    }

    // ===============================================================
    // MODERATE CROWD
    // ===============================================================

    else if (ratio < .75) {
      label = 'MODERATE';
      color =
          Colors.amber.shade800;
    }

    // ===============================================================
    // HIGH CROWD
    // ===============================================================

    else {
      label = 'HIGH';
      color =
          Colors.orange.shade800;
    }

    return Chip(
      label:
      Text(
        label,
        style:
        TextStyle(
          color: color,
          fontSize: 10,
          fontWeight:
          FontWeight.w700,
        ),
      ),

      backgroundColor:
      color.withValues(
        alpha: .1,
      ),

      side:
      BorderSide.none,
    );
  }
}
