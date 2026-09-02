import 'package:flutter/material.dart';

import 'user_sidebar.dart';

const List<TourFlowSidebarItem> staffSidebarItems = [
  // MAIN NAVIGATION
  TourFlowSidebarItem(
    label: 'Operator Dashboard',
    icon: Icons.dashboard_outlined,
    navigationIndex: 0,
    routeName: '/operator-dashboard',
  ),

  TourFlowSidebarItem(
    label: 'Attraction Details',
    icon: Icons.attractions_outlined,
    navigationIndex: 1,
    routeName: '/attraction-details',
  ),

  TourFlowSidebarItem(
    label: 'Slot Manager',
    icon: Icons.event_available_outlined,
    navigationIndex: 2,
    routeName: '/slot-manager',
  ),

  TourFlowSidebarItem(
    label: 'QR Scanner',
    icon: Icons.qr_code_scanner_rounded,
    navigationIndex: 3,
    routeName: '/operator-qr-scanner',
  ),

  // SIDEBAR ONLY
  TourFlowSidebarItem(
    label: 'User Management',
    icon: Icons.manage_accounts_outlined,
    navigationIndex: -1,
    routeName: '/admin-user-management',
  ),

  TourFlowSidebarItem(
    label: 'Attraction Review',
    icon: Icons.fact_check_outlined,
    navigationIndex: -1,
    routeName: '/admin-attraction-review',
  ),

  // MAIN NAVIGATION
  TourFlowSidebarItem(
    label: 'Support Tickets',
    icon: Icons.support_agent_outlined,
    navigationIndex: 4,
    routeName: '/staff/support-tickets',
  ),

  // SIDEBAR ONLY
  TourFlowSidebarItem(
    label: 'Feedback',
    icon: Icons.rate_review_outlined,
    navigationIndex: -1,
    routeName: '/operator-feedback',
  ),
];

class StaffSidebar extends StatelessWidget {
  const StaffSidebar({
    required this.displayName,
    required this.email,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
    this.avatarUrl,
    super.key,
  });

  final String displayName;
  final String email;
  final String? avatarUrl;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return TourFlowSidebar(
      title: 'TourFlow Staff',
      roleLabel: 'Staff Mode',
      displayName: displayName,
      email: email,
      avatarUrl: avatarUrl,
      items: staffSidebarItems,
      selectedIndex: selectedIndex,
      onItemSelected: onItemSelected,
      onLogout: onLogout,
    );
  }
}