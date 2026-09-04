import 'package:flutter/material.dart';

import '../../screens/user/attraction_discovery_page.dart';
import '../../screens/user/booking_history_page.dart';
import '../../screens/user/chat_support_page.dart';
import '../../screens/user/profile_security_page.dart';
import '../../screens/user/user_home_page.dart';
import 'persistent_navigation_shell.dart';
import 'user_bottom_navigation_bar.dart';

class UserNavigationShell extends StatelessWidget {
  const UserNavigationShell({this.initialIndex = 0, super.key});

  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return TourFlowPersistentNavigationShell(
      items: userNavigationItems,
      initialIndex: initialIndex,
      tabBuilders: [
        (_) => const UserHomePage(),
        (_) => const AttractionDiscoveryPage(),
        (_) => const BookingHistoryPage(),
        (_) => const ChatSupportPage(),
        (_) => const ProfileSecurityPage(),
      ],
      bottomBarBuilder: (_, selectedIndex, onItemSelected) =>
          UserBottomNavigationBar(
            selectedIndex: selectedIndex,
            onItemSelected: onItemSelected,
          ),
    );
  }
}
