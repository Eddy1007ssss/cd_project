import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/module3_models.dart';
import '../../repositories/module3_repository.dart';

class BookingQrPage extends StatefulWidget {
  const BookingQrPage({
    super.key,
  });

  static const routeName = '/booking-qr';

  @override
  State<BookingQrPage> createState() =>
      _BookingQrPageState();
}

class _BookingQrPageState extends State<BookingQrPage>
    with WidgetsBindingObserver {
  final _repository = Module3Repository();

  static const double _qrAccessRadiusM = 10.0;

  Timer? _timer;

  TourBooking? _booking;

  bool _initialized = false;
  bool _refreshing = false;
  bool _foreground = true;

  bool _checkingLocation = false;
  bool _locationVerified = false;

  double? _distanceM;

  String? _error;
  String? _locationError;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(
      this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) {
      return;
    }

    _initialized = true;

    final arguments =
        ModalRoute.of(context)?.settings.arguments;

    if (arguments is! TourBooking) {
      return;
    }

    _booking = arguments;

    WidgetsBinding.instance.addPostFrameCallback(
          (_) async {
        if (!mounted) {
          return;
        }

        await _refresh();

        if (!mounted) {
          return;
        }

        if (_booking?.slot.usesStaffScan == true) {
          await _checkLocation();
        }

        if (!mounted) {
          return;
        }

        _startTimer();
      },
    );
  }

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state,
      ) {
    _foreground =
        state == AppLifecycleState.resumed;

    if (_foreground) {
      if (ModalRoute.of(context)?.isCurrent == true) {
        _refresh();

        if (_booking?.slot.usesStaffScan == true) {
          _checkLocation();
        }
      }

      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();

    WidgetsBinding.instance.removeObserver(
      this,
    );

    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();

    if (!_foreground ||
        _booking == null) {
      return;
    }

    _timer = Timer.periodic(
      const Duration(
        seconds: 3,
      ),
          (_) {
        if (!mounted ||
            !_foreground) {
          return;
        }

        if (ModalRoute.of(context)?.isCurrent != true) {
          return;
        }

        _refresh();
      },
    );
  }

  bool _finished(
      TourBooking booking,
      ) {
    return booking.isCompleted ||
        booking.isCheckedOut;
  }

  String _status(
      TourBooking booking,
      ) {
    if (_finished(booking)) {
      return 'Completed';
    }

    if (booking.isCheckedIn) {
      return 'Checked In';
    }

    if (booking.isCancelled) {
      return 'Cancelled';
    }

    return 'Confirmed';
  }

  Color _statusColor(
      TourBooking booking,
      ) {
    if (_finished(booking)) {
      return const Color(
        0xFF2563EB,
      );
    }

    if (booking.isCheckedIn) {
      return const Color(
        0xFF15803D,
      );
    }

    if (booking.isCancelled) {
      return const Color(
        0xFFB91C1C,
      );
    }

    return const Color(
      0xFF79571E,
    );
  }

  String _instructions(
      TourBooking booking,
      ) {
    if (_finished(booking)) {
      return 'This visit is completed. '
          'The QR code is retained as your booking reference.';
    }

    if (booking.isCancelled &&
        !booking.isCheckedIn) {
      return 'This booking is cancelled. '
          'The QR code cannot be used for entry.';
    }

    if (booking.slot.usesGeofence) {
      return booking.isCheckedIn
          ? 'You are currently checked in. '
          'This ticket uses location-based check-out.'
          : 'This is a location-based ticket. '
          'The QR code is retained as your booking reference.';
    }

    if (booking.slot.usesStaffScan) {
      return booking.isCheckedIn
          ? 'Present this QR code to Staff for check-out.'
          : 'Present this QR code to Staff for check-in.';
    }

    return 'The entry method is unavailable.';
  }

  Future<void> _refresh() async {
    final previous =
        _booking;

    if (!mounted ||
        !_foreground ||
        previous == null ||
        _refreshing) {
      return;
    }

    _refreshing = true;

    try {
      final updated =
      await _repository.fetchBooking(
        previous.id,
      );

      if (!mounted) {
        return;
      }

      final justCompleted =
          !_finished(previous) &&
              _finished(updated);

      final justCheckedIn =
          !previous.hasCheckedIn &&
              updated.isCheckedIn &&
              !_finished(updated);

      setState(() {
        _booking = updated;
        _error = null;
      });

      if (_foreground &&
          ModalRoute.of(context)?.isCurrent == true) {
        if (justCompleted) {
          _message(
            'Check-Out Successful. Your booking is completed.',
          );
        } else if (justCheckedIn) {
          _message(
            'Check-In Successful',
          );
        }
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error =
        'Unable to refresh. The displayed status may be out of date.';
      });
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _checkLocation() async {
    final booking =
        _booking;

    if (booking == null ||
        !booking.slot.usesStaffScan ||
        _checkingLocation) {
      return;
    }

    final attractionLatitude =
        booking.slot.latitude;

    final attractionLongitude =
        booking.slot.longitude;

    if (attractionLatitude == null ||
        attractionLongitude == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _locationVerified = false;
        _distanceM = null;
        _locationError =
        'Attraction location is unavailable.';
      });

      return;
    }

    setState(() {
      _checkingLocation = true;
      _locationError = null;
    });

    try {
      final serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'Please enable location services to access your QR code.',
        );
      }

      var permission =
      await Geolocator.checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
        await Geolocator.requestPermission();
      }

      if (permission ==
          LocationPermission.denied) {
        throw Exception(
          'Location permission is required to access your QR code.',
        );
      }

      if (permission ==
          LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is permanently denied. '
              'Please enable it in your device settings.',
        );
      }

      final position =
      await Geolocator.getCurrentPosition(
        locationSettings:
        const LocationSettings(
          accuracy:
          LocationAccuracy.high,
        ),
      );

      final distance =
      Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        attractionLatitude,
        attractionLongitude,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _distanceM = distance;

        _locationVerified =
            distance <= _qrAccessRadiusM;

        _locationError = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _locationVerified = false;
        _distanceM = null;

        _locationError = error
            .toString()
            .replaceFirst(
          'Exception: ',
          '',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _checkingLocation = false;
        });
      }
    }
  }

  Future<void> _pullRefresh() async {
    await _refresh();

    if (!mounted) {
      return;
    }

    if (_booking?.slot.usesStaffScan == true) {
      await _checkLocation();
    }
  }

  void _message(
      String text,
      ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            text,
          ),
        ),
      );
  }

  String _distanceText() {
    final distance =
        _distanceM;

    if (distance == null) {
      return '';
    }

    if (distance < 1000) {
      return '${distance.toStringAsFixed(1)} m from attraction';
    }

    return '${(distance / 1000).toStringAsFixed(2)} km from attraction';
  }

  Widget _locationCard(
      TourBooking booking,
      ) {
    if (_checkingLocation) {
      return Container(
        width: double.infinity,
        padding:
        const EdgeInsets.all(
          16,
        ),
        decoration: BoxDecoration(
          color: const Color(
            0xFFFFF7EA,
          ),
          borderRadius:
          BorderRadius.circular(
            14,
          ),
        ),
        child: const Column(
          children: [
            SizedBox.square(
              dimension: 24,
              child:
              CircularProgressIndicator(
                strokeWidth: 2.5,
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              'Checking your location...',
              style: TextStyle(
                fontWeight:
                FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    if (_locationVerified) {
      return Container(
        width: double.infinity,
        padding:
        const EdgeInsets.all(
          16,
        ),
        decoration: BoxDecoration(
          color: const Color(
            0xFFEFF8F0,
          ),
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          border: Border.all(
            color: const Color(
              0xFFB7D8BD,
            ),
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons
                  .check_circle_rounded,
              color: Color(
                0xFF15803D,
              ),
              size: 34,
            ),
            const SizedBox(
              height: 8,
            ),
            const Text(
              'Location Verified',
              style: TextStyle(
                color: Color(
                  0xFF15803D,
                ),
                fontSize: 16,
                fontWeight:
                FontWeight.w800,
              ),
            ),
            if (_distanceM != null) ...[
              const SizedBox(
                height: 5,
              ),
              Text(
                _distanceText(),
                style:
                const TextStyle(
                  color: Color(
                    0xFF4B5563,
                  ),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFFFFF4E5,
        ),
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color: const Color(
            0xFFF5C27A,
          ),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.location_off_outlined,
            color: Color(
              0xFFB45309,
            ),
            size: 34,
          ),
          const SizedBox(
            height: 8,
          ),
          const Text(
            'Move Closer to the Attraction',
            textAlign:
            TextAlign.center,
            style: TextStyle(
              color: Color(
                0xFFB45309,
              ),
              fontSize: 16,
              fontWeight:
              FontWeight.w800,
            ),
          ),
          const SizedBox(
            height: 7,
          ),
          const Text(
            'You must be within 10 metres of the attraction '
                'to access your QR code.',
            textAlign:
            TextAlign.center,
            style: TextStyle(
              height: 1.4,
            ),
          ),
          if (_distanceM != null) ...[
            const SizedBox(
              height: 8,
            ),
            Text(
              _distanceText(),
              style:
              const TextStyle(
                color: Color(
                  0xFF6B7280,
                ),
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ],
          if (_locationError != null) ...[
            const SizedBox(
              height: 8,
            ),
            Text(
              _locationError!,
              textAlign:
              TextAlign.center,
              style:
              const TextStyle(
                color: Color(
                  0xFFB45309,
                ),
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(
            height: 14,
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
              _checkingLocation
                  ? null
                  : _checkLocation,
              icon: const Icon(
                Icons
                    .my_location_rounded,
              ),
              label: const Text(
                'Check Location Again',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeRow(
      String label,
      DateTime value,
      ) {
    final local =
    value.toLocal();

    return Padding(
      padding:
      const EdgeInsets.only(
        top: 10,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
            ),
          ),
          Expanded(
            child: Text(
              '${shortDate(local)} '
                  '${clockTime(local)}',
              style:
              const TextStyle(
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final booking =
        _booking;

    if (booking == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Booking Ticket',
          ),
        ),
        body: const Center(
          child: Text(
            'Booking ticket is missing.',
          ),
        ),
      );
    }

    final color =
    _statusColor(
      booking,
    );

    final requiresLocation =
        booking.slot.usesStaffScan &&
            !_finished(booking) &&
            !booking.isCancelled;

    final showQr =
        !requiresLocation ||
            _locationVerified;

    return Scaffold(
      backgroundColor:
      const Color(
        0xFFFAF8FF,
      ),
      appBar: AppBar(
        title: const Text(
          'Booking Ticket',
        ),
      ),
      body: RefreshIndicator(
        onRefresh:
        _pullRefresh,
        child: ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding:
          const EdgeInsets.all(
            24,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints:
                const BoxConstraints(
                  maxWidth: 480,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      color:
                      Colors.white,
                      child: Padding(
                        padding:
                        const EdgeInsets.all(
                          24,
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                          children: [
                            Icon(
                              booking.slot.usesGeofence
                                  ? Icons
                                  .location_on_outlined
                                  : Icons
                                  .qr_code_2_rounded,
                              color:
                              const Color(
                                0xFF79571E,
                              ),
                              size: 34,
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            Text(
                              booking.slot
                                  .ticketTypeLabel,
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
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(
                              height: 16,
                            ),
                            Text(
                              booking.slot
                                  .attractionName,
                              textAlign:
                              TextAlign.center,
                              style:
                              const TextStyle(
                                fontSize: 20,
                                fontWeight:
                                FontWeight.w800,
                              ),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            Text(
                              '${shortDate(booking.slot.startsAt)} '
                                  '· ${slotTime(booking.slot)}',
                              textAlign:
                              TextAlign.center,
                            ),
                            const SizedBox(
                              height: 6,
                            ),
                            Text(
                              '${booking.visitorCount} visitor(s)',
                              textAlign:
                              TextAlign.center,
                              style:
                              const TextStyle(
                                color:
                                Colors.black54,
                              ),
                            ),
                            const SizedBox(
                              height: 18,
                            ),
                            Container(
                              padding:
                              const EdgeInsets.all(
                                12,
                              ),
                              decoration:
                              BoxDecoration(
                                color:
                                color.withAlpha(
                                  20,
                                ),
                                borderRadius:
                                BorderRadius.circular(
                                  12,
                                ),
                              ),
                              child: Text(
                                _status(
                                  booking,
                                ),
                                key:
                                const Key(
                                  'tourist-booking-status',
                                ),
                                textAlign:
                                TextAlign.center,
                                style:
                                TextStyle(
                                  color:
                                  color,
                                  fontSize:
                                  18,
                                  fontWeight:
                                  FontWeight.w800,
                                ),
                              ),
                            ),
                            if (requiresLocation) ...[
                              const SizedBox(
                                height: 20,
                              ),
                              _locationCard(
                                booking,
                              ),
                            ],
                            if (showQr) ...[
                              const SizedBox(
                                height: 20,
                              ),
                              Center(
                                child: SizedBox(
                                  width: 230,
                                  child:
                                  AspectRatio(
                                    aspectRatio:
                                    1,
                                    child:
                                    QrImageView(
                                      data:
                                      booking.qrToken,
                                      backgroundColor:
                                      Colors.white,
                                      padding:
                                      const EdgeInsets.all(
                                        16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(
                              height: 12,
                            ),
                            const Text(
                              'Booking Code',
                              textAlign:
                              TextAlign.center,
                              style:
                              TextStyle(
                                color:
                                Colors.black54,
                                fontSize:
                                12,
                              ),
                            ),
                            const SizedBox(
                              height: 6,
                            ),
                            SelectableText(
                              booking.bookingCode,
                              textAlign:
                              TextAlign.center,
                              style:
                              const TextStyle(
                                fontWeight:
                                FontWeight.w800,
                                letterSpacing:
                                1,
                              ),
                            ),
                            const SizedBox(
                              height: 16,
                            ),
                            Text(
                              showQr
                                  ? _instructions(
                                booking,
                              )
                                  : 'Move within 10 metres of the attraction '
                                  'to access your QR code.',
                              textAlign:
                              TextAlign.center,
                              style:
                              const TextStyle(
                                height: 1.5,
                              ),
                            ),
                            if (booking.checkedInAt != null ||
                                booking.checkedOutAt != null) ...[
                              const Divider(
                                height: 28,
                              ),
                              if (booking.checkedInAt != null)
                                _timeRow(
                                  'Check-in',
                                  booking.checkedInAt!,
                                ),
                              if (booking.checkedOutAt != null)
                                _timeRow(
                                  'Check-out',
                                  booking.checkedOutAt!,
                                ),
                            ],
                            if (booking.canSubmitFeedback) ...[
                              const SizedBox(
                                height: 16,
                              ),
                              const Text(
                                'You can now submit feedback '
                                    'from the Feedback page.',
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
                          ],
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(
                        height: 12,
                      ),
                      Text(
                        _error!,
                        textAlign:
                        TextAlign.center,
                        style:
                        const TextStyle(
                          color:
                          Color(
                            0xFFB45309,
                          ),
                        ),
                      ),
                    ],
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