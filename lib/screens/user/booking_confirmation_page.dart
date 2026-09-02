import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/module3_models.dart';
import '../../widgets/navigation/user_bottom_navigation_bar.dart';
import 'booking_history_page.dart';
import 'itinerary_planner_page.dart';

class BookingConfirmationPage extends StatelessWidget {
  const BookingConfirmationPage({super.key});
  static const routeName = '/booking-confirmation';
  @override
  Widget build(BuildContext context) {
    final value = ModalRoute.of(context)?.settings.arguments;
    if (value is! TourBooking) {
      return const Scaffold(
        body: Center(child: Text('Booking confirmation is missing.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Confirmed')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CircleAvatar(
            radius: 36,
            backgroundColor: Color(0xFFDCFCE7),
            foregroundColor: Color(0xFF15803D),
            child: Icon(Icons.check, size: 42),
          ),
          const SizedBox(height: 12),
          const Text(
            'You are registered!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Text(
                    value.bookingCode,
                    style: const TextStyle(
                      color: Color(0xFF79571E),
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  QrImageView(data: value.qrToken, size: 180),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.place_outlined),
                    title: Text(value.slot.attractionName),
                    subtitle: Text(
                      '${shortDate(value.slot.startsAt)} · ${slotTime(value.slot)}',
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.group_outlined),
                    title: Text('${value.visitorCount} visitors'),
                    subtitle: const Text('Please arrive 10 minutes early.'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () =>
                Navigator.pushNamed(context, BookingHistoryPage.routeName),
            child: const Text('View Trips'),
          ),
          TextButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, ItineraryPlannerPage.routeName),
            icon: const Icon(Icons.route_outlined),
            label: const Text('Add to itinerary'),
          ),
        ],
      ),
      bottomNavigationBar: const UserBottomNavigationBar(selectedIndex: 2),
    );
  }
}
