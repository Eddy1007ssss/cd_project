import 'package:flutter/material.dart';

import 'user_sidebar.dart';
import 'navigation_routes.dart';

const List<TourFlowSidebarItem> operatorSidebarItems = [
  // MAIN NAVIGATION
  TourFlowSidebarItem(
    label: 'Operator Dashboard',
    icon: Icons.dashboard_outlined,
    navigationIndex: 0,
    routeName: TourFlowRoutes.operatorDashboard,
  ),

  TourFlowSidebarItem(
    label: 'Attraction Details',
    icon: Icons.attractions_outlined,
    navigationIndex: 1,
    routeName: TourFlowRoutes.attractionDetails,
  ),

  TourFlowSidebarItem(
    label: 'Slot Manager',
    icon: Icons.event_available_outlined,
    navigationIndex: 2,
    routeName: TourFlowRoutes.slotManager,
  ),

  TourFlowSidebarItem(
    label: 'Reports',
    icon: Icons.report_outlined,
    navigationIndex: 3,
    routeName: TourFlowRoutes.operatorReports,
  ),

  TourFlowSidebarItem(
    label: 'Analytics',
    icon: Icons.analytics_outlined,
    navigationIndex: 4,
    routeName: TourFlowRoutes.operatorAnalytics,
  ),

  // SIDEBAR ONLY
  TourFlowSidebarItem(
    label: 'Feedback',
    icon: Icons.rate_review_outlined,
    navigationIndex: -1,
    routeName: '/operator-feedback',
  ),
];

const List<TourFlowSidebarItem> adminSidebarItems = [
  TourFlowSidebarItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    navigationIndex: 0,
    routeName: TourFlowRoutes.adminDashboard,
  ),
  TourFlowSidebarItem(
    label: 'Attraction Review',
    icon: Icons.fact_check_outlined,
    navigationIndex: 1,
    routeName: TourFlowRoutes.adminAttractionReview,
  ),
  TourFlowSidebarItem(
    label: 'Support Tickets',
    icon: Icons.support_agent_outlined,
    navigationIndex: 2,
    routeName: TourFlowRoutes.adminSupportTickets,
  ),
];

const List<TourFlowSidebarItem> staffSidebarItems = [
  TourFlowSidebarItem(
    label: 'Scan QR',
    icon: Icons.qr_code_scanner_rounded,
    navigationIndex: 0,
    routeName: TourFlowRoutes.staffScan,
  ),
  TourFlowSidebarItem(
    label: 'Profile',
    icon: Icons.person_outline_rounded,
    navigationIndex: 1,
    routeName: TourFlowRoutes.staffProfile,
  ),
];

class OperatorSidebar extends StatelessWidget {
  const OperatorSidebar({
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
      title: 'TourFlow Operator',
      roleLabel: 'Operator',
      displayName: displayName,
      email: email,
      avatarUrl: avatarUrl,
      items: operatorSidebarItems,
      selectedIndex: selectedIndex,
      onItemSelected: onItemSelected,
      onLogout: onLogout,
    );
  }
}

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
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
  Widget build(BuildContext context) => TourFlowSidebar(
    title: 'TourFlow Admin',
    roleLabel: 'Administrator',
    displayName: displayName,
    email: email,
    avatarUrl: avatarUrl,
    items: adminSidebarItems,
    selectedIndex: selectedIndex,
    onItemSelected: onItemSelected,
    onLogout: onLogout,
  );
}

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
  Widget build(BuildContext context) => TourFlowSidebar(
    title: 'TourFlow Staff',
    roleLabel: 'Staff',
    displayName: displayName,
    email: email,
    avatarUrl: avatarUrl,
    items: staffSidebarItems,
    selectedIndex: selectedIndex,
    onItemSelected: onItemSelected,
    onLogout: onLogout,
  );
}
