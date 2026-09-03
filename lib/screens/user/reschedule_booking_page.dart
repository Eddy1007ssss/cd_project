import 'package:flutter/material.dart';

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
    if (_booking != null) {
      return;
    }
    _booking = ModalRoute.of(context)?.settings.arguments as TourBooking?;
    _slots = _booking == null
        ? Future.value([])
        : _repository.fetchRescheduleSlots(_booking!);
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    try {
      final booking = await _repository.rescheduleBooking(
        bookingId: _booking!.id,
        newSlotId: _selected!.id,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking rescheduled. Old capacity was released.'),
        ),
      );
      Navigator.pop(context, booking);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Reschedule Booking')),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            color: const Color(0xFFFFF3CD),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'Current: ${shortDate(booking.slot.startsAt)} · ${slotTime(booking.slot)}',
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<AttractionSlot>>(
              future: _slots,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Could not load alternative slots.'),
                  );
                }
                final slots = snapshot.data ?? const [];
                if (slots.isEmpty) {
                  return const Center(
                    child: Text('No suitable alternative slots are available.'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: slots.length,
                  itemBuilder: (_, index) => Card(
                    color: Colors.white,
                    child: ListTile(
                      onTap: () => setState(() => _selected = slots[index]),
                      leading: Icon(
                        _selected?.id == slots[index].id
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                      ),
                      title: Text(
                        '${shortDate(slots[index].startsAt)} · ${slotTime(slots[index])}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${slots[index].remainingCapacity} spaces remaining',
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
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(15),
                ),
                child: Text(_busy ? 'Checking…' : 'Confirm New Slot'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
