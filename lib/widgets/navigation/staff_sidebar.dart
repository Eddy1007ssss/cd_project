import 'package:flutter/material.dart';

import 'user_sidebar.dart';

const List<TourFlowSidebarItem> staffSidebarItems = [
  TourFlowSidebarItem(label: 'Staff Dashboard', icon: Icons.dashboard_outlined, navigationIndex: 0),
  TourFlowSidebarItem(label: 'Scan Visitor QR', icon: Icons.qr_code_scanner_rounded, navigationIndex: 1),
  TourFlowSidebarItem(label: 'Visitor Records', icon: Icons.groups_outlined, navigationIndex: 2),
  TourFlowSidebarItem(label: 'Crowd Alerts', icon: Icons.notifications_none_rounded, navigationIndex: 3),
  TourFlowSidebarItem(label: 'Staff Profile', icon: Icons.badge_outlined, navigationIndex: 4),
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
