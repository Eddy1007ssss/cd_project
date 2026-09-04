import 'package:flutter/material.dart';

import '../../models/module3_models.dart';
import '../../repositories/module3_repository.dart';
import 'booking_review_page.dart';

class TimeSlotSelectionArguments {
  const TimeSlotSelectionArguments({
    required this.attractionId,
    required this.attractionName,
    this.category = 'Attraction',
    this.locationName = 'Malaysia',
  });
  final String attractionId;
  final String attractionName;
  final String category;
  final String locationName;
}

class TimeSlotSelectionPage extends StatefulWidget {
  const TimeSlotSelectionPage({super.key});
  static const routeName = '/time-slot-selection';
  @override
  State<TimeSlotSelectionPage> createState() => _TimeSlotSelectionPageState();
}

class _TimeSlotSelectionPageState extends State<TimeSlotSelectionPage> {
  final _repository = Module3Repository();
  late final List<DateTime> _dates;
  TimeSlotSelectionArguments? _arguments;
  late DateTime _selectedDate;
  AttractionSlot? _selectedSlot;
  int _visitors = 1;
  bool _loading = true;
  String? _error;
  List<AttractionSlot> _slots = const [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dates = List.generate(
      7,
      (i) => DateTime(now.year, now.month, now.day + i),
    );
    _selectedDate = _dates.first;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_arguments != null) {
      return;
    }
    final value = ModalRoute.of(context)?.settings.arguments;
    _arguments = value is TimeSlotSelectionArguments
        ? value
        : const TimeSlotSelectionArguments(
            attractionId: '10000000-0000-0000-0000-000000000001',
            attractionName: 'Merdeka Heritage Walk',
            category: 'Historical Landmark',
            locationName: 'Kuala Lumpur',
          );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _selectedSlot = null;
    });
    try {
      final result = await _repository.fetchSlots(
        attractionId: _arguments!.attractionId,
        date: _selectedDate,
      );
      if (mounted) {
        setState(() => _slots = result);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Could not load slots: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final attraction = _arguments!;
    return Scaffold(
      appBar: AppBar(title: const Text('Select a Time Slot')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              attraction.attractionName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            Text('${attraction.category} · ${attraction.locationName}'),
            const SizedBox(height: 20),
            const Text(
              'Choose your visit date',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _dates.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final date = _dates[index];
                  return ChoiceChip(
                    label: Text(
                      shortDate(date).substring(0, shortDate(date).length - 5),
                    ),
                    selected: _selectedDate == date,
                    selectedColor: const Color(0xFFFFD08B),
                    onSelected: (_) {
                      setState(() => _selectedDate = date);
                      _load();
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Available time slots',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(28),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _MessageCard(_error!)
            else if (_slots.isEmpty)
              const _MessageCard(
                'No slots are scheduled for this date. Try another day.',
              )
            else
              ..._slots.map(
                (slot) => Card(
                  color: Colors.white,
                  child: ListTile(
                    enabled: slot.isBookable,
                    onTap: slot.isBookable
                        ? () => setState(() => _selectedSlot = slot)
                        : null,
                    leading: Icon(
                      _selectedSlot?.id == slot.id
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    title: Text(
                      slotTime(slot),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '${slot.status.toUpperCase()} · ${slot.remainingCapacity} of ${slot.maximumCapacity} spaces left',
                    ),
                    trailing: _StatusBadge(slot),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'Number of visitors',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    const Icon(Icons.group_outlined),
                    const Spacer(),
                    IconButton.outlined(
                      onPressed: _visitors > 1
                          ? () => setState(() => _visitors--)
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '$_visitors',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton.filled(
                      onPressed: _visitors < 6
                          ? () => setState(() => _visitors++)
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed:
                  _selectedSlot != null &&
                      _selectedSlot!.remainingCapacity >= _visitors
                  ? () => Navigator.pushNamed(
                      context,
                      BookingReviewPage.routeName,
                      arguments: BookingReviewArguments(
                        slot: _selectedSlot!,
                        visitors: _visitors,
                      ),
                    )
                  : null,
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Review Booking'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF79571E),
                padding: const EdgeInsets.all(15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    child: Padding(padding: const EdgeInsets.all(16), child: Text(message)),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.slot);
  final AttractionSlot slot;
  @override
  Widget build(BuildContext context) {
    final ratio = slot.reservedCapacity / slot.maximumCapacity;
    final label = !slot.isBookable
        ? slot.status.toUpperCase()
        : ratio < .4
        ? 'LOW'
        : ratio < .75
        ? 'MODERATE'
        : 'HIGH';
    final color = !slot.isBookable
        ? Colors.red
        : ratio < .4
        ? Colors.green
        : ratio < .75
        ? Colors.amber.shade800
        : Colors.orange.shade800;
    return Chip(
      label: Text(label, style: TextStyle(color: color, fontSize: 10)),
      backgroundColor: color.withValues(alpha: .1),
      side: BorderSide.none,
    );
  }
}
