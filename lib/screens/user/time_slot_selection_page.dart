import 'package:flutter/material.dart';

import '../../widgets/navigation/user_bottom_navigation_bar.dart';
import '../../widgets/navigation/user_sidebar.dart';
import 'booking_confirmation_page.dart';

class TimeSlotSelectionPage extends StatefulWidget {
  const TimeSlotSelectionPage({super.key});
  static const routeName = '/time-slot-selection';

  @override
  State<TimeSlotSelectionPage> createState() => _TimeSlotSelectionPageState();
}

class _TimeSlotSelectionPageState extends State<TimeSlotSelectionPage> {
  int _selectedDate = 0;
  int _visitorCount = 1;
  String? _selectedSlot;

  static const int _maximumVisitorsPerBooking = 6;

  final _dates = const ['Today\n28 Aug', 'Fri\n29 Aug', 'Sat\n30 Aug', 'Sun\n31 Aug'];
  final _slots = const [
    ('09:00 – 10:30', '48 spaces left', 'Low', Color(0xFF16A34A)),
    ('11:00 – 12:30', '12 spaces left', 'Moderate', Color(0xFFF59E0B)),
    ('14:00 – 15:30', 'Full', 'Full', Color(0xFFBA1A1A)),
    ('16:00 – 17:30', '26 spaces left', 'Low', Color(0xFF16A34A)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      drawer: UserSidebar(displayName: 'Alex Tan', email: 'alex@example.com', selectedIndex: 1, onLogout: () => Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (route) => false)),
      appBar: AppBar(backgroundColor: Colors.white, surfaceTintColor: Colors.transparent, title: const Text('Select a Time Slot', style: TextStyle(fontWeight: FontWeight.w700))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Old Town Square', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF131B2E))),
          const SizedBox(height: 4),
          const Text('Historical Landmark · Kuala Lumpur', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          const SizedBox(height: 20),
          const Text('Choose your visit date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          SizedBox(height: 72, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: _dates.length, separatorBuilder: (_, __) => const SizedBox(width: 9), itemBuilder: (_, index) => ChoiceChip(
            label: Text(_dates[index], textAlign: TextAlign.center),
            selected: _selectedDate == index,
            onSelected: (_) => setState(() => _selectedDate = index),
            selectedColor: const Color(0xFFFFD08B),
            labelStyle: TextStyle(color: _selectedDate == index ? const Color(0xFF79571E) : const Color(0xFF4F4539), fontWeight: FontWeight.w700, fontSize: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ))),
          const SizedBox(height: 22),
          const Text('Available time slots', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ..._slots.map((slot) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SlotCard(time: slot.$1, capacity: slot.$2, crowd: slot.$3, crowdColor: slot.$4, selected: _selectedSlot == slot.$1, onTap: slot.$3 == 'Full' ? null : () => setState(() => _selectedSlot = slot.$1)),
          )),
          const SizedBox(height: 12),
          const Text('Number of visitors', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          const Text('You can register up to 6 visitors in one booking.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          const SizedBox(height: 10),
          _VisitorCounter(
            count: _visitorCount,
            canDecrease: _visitorCount > 1,
            canIncrease: _visitorCount < _maximumVisitorsPerBooking,
            onDecrease: () => setState(() => _visitorCount--),
            onIncrease: () => setState(() => _visitorCount++),
          ),
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF2F3FF), borderRadius: BorderRadius.circular(14)), child: const Row(children: [Icon(Icons.auto_awesome_rounded, color: Color(0xFF79571E)), SizedBox(width: 10), Expanded(child: Text('Recommended: 09:00 – 10:30 has the lowest crowd level.', style: TextStyle(fontSize: 12, height: 1.4)))])),
          const SizedBox(height: 22),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: _selectedSlot == null ? null : () => Navigator.pushNamed(context, BookingConfirmationPage.routeName),
            icon: const Icon(Icons.confirmation_num_outlined), label: const Text('Confirm Registration'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF79571E), padding: const EdgeInsets.symmetric(vertical: 15)),
          )),
        ]),
      ),
      bottomNavigationBar: const UserBottomNavigationBar(selectedIndex: 1),
    );
  }
}

class _VisitorCounter extends StatelessWidget {
  const _VisitorCounter({
    required this.count,
    required this.canDecrease,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int count;
  final bool canDecrease;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD2C4B4)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFFFE2B5),
            foregroundColor: Color(0xFF79571E),
            child: Icon(Icons.group_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count ${count == 1 ? 'visitor' : 'visitors'}',
                  style: const TextStyle(
                    color: Color(0xFF131B2E),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'Reserved capacity for this booking',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton.outlined(
            tooltip: 'Remove visitor',
            onPressed: canDecrease ? onDecrease : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          IconButton.filled(
            tooltip: 'Add visitor',
            onPressed: canIncrease ? onIncrease : null,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFFFD08B),
              foregroundColor: const Color(0xFF79571E),
            ),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({required this.time, required this.capacity, required this.crowd, required this.crowdColor, required this.selected, this.onTap});
  final String time, capacity, crowd;
  final Color crowdColor;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: selected ? const Color(0xFF79571E) : const Color(0xFFD2C4B4), width: selected ? 2 : 1)), child: Row(children: [Icon(Icons.access_time_rounded, color: onTap == null ? const Color(0xFF94A3B8) : const Color(0xFF79571E)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(time, style: TextStyle(fontWeight: FontWeight.w800, color: onTap == null ? const Color(0xFF94A3B8) : const Color(0xFF131B2E))), const SizedBox(height: 3), Text(capacity, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))])), Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: crowdColor.withOpacity(.12), borderRadius: BorderRadius.circular(20)), child: Text(crowd, style: TextStyle(color: crowdColor, fontSize: 10, fontWeight: FontWeight.w800)))])),
  );
}