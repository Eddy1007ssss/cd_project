import 'package:flutter/material.dart';

import 'user_bottom_navigation_bar.dart';

const List<TourFlowNavigationItem> operatorNavigationItems = [
  TourFlowNavigationItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
  ),

  TourFlowNavigationItem(
    label: 'Attractions',
    icon: Icons.attractions_outlined,
    selectedIcon: Icons.attractions_rounded,
  ),

  TourFlowNavigationItem(
    label: 'Slots',
    icon: Icons.event_available_outlined,
    selectedIcon: Icons.event_available_rounded,
  ),

  TourFlowNavigationItem(
    label: 'Reports',
    icon: Icons.report_outlined,
    selectedIcon: Icons.report_rounded,
  ),

  TourFlowNavigationItem(
    label: 'Analytics',
    icon: Icons.analytics_outlined,
    selectedIcon: Icons.analytics_rounded,
  ),
];

class OperatorBottomNavigationBar extends StatelessWidget {
  const OperatorBottomNavigationBar({
    required this.selectedIndex,
    required this.onItemSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  @override
  Widget build(BuildContext context) {
    return TourFlowBottomNavigationBar(
      items: operatorNavigationItems,
      selectedIndex: selectedIndex,
      onItemSelected: onItemSelected,
    );
  }
}
