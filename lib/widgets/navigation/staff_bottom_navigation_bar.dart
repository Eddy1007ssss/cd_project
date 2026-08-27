import 'package:flutter/material.dart';

import 'user_bottom_navigation_bar.dart';

const List<TourFlowNavigationItem> staffNavigationItems = [
  TourFlowNavigationItem(label: 'Dashboard', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard_rounded),
  TourFlowNavigationItem(label: 'Scan', icon: Icons.qr_code_scanner_outlined, selectedIcon: Icons.qr_code_scanner_rounded),
  TourFlowNavigationItem(label: 'Visitors', icon: Icons.groups_outlined, selectedIcon: Icons.groups_rounded),
  TourFlowNavigationItem(label: 'Alerts', icon: Icons.notifications_none_rounded, selectedIcon: Icons.notifications_rounded),
  TourFlowNavigationItem(label: 'Profile', icon: Icons.person_outline_rounded, selectedIcon: Icons.person_rounded),
];

class StaffBottomNavigationBar extends StatelessWidget {
  const StaffBottomNavigationBar({
    required this.selectedIndex,
    required this.onItemSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  @override
  Widget build(BuildContext context) {
    return TourFlowBottomNavigationBar(
      items: staffNavigationItems,
      selectedIndex: selectedIndex,
      onItemSelected: onItemSelected,
    );
  }
}
