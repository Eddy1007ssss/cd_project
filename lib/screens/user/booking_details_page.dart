import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/module3_models.dart';
import '../../repositories/module3_repository.dart';
import '../../services/geofence_service.dart';
import 'booking_qr_page.dart';
import 'capacity_alert_page.dart';
import 'geofence_page.dart';
import 'reschedule_booking_page.dart';

class BookingDetailsPage extends StatefulWidget {
  const BookingDetailsPage({super.key});

  static const routeName = '/booking-details';

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage>
    with WidgetsBindingObserver {
  final _repository = Module3Repository();
  final _geofenceService = GeofenceService();

  Timer? _timer;
  TourBooking? _booking;

  bool _initialized = false;
  bool _busy = false;
  bool _refreshing = false;
  bool _foreground = true;
  bool _hasFreshData = false;

  bool _geofenceMonitoring = false;
  String? _monitoredBookingId;

  String _geofenceStatus = 'Preparing automatic Geofence...';
  double? _geofenceDistance;
  int? _geofenceSecondsRemaining;
  String? _geofenceError;

  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;
    _initialized = true;

    final arguments = ModalRoute.of(context)?.settings.arguments;

    if (arguments is! TourBooking) return;

    _booking = arguments;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await _refresh(notify: false);

      if (!mounted) return;

      _startTimer();
      await _ensureGeofenceMonitoring();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;

    if (_foreground) {
      if (ModalRoute.of(context)?.isCurrent == true) {
        _refresh(notify: false);
      }

      _startTimer();
      _ensureGeofenceMonitoring();
    } else {
      _timer?.cancel();

      // Do not stop GeofenceService here.
      // The service is shared across pages.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();

    // Only detach this page from Geofence UI callbacks.
    // Do NOT stop the shared Geofence timer.
    _geofenceService.detachCallbacks();

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  // ============================================================
  // NORMAL BOOKING REFRESH
  // ============================================================

  void _startTimer() {
    _timer?.cancel();

    if (!_foreground || _booking == null) return;

    _timer = Timer.periodic(
      const Duration(seconds: 3),
          (_) {
        if (!mounted || !_foreground) return;
        if (ModalRoute.of(context)?.isCurrent != true) return;

        _refresh();
      },
    );
  }

  bool _finished(TourBooking booking) =>
      booking.isCompleted || booking.isCheckedOut;

  bool _editable(TourBooking booking) =>
      booking.isUpcoming &&
          !booking.hasCheckedIn &&
          !_finished(booking);

  bool _activeConfirmed(TourBooking booking) =>
      booking.status == BookingStatus.confirmed &&
          !booking.hasCheckedIn &&
          !booking.isCheckedOut &&
          !booking.slot.endsAt.isBefore(DateTime.now());

  bool _shouldMonitorGeofence(TourBooking booking) {
    if (!booking.slot.usesGeofence) {
      return false;
    }

    if (booking.isCancelled || _finished(booking)) {
      return false;
    }

    if (booking.hasCheckedIn && !booking.isCheckedOut) {
      return true;
    }

    if (booking.status != BookingStatus.confirmed) {
      return false;
    }

    final now = DateTime.now();

    final earliest =
    booking.slot.startsAt.subtract(
      const Duration(minutes: 30),
    );

    return !now.isBefore(earliest) &&
        !now.isAfter(booking.slot.endsAt);
  }

  String _statusLabel(TourBooking booking) {
    if (_finished(booking)) return 'Completed';
    if (booking.isCheckedIn) return 'Checked In';
    if (booking.isCancelled) return 'Cancelled';

    return 'Confirmed';
  }

  Color _statusColor(TourBooking booking) {
    if (_finished(booking)) {
      return const Color(0xFF2563EB);
    }

    if (booking.isCheckedIn) {
      return const Color(0xFF15803D);
    }

    if (booking.isCancelled) {
      return const Color(0xFFB91C1C);
    }

    return const Color(0xFF79571E);
  }

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
        ),
      );
  }

  void _apply(
      TourBooking updated, {
        bool notify = true,
      }) {
    final previous = _booking;

    final justCompleted =
        previous != null &&
            !_finished(previous) &&
            _finished(updated);

    final justCheckedIn =
        previous != null &&
            !previous.hasCheckedIn &&
            updated.isCheckedIn &&
            !_finished(updated);

    setState(() {
      _booking = updated;
      _hasFreshData = true;
      _error = null;

      if (updated.slot.usesGeofence &&
          _finished(updated)) {
        _geofenceStatus = 'Visit completed';
        _geofenceSecondsRemaining = null;
      }
    });

    if (updated.slot.usesGeofence) {
      if (_finished(updated) ||
          updated.isCancelled) {
        _geofenceMonitoring = false;
        _monitoredBookingId = null;
      } else {
        _ensureGeofenceMonitoring();
      }
    }

    if (!notify ||
        !_foreground ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }

    if (justCompleted) {
      _message(
        'Check-Out Successful. Your booking is completed.',
      );
    } else if (justCheckedIn) {
      _message('Check-In Successful');
    }
  }

  Future<void> _refresh({
    bool notify = true,
  }) async {
    final booking = _booking;

    if (!mounted ||
        !_foreground ||
        booking == null ||
        _busy ||
        _refreshing) {
      return;
    }

    setState(() {
      _refreshing = true;
    });

    try {
      final updated =
      await _repository.fetchBooking(
        booking.id,
      );

      if (!mounted) return;

      _apply(
        updated,
        notify: notify,
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _hasFreshData = false;
        _error =
        'Unable to refresh. The displayed information may be out of date.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _refreshing = false;
        });
      }
    }
  }

  // ============================================================
  // AUTOMATIC GEOFENCE
  // ============================================================

  Future<void> _ensureGeofenceMonitoring() async {
    final booking = _booking;

    if (!mounted ||
        !_foreground ||
        booking == null ||
        !booking.slot.usesGeofence) {
      return;
    }

    if (!_shouldMonitorGeofence(booking)) {
      if (!mounted) return;

      if (_finished(booking)) {
        setState(() {
          _geofenceStatus = 'Visit completed';
          _geofenceSecondsRemaining = null;
        });

        return;
      }

      if (booking.isCancelled) {
        setState(() {
          _geofenceStatus = 'Booking cancelled';
          _geofenceSecondsRemaining = null;
        });

        return;
      }

      final earliest =
      booking.slot.startsAt.subtract(
        const Duration(minutes: 30),
      );

      if (DateTime.now().isBefore(earliest)) {
        setState(() {
          _geofenceStatus =
          'Automatic Geofence will start 30 minutes before your booking.';
          _geofenceSecondsRemaining = null;
        });
      }

      return;
    }

    if (_geofenceMonitoring &&
        _monitoredBookingId == booking.id) {
      return;
    }

    _geofenceMonitoring = true;
    _monitoredBookingId = booking.id;

    setState(() {
      _geofenceStatus = booking.hasCheckedIn
          ? 'Automatic Check-Out monitoring active'
          : 'Automatic Check-In monitoring active';

      _geofenceError = null;
    });

    await _geofenceService.startMonitoring(
      bookingId: booking.id,

      onUpdate: (update) {
        if (!mounted) return;

        setState(() {
          _geofenceStatus = update.message;
          _geofenceDistance = update.distanceM;
          _geofenceSecondsRemaining =
              update.secondsRemaining;
          _geofenceError = null;
        });
      },

      onCheckedIn: () async {
        final currentBooking = _booking;

        if (!mounted ||
            currentBooking == null) {
          return;
        }

        try {
          final updated =
          await _repository.fetchBooking(
            currentBooking.id,
          );

          if (!mounted) return;

          _apply(
            updated,
            notify: false,
          );

          _message(
            'Automatic Geofence Check-In Successful',
          );
        } catch (_) {
          if (!mounted) return;

          _message(
            'Check-in succeeded, but booking refresh failed.',
          );
        }
      },

      onCheckedOut: () async {
        final currentBooking = _booking;

        if (!mounted ||
            currentBooking == null) {
          return;
        }

        try {
          final updated =
          await _repository.fetchBooking(
            currentBooking.id,
          );

          if (!mounted) return;

          _apply(
            updated,
            notify: false,
          );

          _message(
            'Automatic Geofence Check-Out Successful',
          );
        } catch (_) {
          if (!mounted) return;

          _message(
            'Check-out succeeded, but booking refresh failed.',
          );
        }
      },

      onError: (error) {
        if (!mounted) return;

        setState(() {
          _geofenceError =
              error.toString();
        });
      },
    );
  }

  // ============================================================
  // OPEN QR
  // ============================================================

  Future<void> _openQr() async {
    final booking = _booking;

    if (booking == null || _busy) return;

    await Navigator.pushNamed(
      context,
      BookingQrPage.routeName,
      arguments: booking,
    );

    if (mounted) {
      await _refresh(
        notify: false,
      );
    }
  }

  // ============================================================
  // CAPACITY ALERT
  // ============================================================

  Future<void> _openCapacity() async {
    final booking = _booking;

    if (booking == null ||
        _busy ||
        _refreshing ||
        !_hasFreshData) {
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      final latest =
      await _repository.fetchBooking(
        booking.id,
      );

      if (!mounted) return;

      _apply(latest);

      if (!_activeConfirmed(latest)) {
        _message(
          'Capacity Alert is available for active, confirmed bookings.',
        );
        return;
      }

      await Navigator.pushNamed(
        context,
        CapacityAlertPage.routeName,
        arguments: latest,
      );
    } catch (_) {
      if (mounted) {
        _message(
          'Unable to open Capacity Alert. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }

    if (mounted) {
      await _refresh(
        notify: false,
      );
    }
  }

  // ============================================================
  // VIEW GEOFENCE / ATTRACTION MAP
  // ============================================================

  Future<void> _openGeofence() async {
    final booking = _booking;

    if (booking == null || _busy) return;

    await Navigator.pushNamed(
      context,
      GeofencePage.routeName,
      arguments: booking,
    );

    if (mounted) {
      await _refresh(
        notify: false,
      );
    }
  }

  // ============================================================
  // RESCHEDULE
  // ============================================================

  Future<void> _reschedule() async {
    final booking = _booking;

    if (booking == null ||
        _busy ||
        _refreshing ||
        !_hasFreshData ||
        !_editable(booking)) {
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      final latest =
      await _repository.fetchBooking(
        booking.id,
      );

      if (!mounted) return;

      _apply(latest);

      if (!_editable(latest)) {
        _message(
          'This booking can no longer be rescheduled.',
        );
        return;
      }

      final result =
      await Navigator.pushNamed(
        context,
        RescheduleBookingPage.routeName,
        arguments: latest,
      );

      if (!mounted) return;

      if (result is TourBooking) {
        _apply(
          result,
          notify: false,
        );
      }
    } catch (error) {
      if (mounted) {
        _message(
          bookingErrorMessage(error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }

    if (mounted) {
      await _refresh(
        notify: false,
      );
    }
  }

  // ============================================================
  // CANCEL
  // ============================================================

  Future<void> _cancel() async {
    final booking = _booking;

    if (booking == null ||
        _busy ||
        _refreshing ||
        !_hasFreshData ||
        !_editable(booking)) {
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      final confirmed =
      await showDialog<bool>(
        context: context,
        builder:
            (dialogContext) =>
            AlertDialog(
              title: const Text(
                'Cancel booking?',
              ),
              content: const Text(
                'The reserved spaces will be released immediately. '
                    'This cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(
                        dialogContext,
                        false,
                      ),
                  child: const Text(
                    'Keep booking',
                  ),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(
                        dialogContext,
                        true,
                      ),
                  child: const Text(
                    'Cancel booking',
                  ),
                ),
              ],
            ),
      );

      if (!mounted ||
          confirmed != true) {
        return;
      }

      final latest =
      await _repository.fetchBooking(
        booking.id,
      );

      if (!mounted) return;

      _apply(latest);

      if (!_editable(latest)) {
        _message(
          'This booking can no longer be cancelled.',
        );
        return;
      }

      final updated =
      await _repository.cancelBooking(
        booking.id,
      );

      if (!mounted) return;

      _apply(
        updated,
        notify: false,
      );

      _message(
        'Booking cancelled.',
      );
    } catch (error) {
      if (mounted) {
        _message(
          bookingErrorMessage(error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  String _dateTime(DateTime value) {
    final local = value.toLocal();

    return '${shortDate(local)} ${clockTime(local)}';
  }

  String _distanceText() {
    final distance =
        _geofenceDistance;

    if (distance == null) {
      return 'Locating...';
    }

    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)} m from attraction';
    }

    return '${(distance / 1000).toStringAsFixed(2)} km from attraction';
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final booking = _booking;

    if (booking == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Booking Details',
          ),
        ),
        body: const Center(
          child: Text(
            'Booking details are missing.',
          ),
        ),
      );
    }

    final finished =
    _finished(booking);

    final disabled =
        _busy ||
            _refreshing ||
            !_hasFreshData;

    return Scaffold(
      backgroundColor:
      const Color(0xFFFAF8FF),

      appBar: AppBar(
        title: const Text(
          'Booking Details',
        ),
        actions: [
          IconButton(
            tooltip:
            'Refresh booking',
            onPressed:
            _busy || _refreshing
                ? null
                : () => _refresh(),
            icon: _refreshing
                ? const SizedBox.square(
              dimension: 18,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () => _refresh(),

        child: ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),

          padding:
          const EdgeInsets.all(18),

          children: [
            if (_error != null) ...[
              Text(
                _error!,
                style:
                const TextStyle(
                  color:
                  Color(0xFFB45309),
                ),
              ),
              const SizedBox(
                height: 12,
              ),
            ],

            // ==================================================
            // BOOKING DETAILS CARD
            // ==================================================

            Card(
              color: Colors.white,

              child: Padding(
                padding:
                const EdgeInsets.all(
                  18,
                ),

                child: Column(
                  children: [
                    Icon(
                      booking.slot
                          .usesGeofence
                          ? Icons
                          .location_on_outlined
                          : Icons
                          .qr_code_2_rounded,
                      size: 46,
                      color:
                      const Color(
                        0xFF79571E,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Text(
                      booking.slot
                          .attractionName,
                      textAlign:
                      TextAlign.center,
                      style:
                      const TextStyle(
                        fontSize: 21,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Container(
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration:
                      BoxDecoration(
                        color:
                        const Color(
                          0xFFFFF4E3,
                        ),
                        borderRadius:
                        BorderRadius
                            .circular(
                          20,
                        ),
                      ),
                      child: Text(
                        booking.slot
                            .ticketTypeLabel,
                        style:
                        const TextStyle(
                          color:
                          Color(
                            0xFF79571E,
                          ),
                          fontWeight:
                          FontWeight
                              .w700,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    SelectableText(
                      booking.bookingCode,
                      textAlign:
                      TextAlign.center,
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

                    const Divider(
                      height: 28,
                    ),

                    _Detail(
                      'Status',
                      _statusLabel(
                        booking,
                      ),
                      color:
                      _statusColor(
                        booking,
                      ),
                    ),

                    _Detail(
                      'Date',
                      shortDate(
                        booking.slot
                            .startsAt,
                      ),
                    ),

                    _Detail(
                      'Time',
                      slotTime(
                        booking.slot,
                      ),
                    ),

                    _Detail(
                      'Visitors',
                      '${booking.visitorCount}',
                    ),

                    _Detail(
                      'Location',
                      booking.slot
                          .locationName,
                    ),

                    _Detail(
                      'Entry Method',
                      booking.slot
                          .usesGeofence
                          ? 'Location-based entry'
                          : booking.slot
                          .usesStaffScan
                          ? 'Staff QR verification'
                          : 'Not available',
                    ),

                    if (booking
                        .checkedInAt !=
                        null)
                      _Detail(
                        'Check-in',
                        _dateTime(
                          booking
                              .checkedInAt!,
                        ),
                      ),

                    if (booking
                        .checkedOutAt !=
                        null)
                      _Detail(
                        'Check-out',
                        _dateTime(
                          booking
                              .checkedOutAt!,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // ==================================================
            // AUTOMATIC GEOFENCE STATUS
            // ==================================================

            if (booking.slot
                .usesGeofence &&
                !booking
                    .isCancelled)
              Container(
                padding:
                const EdgeInsets.all(
                  16,
                ),
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFEFF8F0,
                  ),
                  borderRadius:
                  BorderRadius
                      .circular(
                    14,
                  ),
                  border:
                  Border.all(
                    color:
                    const Color(
                      0xFFB7D8BD,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons
                              .my_location_rounded,
                          color:
                          Color(
                            0xFF15803D,
                          ),
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        Text(
                          'Automatic Geofence',
                          style:
                          TextStyle(
                            fontSize:
                            16,
                            fontWeight:
                            FontWeight
                                .w800,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    Text(
                      _geofenceStatus,
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight
                            .w700,
                      ),
                    ),

                    if (!finished) ...[
                      const SizedBox(
                        height: 6,
                      ),

                      Text(
                        _distanceText(),
                        style:
                        const TextStyle(
                          color:
                          Color(
                            0xFF4B5563,
                          ),
                        ),
                      ),
                    ],

                    if (_geofenceSecondsRemaining !=
                        null) ...[
                      const SizedBox(
                        height: 8,
                      ),

                      Text(
                        booking.hasCheckedIn
                            ? 'Auto Check-Out in '
                            '${_geofenceSecondsRemaining}s'
                            : 'Auto Check-In in '
                            '${_geofenceSecondsRemaining}s',
                        style:
                        const TextStyle(
                          color:
                          Color(
                            0xFF15803D,
                          ),
                          fontWeight:
                          FontWeight
                              .w800,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      LinearProgressIndicator(
                        value: null,
                        minHeight: 5,
                        borderRadius:
                        BorderRadius
                            .circular(
                          20,
                        ),
                      ),
                    ],

                    if (_geofenceError !=
                        null) ...[
                      const SizedBox(
                        height: 10,
                      ),

                      Text(
                        'Location status: $_geofenceError',
                        style:
                        const TextStyle(
                          color:
                          Color(
                            0xFFB45309,
                          ),
                          fontSize:
                          12,
                        ),
                      ),
                    ],

                    if (!finished) ...[
                      const SizedBox(
                        height: 10,
                      ),

                      const Text(
                        'Keep location permission enabled while using the app.',
                        style:
                        TextStyle(
                          fontSize:
                          12,
                          color:
                          Color(
                            0xFF6B7280,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            if (booking.slot
                .usesGeofence)
              const SizedBox(
                height: 12,
              ),

            // ==================================================
            // STAFF SCAN INFO
            // ==================================================

            if (!finished &&
                !booking.isCancelled &&
                booking.slot
                    .usesStaffScan)
              Container(
                padding:
                const EdgeInsets.all(
                  14,
                ),
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFFFF7EA,
                  ),
                  borderRadius:
                  BorderRadius
                      .circular(
                    12,
                  ),
                ),
                child:
                const Text(
                  'Present your QR code to Staff for '
                      'check-in and check-out.',
                  textAlign:
                  TextAlign.center,
                  style:
                  TextStyle(
                    height: 1.5,
                  ),
                ),
              ),

            if (booking
                .canSubmitFeedback) ...[
              const SizedBox(
                height: 12,
              ),

              const Text(
                'Your booking is completed. '
                    'You can submit feedback from the Feedback page.',
                textAlign:
                TextAlign.center,
                style:
                TextStyle(
                  color:
                  Color(
                    0xFF2563EB,
                  ),
                ),
              ),
            ],

            const SizedBox(
              height: 12,
            ),

            // ==================================================
            // VIEW QR
            // ==================================================

            FilledButton.icon(
              onPressed:
              _busy
                  ? null
                  : _openQr,
              icon:
              const Icon(
                Icons
                    .qr_code_2_rounded,
              ),
              label:
              const Text(
                'View Ticket / QR Code',
              ),
            ),

            // ==================================================
            // CAPACITY ALERT
            // ==================================================

            if (_activeConfirmed(
              booking,
            )) ...[
              const SizedBox(
                height: 8,
              ),

              OutlinedButton.icon(
                onPressed:
                disabled
                    ? null
                    : _openCapacity,
                icon:
                const Icon(
                  Icons
                      .groups_outlined,
                ),
                label:
                const Text(
                  'View Capacity Alert',
                ),
              ),
            ],

            // ==================================================
            // VIEW GEOFENCE / MAP
            // ALL BOOKINGS CAN USE THIS
            // ==================================================

            const SizedBox(
              height: 8,
            ),

            OutlinedButton.icon(
              onPressed:
              _busy
                  ? null
                  : _openGeofence,
              icon:
              const Icon(
                Icons.map_outlined,
              ),
              label:
              const Text(
                'View Geofence',
              ),
            ),

            // ==================================================
            // RESCHEDULE / CANCEL
            // ==================================================

            if (_editable(
              booking,
            )) ...[
              const SizedBox(
                height: 8,
              ),

              OutlinedButton.icon(
                onPressed:
                disabled
                    ? null
                    : _reschedule,
                icon:
                const Icon(
                  Icons
                      .edit_calendar_outlined,
                ),
                label:
                const Text(
                  'Reschedule',
                ),
              ),

              TextButton.icon(
                onPressed:
                disabled
                    ? null
                    : _cancel,
                icon:
                const Icon(
                  Icons
                      .cancel_outlined,
                ),
                label: Text(
                  _busy
                      ? 'Updating...'
                      : 'Cancel booking',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail(
      this.label,
      this.value, {
        this.color,
      });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
              TextStyle(
                color: color,
                fontWeight:
                FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}