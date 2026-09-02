import 'package:flutter/material.dart';

import '../../models/module3_models.dart';
import '../../repositories/module3_repository.dart';
import 'booking_confirmation_page.dart';

class BookingReviewArguments {
  const BookingReviewArguments({required this.slot, required this.visitors});
  final AttractionSlot slot;
  final int visitors;
}

class BookingReviewPage extends StatefulWidget {
  const BookingReviewPage({super.key});
  static const routeName = '/booking-review';
  @override
  State<BookingReviewPage> createState() => _BookingReviewPageState();
}

class _BookingReviewPageState extends State<BookingReviewPage> {
  final _repository = Module3Repository();
  bool _submitting = false;
  String? _error;

  Future<void> _confirm(BookingReviewArguments data) async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final booking = await _repository.createBooking(
        slotId: data.slot.id,
        visitors: data.visitors,
      );
      if (!mounted) {
        return;
      }
      Navigator.pushNamedAndRemoveUntil(
        context,
        BookingConfirmationPage.routeName,
        (route) => route.isFirst,
        arguments: booking,
      );
    } catch (error) {
      if (mounted) setState(() => _error = bookingErrorMessage(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ModalRoute.of(context)?.settings.arguments;
    if (data is! BookingReviewArguments) {
      return const Scaffold(
        body: Center(child: Text('Booking details are missing.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Review Booking')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(
            Icons.fact_check_outlined,
            size: 54,
            color: Color(0xFF79571E),
          ),
          Text(
            data.slot.attractionName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _Row('Date', shortDate(data.slot.startsAt)),
                  _Row('Time', slotTime(data.slot)),
                  _Row('Location', data.slot.locationName),
                  _Row('Visitors', '${data.visitors}'),
                  _Row(
                    'Capacity',
                    '${data.slot.remainingCapacity} spaces currently remaining',
                  ),
                ],
              ),
            ),
          ),
          const Card(
            color: Color(0xFFFFF3CD),
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Capacity, closures, overlaps and travel time are checked again when you confirm.',
              ),
            ),
          ),
          if (_error != null)
            Card(
              color: const Color(0xFFFFEDEA),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Text(_error!),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('View alternative slots'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _submitting ? null : () => _confirm(data),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF79571E),
              padding: const EdgeInsets.all(15),
            ),
            child: _submitting
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Confirm Booking'),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
