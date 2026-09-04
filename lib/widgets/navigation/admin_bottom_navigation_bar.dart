import 'package:flutter/material.dart';

import 'user_bottom_navigation_bar.dart';

const List<TourFlowNavigationItem> adminNavigationItems = [
  TourFlowNavigationItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
  ),
  TourFlowNavigationItem(
    label: 'Reviews',
    icon: Icons.fact_check_outlined,
    selectedIcon: Icons.fact_check_rounded,
  ),
  TourFlowNavigationItem(
    label: 'Support',
    icon: Icons.support_agent_outlined,
    selectedIcon: Icons.support_agent_rounded,
  ),
];

class AdminBottomNavigationBar extends StatelessWidget {
  const AdminBottomNavigationBar({
    required this.selectedIndex,
    required this.onItemSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  @override
  Widget build(BuildContext context) {
    return TourFlowBottomNavigationBar(
      items: adminNavigationItems,
      selectedIndex: selectedIndex,
      onItemSelected: onItemSelected,
    );
  }
}
