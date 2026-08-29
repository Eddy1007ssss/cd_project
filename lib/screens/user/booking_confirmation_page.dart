import 'package:flutter/material.dart';

import '../../widgets/navigation/user_bottom_navigation_bar.dart';
import '../../widgets/navigation/user_sidebar.dart';
import 'booking_history_page.dart';
import 'itinerary_planner_page.dart';

class BookingConfirmationArguments {
  const BookingConfirmationArguments({
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

class BookingConfirmationPage extends StatelessWidget {
  const BookingConfirmationPage({super.key});
  static const routeName = '/booking-confirmation';

  @override
  Widget build(BuildContext context) {
    final routeArguments = ModalRoute.of(context)?.settings.arguments;
    final booking = routeArguments is BookingConfirmationArguments
        ? routeArguments
        : const BookingConfirmationArguments(
            attraction: 'Old Town Square',
            date: 'Thursday, 28 August',
            time: '09:00 – 10:30',
            code: 'TF-OT-2808-93A7',
            visitors: 1,
          );

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      drawer: UserSidebar(displayName: 'Alex Tan', email: 'alex@example.com', selectedIndex: 2, onLogout: () => Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (route) => false)),
      appBar: AppBar(backgroundColor: Colors.white, surfaceTintColor: Colors.transparent, title: const Text('Registration Confirmed', style: TextStyle(fontWeight: FontWeight.w700))),
      body: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 22, 20, 30), child: Column(children: [
        const CircleAvatar(radius: 37, backgroundColor: Color(0xFFDCFCE7), foregroundColor: Color(0xFF15803D), child: Icon(Icons.check_rounded, size: 45)),
        const SizedBox(height: 13),
        const Text('You are registered!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF131B2E))),
        const SizedBox(height: 5),
        const Text('Show this QR code when you arrive.', style: TextStyle(color: Color(0xFF64748B))),
        const SizedBox(height: 22),
        Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFD2C4B4))), child: Column(children: [
          Text(booking.code, style: const TextStyle(color: Color(0xFF79571E), letterSpacing: 1.3, fontWeight: FontWeight.w800)),
          const SizedBox(height: 15),
          Container(width: 178, height: 178, color: Colors.white, alignment: Alignment.center, child: const Icon(Icons.qr_code_2_rounded, size: 168, color: Color(0xFF131B2E))),
          const SizedBox(height: 15),
          const Divider(),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.account_balance_rounded, color: Color(0xFF79571E)), title: Text(booking.attraction, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${booking.date} · ${booking.time}')),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.person_outline_rounded, color: Color(0xFF79571E)), title: Text('${booking.visitors} ${booking.visitors == 1 ? 'visitor' : 'visitors'}'), subtitle: const Text('Please arrive 10 minutes before your slot.')),
        ])),
        const SizedBox(height: 18),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pushNamed(context, BookingHistoryPage.routeName), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF79571E), padding: const EdgeInsets.symmetric(vertical: 15)), child: const Text('View My Bookings'))),
        const SizedBox(height: 9),
        TextButton.icon(onPressed: () => Navigator.pushNamed(context, ItineraryPlannerPage.routeName), icon: const Icon(Icons.route_outlined), label: const Text('Add to itinerary')),
      ])),
      bottomNavigationBar: const UserBottomNavigationBar(selectedIndex: 2),
    );
  }
}
