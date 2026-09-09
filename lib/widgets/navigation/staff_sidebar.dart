import 'package:flutter/material.dart';

import 'user_sidebar.dart';
import 'navigation_routes.dart';

const List<TourFlowSidebarItem> operatorSidebarItems = [
  TourFlowSidebarItem(
    label: 'Feedback',
    icon: Icons.rate_review_outlined,
    navigationIndex: 6,
    routeName: '/operator-feedback',
  ),
];

const List<TourFlowSidebarItem> adminSidebarItems = [];

const List<TourFlowSidebarItem> staffSidebarItems = [];

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
