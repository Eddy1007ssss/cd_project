import 'package:flutter/material.dart';

import '../../widgets/navigation/user_bottom_navigation_bar.dart';
import '../../widgets/navigation/user_sidebar.dart';
import 'booking_confirmation_page.dart';

class RescheduleBookingArguments {
  const RescheduleBookingArguments({
    required this.attraction,
    required this.date,
    required this.time,
    required this.code,
    required this.visitors,
  });

  final String attraction;
  final String date;
  final String time;
  final String code;
  final int visitors;
}

class RescheduleBookingPage extends StatefulWidget {
  const RescheduleBookingPage({super.key});
  static const routeName = '/reschedule-booking';
  @override
  State<RescheduleBookingPage> createState() => _RescheduleBookingPageState();
}

class _RescheduleBookingPageState extends State<RescheduleBookingPage> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final routeArguments = ModalRoute.of(context)?.settings.arguments;
    final booking = routeArguments is RescheduleBookingArguments
        ? routeArguments
        : const RescheduleBookingArguments(
            attraction: 'Old Town Square',
            date: '28 Aug 2026',
            time: '09:00 – 10:30',
            code: 'TF-OT-2808-93A7',
            visitors: 1,
          );

    return Scaffold(
    backgroundColor: const Color(0xFFFAF8FF),
    drawer: UserSidebar(displayName: 'Alex Tan', email: 'alex@example.com', selectedIndex: 2, onLogout: () => Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (route) => false)),
    appBar: AppBar(backgroundColor: Colors.white, surfaceTintColor: Colors.transparent, title: const Text('Reschedule Booking', style: TextStyle(fontWeight: FontWeight.w700))),
    body: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF2F3FF), borderRadius: BorderRadius.circular(14)), child: Row(children: [const Icon(Icons.info_outline_rounded, color: Color(0xFF79571E)), const SizedBox(width: 10), Expanded(child: Text('Current booking: ${booking.attraction} · ${booking.date} · ${booking.time}', style: const TextStyle(fontSize: 12, height: 1.4)))])),
      const SizedBox(height: 22), const Text('Select a new available slot', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 12),
      ...['Fri, 29 Aug · 10:00 – 11:30', 'Sat, 30 Aug · 09:00 – 10:30', 'Sun, 31 Aug · 16:00 – 17:30'].map((value) => RadioListTile<String>(value: value, groupValue: _selected, onChanged: (value) => setState(() => _selected = value), title: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: const Text('Available · Low crowd level'), tileColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFD2C4B4))))),
      const Spacer(),
      if (_selected != null) Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFFF3CD), borderRadius: BorderRadius.circular(12)), child: const Text('No scheduling conflict detected. Estimated travel time is suitable.', style: TextStyle(fontSize: 12))),
      SizedBox(width: double.infinity, child: FilledButton(onPressed: _selected == null ? null : () => Navigator.pushNamedAndRemoveUntil(context, BookingConfirmationPage.routeName, (route) => false, arguments: BookingConfirmationArguments(attraction: booking.attraction, date: _selected!.split(' · ').first, time: _selected!.split(' · ').last, code: booking.code, visitors: booking.visitors)), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF79571E), padding: const EdgeInsets.symmetric(vertical: 15)), child: const Text('Confirm New Slot'))),
    ])),
    bottomNavigationBar: const UserBottomNavigationBar(selectedIndex: 2),
    );
  }
}
