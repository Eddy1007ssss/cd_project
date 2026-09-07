import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/module3_models.dart';
import '../../repositories/module3_repository.dart';

class BookingQrPage extends StatefulWidget {
  const BookingQrPage({super.key});

  static const routeName = '/booking-qr';

  @override
  State<BookingQrPage> createState() => _BookingQrPageState();
}

class _BookingQrPageState extends State<BookingQrPage>
    with WidgetsBindingObserver {
  final _repository = Module3Repository();

  Timer? _timer;
  TourBooking? _booking;

  bool _initialized = false;
  bool _refreshing = false;
  bool _foreground = true;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _refresh();
      _startTimer();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;

    if (_foreground) {
      if (ModalRoute.of(context)?.isCurrent == true) {
        _refresh();
      }
      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

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

  String _status(TourBooking booking) {
    if (_finished(booking)) return 'Completed';
    if (booking.isCheckedIn) return 'Checked In';
    if (booking.isCancelled) return 'Cancelled';

    return 'Confirmed';
  }

  Color _statusColor(TourBooking booking) {
    if (_finished(booking)) return const Color(0xFF2563EB);
    if (booking.isCheckedIn) return const Color(0xFF15803D);
    if (booking.isCancelled) return const Color(0xFFB91C1C);

    return const Color(0xFF79571E);
  }

  String _instructions(TourBooking booking) {
    if (_finished(booking)) {
      return 'This visit is completed. '
          'The QR code is retained as your booking reference.';
    }

    if (booking.isCancelled && !booking.isCheckedIn) {
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
          ? 'Present this QR code to Staff '
          'when your whole party leaves.'
          : 'Present this QR code to Staff for check-in.';
    }

    return 'The entry method is unavailable. Please refresh the ticket.';
  }

  Future<void> _refresh() async {
    final previous = _booking;

    if (!mounted ||
        !_foreground ||
        previous == null ||
        _refreshing) {
      return;
    }

    setState(() => _refreshing = true);

    try {
      final updated = await _repository.fetchBooking(previous.id);

      if (!mounted) return;

      final justCompleted =
          !_finished(previous) && _finished(updated);

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
          _message('Check-Out Successful. Your booking is completed.');
        } else if (justCheckedIn) {
          _message('Check-In Successful');
        }
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error =
        'Unable to refresh. The displayed status may be out of date.';
      });
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Widget _timeRow(String label, DateTime value) {
    final local = value.toLocal();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label)),
          Expanded(
            child: Text(
              '${shortDate(local)} ${clockTime(local)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;

    if (booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Ticket')),
        body: const Center(
          child: Text('Booking ticket is missing.'),
        ),
      );
    }

    final color = _statusColor(booking);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        title: const Text('Booking Ticket'),
        actions: [
          IconButton(
            tooltip: 'Refresh ticket',
            onPressed: _refreshing ? null : _refresh,
            icon: _refreshing
                ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(
                            booking.slot.usesGeofence
                                ? Icons.location_on_outlined
                                : Icons.qr_code_2_rounded,
                            color: const Color(0xFF79571E),
                            size: 34,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            booking.slot.ticketTypeLabel,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF79571E),
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            booking.slot.attractionName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${shortDate(booking.slot.startsAt)} '
                                '· ${slotTime(booking.slot)}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${booking.visitorCount} visitor(s)',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _status(booking),
                              key: const Key('tourist-booking-status'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: color,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: SizedBox(
                              width: 230,
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: QrImageView(
                                  data: booking.qrToken,
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.all(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Booking Code',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SelectableText(
                            booking.bookingCode,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _instructions(booking),
                            textAlign: TextAlign.center,
                            style: const TextStyle(height: 1.5),
                          ),
                          if (booking.checkedInAt != null ||
                              booking.checkedOutAt != null) ...[
                            const Divider(height: 28),
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
                            const SizedBox(height: 16),
                            const Text(
                              'You can now submit feedback '
                                  'from the Feedback page.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}