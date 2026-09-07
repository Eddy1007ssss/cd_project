import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/module3_models.dart';
import 'booking_qr_page.dart';
import 'geofence_page.dart';

class CapacityAlertPage extends StatefulWidget {
  const CapacityAlertPage({super.key});

  static const String routeName = '/capacity-alert';

  @override
  State<CapacityAlertPage> createState() =>
      _CapacityAlertPageState();
}

class _CapacityAlertPageState extends State<CapacityAlertPage>
    with WidgetsBindingObserver {
  Timer? _timer;
  TourBooking? _booking;
  _CapacityData? _data;

  bool _initialized = false;
  bool _loading = false;
  bool _foreground = true;

  String? _error;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  // ============================================================
  // LOAD BOOKING
  // ============================================================

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    _initialized = true;

    final arguments =
        ModalRoute.of(context)?.settings.arguments;

    if (arguments is! TourBooking) return;

    _booking = arguments;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _refresh();
      _startTimer();
    });
  }

  // ============================================================
  // APP LIFECYCLE
  // ============================================================

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state,
      ) {
    _foreground =
        state == AppLifecycleState.resumed;

    if (_foreground) {
      if (ModalRoute.of(context)?.isCurrent == true) {
        _refresh();
      }

      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _timer?.cancel();

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  // ============================================================
  // AUTO REFRESH
  // ============================================================

  void _startTimer() {
    _timer?.cancel();

    if (!_foreground || _booking == null) {
      return;
    }

    _timer = Timer.periodic(
      const Duration(seconds: 3),
          (_) {
        if (!mounted || !_foreground) {
          return;
        }

        if (ModalRoute.of(context)?.isCurrent != true) {
          return;
        }

        _refresh();
      },
    );
  }

  // ============================================================
  // REFRESH CAPACITY
  // ============================================================

  Future<void> _refresh() async {
    final booking = _booking;

    if (!mounted ||
        !_foreground ||
        _loading ||
        booking == null) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final result =
      await Supabase.instance.client.rpc(
        'get_booking_capacity',
        params: {
          'target_booking_id': booking.id,
        },
      );

      if (result is! Map) {
        throw const FormatException(
          'Invalid capacity response.',
        );
      }

      final data = _CapacityData.fromMap(
        result.cast<String, dynamic>(),
      );

      if (!mounted) return;

      setState(() {
        _data = data;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = _data == null
            ? 'Unable to load capacity information. Please try again.'
            : 'Unable to refresh. The displayed information may be out of date.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ============================================================
  // OPEN PAGE
  // ============================================================

  Future<void> _openPage(
      String routeName,
      ) async {
    final booking = _booking;

    if (booking == null) {
      return;
    }

    // Geofence / open attractions should never open QR.
    if (routeName == BookingQrPage.routeName &&
        !booking.slot.usesStaffScan) {
      return;
    }

    await Navigator.pushNamed(
      context,
      routeName,
      arguments: booking,
    );

    if (!mounted) return;

    await _refresh();
  }

  // ============================================================
  // PHOTO PLACEHOLDER
  // ============================================================

  Widget _photoPlaceholder() {
    return Container(
      height: 210,
      color: const Color(
        0xFFFFEAD0,
      ),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_outlined,
            size: 46,
            color: Color(
              0xFF79571E,
            ),
          ),
          SizedBox(
            height: 8,
          ),
          Text(
            'Attraction photo unavailable',
            style: TextStyle(
              color: Color(
                0xFF79571E,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAIN CONTENT
  // ============================================================

  Widget _buildContent(
      _CapacityData data,
      ) {
    final booking = _booking!;
    final imageUrl = data.coverImageUrl;
    final color = data.levelColor;

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.stretch,
      children: [
        // ======================================================
        // ATTRACTION CARD
        // ======================================================

        Card(
          color: Colors.white,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              16,
            ),
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.stretch,
            children: [
              if (imageUrl == null ||
                  imageUrl.trim().isEmpty)
                _photoPlaceholder()
              else
                Image.network(
                  imageUrl,
                  height: 210,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (
                      context,
                      error,
                      stackTrace,
                      ) {
                    return _photoPlaceholder();
                  },
                ),

              Padding(
                padding:
                const EdgeInsets.all(
                  18,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.attractionName,
                      style:
                      const TextStyle(
                        fontSize: 21,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      data.locationName,
                      style:
                      const TextStyle(
                        color:
                        Colors.black54,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      booking.bookingCode,
                      style:
                      const TextStyle(
                        color:
                        Color(
                          0xFF79571E,
                        ),
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      '${shortDate(booking.slot.startsAt)} '
                          '· ${slotTime(booking.slot)}',
                      style:
                      const TextStyle(
                        color:
                        Colors.black54,
                        fontSize: 12,
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

        // ======================================================
        // CURRENT CROWD LEVEL
        // ======================================================

        Container(
          padding:
          const EdgeInsets.all(
            18,
          ),
          decoration:
          BoxDecoration(
            color:
            color.withAlpha(
              20,
            ),
            borderRadius:
            BorderRadius.circular(
              14,
            ),
            border:
            Border.all(
              color:
              color.withAlpha(
                60,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Text(
                'Current Crowd Level',
                style:
                TextStyle(
                  color:
                  Colors.black54,
                  fontSize: 13,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              Text(
                data.levelLabel,
                style:
                TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              const Text(
                'Based on current attraction occupancy.',
                style:
                TextStyle(
                  fontSize: 12,
                  color:
                  Colors.black54,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        // ======================================================
        // CURRENT VISITORS
        // ======================================================

        _InformationCard(
          title: 'Current Visitors',
          icon: Icons.groups_outlined,
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                '${data.currentVisitors} / '
                    '${data.maximumCapacity}',
                style:
                const TextStyle(
                  fontSize: 25,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              ClipRRect(
                borderRadius:
                BorderRadius.circular(
                  8,
                ),
                child:
                LinearProgressIndicator(
                  value:
                  data.occupancy
                      .clamp(
                    0.0,
                    1.0,
                  )
                      .toDouble(),
                  minHeight: 9,
                  backgroundColor:
                  const Color(
                    0xFFF0ECE5,
                  ),
                  color: color,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                '${(data.occupancy * 100).toStringAsFixed(0)}% occupied',
                style:
                const TextStyle(
                  color:
                  Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        // ======================================================
        // AVAILABLE CAPACITY
        // ======================================================

        _InformationCard(
          title:
          'Available Capacity',
          icon:
          Icons.people_alt_outlined,
          child: Text(
            '${data.availableCapacity} space(s)',
            style:
            const TextStyle(
              fontSize: 19,
              fontWeight:
              FontWeight.w800,
            ),
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        // ======================================================
        // ENTRY RECOMMENDATION
        //
        // Replaces Estimated Waiting Time
        // ======================================================

        _InformationCard(
          title:
          'Entry Recommendation',
          icon:
          Icons.directions_walk_outlined,
          child: Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Icon(
                data.entryRecommendationIcon,
                color:
                data.entryRecommendationColor,
                size: 24,
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: Text(
                  data.entryRecommendation,
                  style:
                  TextStyle(
                    color:
                    data.entryRecommendationColor,
                    height: 1.4,
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        // ======================================================
        // RECOMMENDATION
        // ======================================================

        _InformationCard(
          title:
          'Recommendation',
          icon:
          Icons.info_outline,
          child: Text(
            data.recommendation(
              booking.visitorCount,
              usesGeofence:
              booking.slot.usesGeofence,
            ),
            style:
            const TextStyle(
              height: 1.5,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(
          height: 20,
        ),

        // ======================================================
        // OPEN QR CODE
        //
        // ONLY STAFF SCAN ATTRACTIONS
        // ======================================================

        if (booking.slot
            .usesStaffScan) ...[
          FilledButton.icon(
            onPressed: () {
              _openPage(
                BookingQrPage.routeName,
              );
            },
            style:
            FilledButton.styleFrom(
              backgroundColor:
              const Color(
                0xFF79571E,
              ),
              foregroundColor:
              Colors.white,
              padding:
              const EdgeInsets.symmetric(
                vertical: 15,
              ),
            ),
            icon:
            const Icon(
              Icons.qr_code_2_rounded,
            ),
            label:
            const Text(
              'Open QR Code',
            ),
          ),

          const SizedBox(
            height: 10,
          ),
        ],

        // ======================================================
        // VIEW GEOFENCE / MAP
        //
        // BOTH GEOFENCE AND STAFF SCAN
        // ======================================================

        OutlinedButton.icon(
          onPressed: () {
            _openPage(
              GeofencePage.routeName,
            );
          },
          style:
          OutlinedButton.styleFrom(
            foregroundColor:
            const Color(
              0xFF79571E,
            ),
            padding:
            const EdgeInsets.symmetric(
              vertical: 15,
            ),
          ),
          icon:
          const Icon(
            Icons.location_on_outlined,
          ),
          label:
          const Text(
            'View Geofence',
          ),
        ),

        const SizedBox(
          height: 20,
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final data = _data;

    return Scaffold(
      backgroundColor:
      const Color(
        0xFFFAF8FF,
      ),

      // ========================================================
      // APP BAR
      //
      // No Refresh button
      // No Loading icon
      // ========================================================

      appBar: AppBar(
        title:
        const Text(
          'Capacity Alert',
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: _booking == null
          ? const Center(
        child: Padding(
          padding:
          EdgeInsets.all(
            24,
          ),
          child: Text(
            'Open Capacity Alert from your booking details.',
            textAlign:
            TextAlign.center,
          ),
        ),
      )
          : data == null &&
          _error == null
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : RefreshIndicator(
        // =============================================
        // PULL DOWN REFRESH
        // =============================================

        onRefresh:
        _refresh,

        child: ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),

          padding:
          const EdgeInsets.all(
            18,
          ),

          children: [
            Center(
              child:
              ConstrainedBox(
                constraints:
                const BoxConstraints(
                  maxWidth: 760,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.stretch,
                  children: [
                    // =================================
                    // ERROR
                    // =================================

                    if (_error !=
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
                            0xFFFFF3CD,
                          ),
                          borderRadius:
                          BorderRadius.circular(
                            12,
                          ),
                        ),
                        child:
                        Column(
                          children: [
                            Text(
                              _error!,
                              textAlign:
                              TextAlign.center,
                              style:
                              const TextStyle(
                                color:
                                Color(
                                  0xFF92400E,
                                ),
                              ),
                            ),

                            TextButton(
                              onPressed:
                              _loading
                                  ? null
                                  : () {
                                _refresh();
                              },
                              child:
                              const Text(
                                'Try again',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),
                    ],

                    if (data !=
                        null)
                      _buildContent(
                        data,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// INFORMATION CARD
// ============================================================

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        side:
        const BorderSide(
          color:
          Color(
            0xFFE5E2DC,
          ),
        ),
      ),
      child: Padding(
        padding:
        const EdgeInsets.all(
          18,
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 21,
                  color:
                  const Color(
                    0xFF79571E,
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                Expanded(
                  child: Text(
                    title,
                    style:
                    const TextStyle(
                      color:
                      Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            child,
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CAPACITY DATA
// ============================================================

class _CapacityData {
  const _CapacityData({
    required this.attractionName,
    required this.locationName,
    required this.maximumCapacity,
    required this.currentVisitors,
    required this.updatedAt,
    this.coverImageUrl,
  });

  final String attractionName;
  final String locationName;
  final String? coverImageUrl;

  final int maximumCapacity;
  final int currentVisitors;

  final DateTime updatedAt;

  // ============================================================
  // AVAILABLE CAPACITY
  // ============================================================

  int get availableCapacity =>
      (maximumCapacity - currentVisitors)
          .clamp(
        0,
        maximumCapacity,
      )
          .toInt();

  // ============================================================
  // OCCUPANCY
  // ============================================================

  double get occupancy =>
      maximumCapacity > 0
          ? currentVisitors /
          maximumCapacity
          : 0;

  // ============================================================
  // CROWD LEVEL
  // ============================================================

  String get levelLabel {
    if (maximumCapacity <= 0) {
      return 'UNAVAILABLE';
    }

    if (currentVisitors >=
        maximumCapacity) {
      return 'FULL';
    }

    if (occupancy >= 0.8) {
      return 'HIGH';
    }

    if (occupancy >= 0.5) {
      return 'MODERATE';
    }

    return 'LOW';
  }

  // ============================================================
  // CROWD LEVEL COLOR
  // ============================================================

  Color get levelColor {
    if (maximumCapacity <= 0) {
      return Colors.grey;
    }

    if (occupancy >= 1) {
      return const Color(
        0xFFB91C1C,
      );
    }

    if (occupancy >= 0.8) {
      return const Color(
        0xFFC2410C,
      );
    }

    if (occupancy >= 0.5) {
      return const Color(
        0xFFB77900,
      );
    }

    return const Color(
      0xFF15803D,
    );
  }

  // ============================================================
  // ENTRY RECOMMENDATION
  //
  // LOW:
  // Good time to visit
  //
  // MODERATE:
  // Moderate crowd
  //
  // HIGH:
  // Consider visiting later
  //
  // FULL:
  // Please wait before entering
  // ============================================================

  String get entryRecommendation {
    if (maximumCapacity <= 0) {
      return 'Capacity information unavailable';
    }

    if (currentVisitors >=
        maximumCapacity) {
      return 'Please wait before entering';
    }

    if (occupancy >= 0.8) {
      return 'Consider visiting later';
    }

    if (occupancy >= 0.5) {
      return 'Moderate crowd';
    }

    return 'Good time to visit';
  }

  // ============================================================
  // ENTRY RECOMMENDATION COLOR
  // ============================================================

  Color get entryRecommendationColor {
    if (maximumCapacity <= 0) {
      return Colors.grey;
    }

    if (currentVisitors >=
        maximumCapacity) {
      return const Color(
        0xFFB91C1C,
      );
    }

    if (occupancy >= 0.8) {
      return const Color(
        0xFFC2410C,
      );
    }

    if (occupancy >= 0.5) {
      return const Color(
        0xFFB77900,
      );
    }

    return const Color(
      0xFF15803D,
    );
  }

  // ============================================================
  // ENTRY RECOMMENDATION ICON
  // ============================================================

  IconData get entryRecommendationIcon {
    if (maximumCapacity <= 0) {
      return Icons.help_outline_rounded;
    }

    if (currentVisitors >=
        maximumCapacity) {
      return Icons.block_rounded;
    }

    if (occupancy >= 0.8) {
      return Icons.schedule_rounded;
    }

    if (occupancy >= 0.5) {
      return Icons.groups_rounded;
    }

    return Icons.check_circle_outline_rounded;
  }

  // ============================================================
  // DETAILED RECOMMENDATION
  // ============================================================

  String recommendation(
      int partySize, {
        required bool usesGeofence,
      }) {
    if (maximumCapacity <= 0) {
      return 'Capacity information is unavailable. '
          'Please contact attraction staff.';
    }

    if (availableCapacity < partySize) {
      return 'There is currently insufficient capacity for your party. '
          'Please wait and check the capacity again before entering.';
    }

    if (occupancy >= 0.8) {
      return 'The attraction is currently busy. '
          'Consider waiting until the crowd level decreases.';
    }

    if (usesGeofence) {
      return 'There is currently enough capacity for your party. '
          'Entry depends on your booking time and automatic geofence validation.';
    }

    return 'There is currently enough capacity for your party. '
        'Entry depends on your booking time and staff QR verification.';
  }

  // ============================================================
  // FROM MAP
  // ============================================================

  factory _CapacityData.fromMap(
      Map<String, dynamic> map,
      ) {
    final maximumCapacity =
    (map['maximum_capacity'] as num)
        .toInt();

    final currentVisitors =
    (map['current_visitors'] as num)
        .toInt();

    if (maximumCapacity < 0 ||
        currentVisitors < 0) {
      throw const FormatException(
        'Invalid capacity values.',
      );
    }

    return _CapacityData(
      attractionName:
      map['attraction_name']
      as String,

      locationName:
      map['location_name']
      as String? ??
          '',

      coverImageUrl:
      map['cover_image_url']
      as String?,

      maximumCapacity:
      maximumCapacity,

      currentVisitors:
      currentVisitors,

      updatedAt:
      DateTime.parse(
        map['updated_at']
        as String,
      ).toLocal(),
    );
  }
}