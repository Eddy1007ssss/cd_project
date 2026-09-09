import 'package:cd_project/l10n/tourflow_localization.dart';
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
  Future<BookingConflictAnalysis>? _analysis;
  BookingReviewArguments? _data;
  bool _submitting = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final value = ModalRoute.of(context)?.settings.arguments;
    if (value is BookingReviewArguments && !identical(value, _data)) {
      _data = value;
      _analysis = _repository.previewBooking(
        slot: value.slot,
        visitors: value.visitors,
      );
    }
  }

  Future<void> _confirm(BookingReviewArguments data) async {
    setState(() { _submitting = true; _error = null; });
    try {
      final booking = await _repository.createBooking(
        slotId: data.slot.id,
        visitors: data.visitors,
      );
      if (!mounted) return;
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

  void _chooseAlternative(AttractionSlot slot, int visitors) {
    Navigator.pushReplacementNamed(
      context,
      BookingReviewPage.routeName,
      arguments: BookingReviewArguments(slot: slot, visitors: visitors),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) {
      return const Scaffold(
        body: Center(child: TourFlowText('Booking details are missing.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const TourFlowText('Review Booking')),
      body: FutureBuilder<BookingConflictAnalysis>(
        future: _analysis,
        builder: (context, snapshot) {
          final checking = snapshot.connectionState == ConnectionState.waiting;
          final analysis = snapshot.data;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Icon(Icons.fact_check_outlined, size: 54,
                  color: Color(0xFF79571E)),
              TourFlowText(
                data.slot.attractionName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(children: [
                    _Row('Date', shortDate(data.slot.startsAt)),
                    _Row('Time', slotTime(data.slot)),
                    _Row('Location', data.slot.locationName),
                    _Row('Visitors', '${data.visitors}'),
                    _Row('Capacity',
                        '${data.slot.remainingCapacity} spaces currently remaining'),
                  ]),
                ),
              ),
              if (checking)
                const Card(
                  child: ListTile(
                    leading: CircularProgressIndicator(),
                    title: TourFlowText('Checking your schedule…'),
                    subtitle: TourFlowText(
                      'Validating capacity, closures, overlaps and travel time.',
                    ),
                  ),
                )
              else if (snapshot.hasError)
                const Card(
                  color: Color(0xFFFFF3CD),
                  child: ListTile(
                    leading: Icon(Icons.cloud_off_outlined),
                    title: TourFlowText('Preview unavailable'),
                    subtitle: TourFlowText(
                      'The secure server checks every rule again when you confirm.',
                    ),
                  ),
                )
              else if (analysis != null && analysis.canConfirm)
                const Card(
                  color: Color(0xFFDCFCE7),
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline),
                    title: TourFlowText('No conflict detected'),
                    subtitle: TourFlowText(
                      'Capacity, closure, overlap and travel-time checks passed.',
                    ),
                  ),
                )
              else if (analysis != null) ...[
                ...analysis.issues.map((issue) => Card(
                  color: const Color(0xFFFFEDEA),
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber),
                    title: TourFlowText(issue.title,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: TourFlowText(issue.detail),
                  ),
                )),
                if (analysis.alternativeSlots.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(top: 10, bottom: 4),
                    child: TourFlowText('Available alternatives',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  ...analysis.alternativeSlots.map((slot) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.schedule_outlined),
                      title: TourFlowText(
                        '${shortDate(slot.startsAt)} · ${slotTime(slot)}',
                      ),
                      subtitle: TourFlowText(
                        '${slot.remainingCapacity} spaces remaining',
                      ),
                      trailing: const TourFlowText('Choose'),
                      onTap: () => _chooseAlternative(slot, data.visitors),
                    ),
                  )),
                ],
              ],
              if (_error != null)
                Card(
                  color: const Color(0xFFFFEDEA),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: TourFlowText(_error!),
                  ),
                ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _submitting || checking ||
                        (analysis != null && !analysis.canConfirm)
                    ? null
                    : () => _confirm(data),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF79571E),
                  padding: const EdgeInsets.all(15),
                ),
                child: _submitting
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const TourFlowText('Confirm Booking'),
              ),
            ],
          );
        },
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
        SizedBox(width: 90, child: TourFlowText(label)),
        Expanded(
          child: TourFlowText(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
