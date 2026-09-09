import 'package:flutter/material.dart';
import 'package:cd_project/l10n/tourflow_localization.dart';
import '../../models/module3_models.dart';
import '../../repositories/module3_repository.dart';

class RescheduleBookingPage extends StatefulWidget {
  const RescheduleBookingPage({super.key});
  static const routeName = '/reschedule-booking';
  @override
  State<RescheduleBookingPage> createState() => _RescheduleBookingPageState();
}

class _RescheduleBookingPageState extends State<RescheduleBookingPage> {
  final _repository = Module3Repository();
  TourBooking? _booking;
  late Future<List<AttractionSlot>> _slots;
  AttractionSlot? _selected;
  bool _busy = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_booking != null) return;
    _booking = ModalRoute.of(context)?.settings.arguments as TourBooking?;
    _slots = _booking == null
        ? Future.value([])
        : _repository.fetchRescheduleSlots(_booking!);
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    try {
      final updated = await _repository.rescheduleBooking(
        bookingId: _booking!.id,
        newSlotId: _selected!.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TourFlowText(
            'Booking rescheduled. Old capacity was released.',
          ),
        ),
      );
      Navigator.pop(context, updated);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: TourFlowText(bookingErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;
    if (booking == null)
      return const Scaffold(
        body: Center(child: TourFlowText('Booking details are missing.')),
      );
    return Scaffold(
      appBar: AppBar(title: const TourFlowText('Reschedule Booking')),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            color: const Color(0xFFFFF3CD),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: TourFlowText(
                'Choose a new time at ${booking.slot.attractionName}.\nCurrent: ${shortDate(booking.slot.startsAt)} · ${slotTime(booking.slot)}',
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<AttractionSlot>>(
              future: _slots,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError)
                  return const Center(
                    child: TourFlowText('Could not load alternative slots.'),
                  );
                final slots = snapshot.data ?? const <AttractionSlot>[];
                if (slots.isEmpty)
                  return const Center(
                    child: TourFlowText(
                      'No suitable alternative slots are available.',
                    ),
                  );
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: slots.length,
                  itemBuilder: (_, i) => Card(
                    child: ListTile(
                      onTap: _busy
                          ? null
                          : () => setState(() => _selected = slots[i]),
                      leading: Icon(
                        _selected?.id == slots[i].id
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                      ),
                      title: TourFlowText(
                        '${shortDate(slots[i].startsAt)} · ${slotTime(slots[i])}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: TourFlowText(
                        '${slots[i].remainingCapacity} spaces remaining',
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selected == null || _busy ? null : _confirm,
                child: TourFlowText(_busy ? 'Checking…' : 'Confirm New Slot'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
