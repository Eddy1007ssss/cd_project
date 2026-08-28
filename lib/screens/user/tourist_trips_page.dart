import 'package:flutter/material.dart';

import '../../widgets/navigation/user_bottom_navigation_bar.dart';
import '../../widgets/navigation/user_sidebar.dart';

/// Static placeholder until the booking pages in Module 3 are built.
class TouristTripsPage extends StatelessWidget {
  const TouristTripsPage({super.key});

  static const routeName = '/user/trips';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      drawer: UserSidebar(
        displayName: 'Alex Tan',
        email: 'alex@example.com',
        selectedIndex: 2,
        onLogout: () => Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (route) => false),
      ),
      appBar: AppBar(backgroundColor: Colors.white, surfaceTintColor: Colors.transparent, title: const Text('My Trips & Bookings')),
      body: const Center(child: Text('Your bookings will appear here when Module 3 is completed.')),
      bottomNavigationBar: const UserBottomNavigationBar(selectedIndex: 2),
    );
  }
}
