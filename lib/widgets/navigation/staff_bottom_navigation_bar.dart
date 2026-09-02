import 'package:flutter/material.dart';

import 'user_bottom_navigation_bar.dart';

const List<TourFlowNavigationItem> staffNavigationItems = [
  TourFlowNavigationItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
    routeName: '/operator-dashboard',
  ),
  TourFlowNavigationItem(
    label: 'Attractions',
    icon: Icons.attractions_outlined,
    selectedIcon: Icons.attractions_rounded,
    routeName: '/attraction-details',
  ),
  TourFlowNavigationItem(
    label: 'Slots',
    icon: Icons.event_available_outlined,
    selectedIcon: Icons.event_available_rounded,
    routeName: '/slot-manager',
  ),
  TourFlowNavigationItem(
    label: 'Users',
    icon: Icons.manage_accounts_outlined,
    selectedIcon: Icons.manage_accounts_rounded,
    routeName: '/admin-user-management',
  ),
  TourFlowNavigationItem(
    label: 'Reviews',
    icon: Icons.fact_check_outlined,
    selectedIcon: Icons.fact_check_rounded,
    routeName: '/admin-attraction-review',
  ),
  TourFlowNavigationItem(
    label: 'Support',
    icon: Icons.support_agent_outlined,
    selectedIcon: Icons.support_agent_rounded,
    routeName: '/staff/support-tickets',
  ),
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
