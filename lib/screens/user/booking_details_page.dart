import 'package:flutter/material.dart';

import '../../models/module3_models.dart';
import '../../repositories/module3_repository.dart';
import 'booking_qr_page.dart';
import 'reschedule_booking_page.dart';

class BookingDetailsPage extends StatefulWidget {
  const BookingDetailsPage({super.key});
  static const routeName = '/booking-details';
  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  final _repository = Module3Repository();
  TourBooking? _booking;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _booking ??= ModalRoute.of(context)?.settings.arguments as TourBooking?;
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: const Text(
          'The reserved spaces will be released immediately. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep booking'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    setState(() => _busy = true);
    try {
      final updated = await _repository.cancelBooking(_booking!.id);
      if (mounted) {
        setState(() => _booking = updated);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(bookingErrorMessage(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;
    if (booking == null) {
      return const Scaffold(
        body: Center(child: Text('Booking details are missing.')),
      );
    }
    final editable = booking.isUpcoming;
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Icon(
                    Icons.confirmation_num_outlined,
                    size: 46,
                    color: Color(0xFF79571E),
                  ),
                  Text(
                    booking.slot.attractionName,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    booking.bookingCode,
                    style: const TextStyle(
                      color: Color(0xFF79571E),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Divider(),
                  _Detail('Status', booking.status.name.toUpperCase()),
                  _Detail('Date', shortDate(booking.slot.startsAt)),
                  _Detail('Time', slotTime(booking.slot)),
                  _Detail('Visitors', '${booking.visitorCount}'),
                  _Detail('Location', booking.slot.locationName),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => Navigator.pushNamed(
              context,
              BookingQrPage.routeName,
              arguments: booking,
            ),
            icon: const Icon(Icons.qr_code_2),
            label: const Text('View QR Code'),
          ),
          if (editable) ...[
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      final result = await Navigator.pushNamed(
                        context,
                        RescheduleBookingPage.routeName,
                        arguments: booking,
                      );
                      if (result is TourBooking && mounted) {
                        setState(() => _booking = result);
                      }
                    },
              icon: const Icon(Icons.edit_calendar_outlined),
              label: const Text('Reschedule'),
            ),
            TextButton.icon(
              onPressed: _busy ? null : _cancel,
              icon: const Icon(Icons.cancel_outlined),
              label: Text(_busy ? 'Updating…' : 'Cancel booking'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        SizedBox(width: 90, child: Text(label)),
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
