import 'package:flutter/material.dart';

import 'user_bottom_navigation_bar.dart';

class TourFlowSidebarItem {
  const TourFlowSidebarItem({
    required this.label,
    required this.icon,
    required this.navigationIndex,
    this.routeName,
  });

  final String label;
  final IconData icon;
  final int navigationIndex;
  final String? routeName;
}

const List<TourFlowSidebarItem> userSidebarItems = [
  TourFlowSidebarItem(label: 'Home', icon: Icons.home_outlined, navigationIndex: 0, routeName: '/user/home'),
  TourFlowSidebarItem(label: 'Discover Attractions', icon: Icons.explore_outlined, navigationIndex: 1, routeName: '/attraction-discovery'),
  TourFlowSidebarItem(label: 'My Trips & Bookings', icon: Icons.confirmation_num_outlined, navigationIndex: 2, routeName: '/user/trips'),
  TourFlowSidebarItem(label: 'Itinerary Planner', icon: Icons.route_rounded, navigationIndex: 5, routeName: '/itinerary-planner'),
  TourFlowSidebarItem(label: 'Chatbot & Support', icon: Icons.chat_bubble_outline_rounded, navigationIndex: 3, routeName: '/user/chat'),
  TourFlowSidebarItem(label: 'My Profile', icon: Icons.person_outline_rounded, navigationIndex: 4, routeName: '/profile-security'),
];

class TourFlowSidebar extends StatelessWidget {
  const TourFlowSidebar({
    required this.title,
    required this.roleLabel,
    required this.displayName,
    required this.email,
    required this.items,
    required this.selectedIndex,
    this.onItemSelected,
    required this.onLogout,
    this.avatarUrl,
    super.key,
  });

  final String title;
  final String roleLabel;
  final String displayName;
  final String email;
  final String? avatarUrl;
  final List<TourFlowSidebarItem> items;
  final int selectedIndex;
  final ValueChanged<int>? onItemSelected;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 304,
      backgroundColor: TourFlowNavigationColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _SidebarHeader(
              title: title,
              roleLabel: roleLabel,
              displayName: displayName,
              email: email,
              avatarUrl: avatarUrl,
            ),
            const Divider(height: 1, color: TourFlowNavigationColors.border),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final selected = item.navigationIndex == selectedIndex;
                  return ListTile(
                    selected: selected,
                    selectedTileColor: TourFlowNavigationColors.activeBackground,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    leading: Icon(
                      item.icon,
                      color: selected
                          ? TourFlowNavigationColors.activeForeground
                          : TourFlowNavigationColors.foreground,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        color: selected
                            ? TourFlowNavigationColors.activeForeground
                            : TourFlowNavigationColors.foreground,
                        fontSize: 14,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      final routeName = item.routeName;
                      if (routeName != null) {
                        Navigator.pushNamedAndRemoveUntil(context, routeName, (route) => false);
                      } else {
                        onItemSelected?.call(item.navigationIndex);
                      }
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1, color: TourFlowNavigationColors.border),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                leading: const Icon(Icons.logout_rounded, color: TourFlowNavigationColors.danger),
                title: const Text(
                  'Log Out',
                  style: TextStyle(color: TourFlowNavigationColors.danger, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onLogout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({
    required this.title,
    required this.roleLabel,
    required this.displayName,
    required this.email,
    required this.avatarUrl,
  });

  final String title;
  final String roleLabel;
  final String displayName;
  final String email;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      color: const Color(0xFFFFF6E8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: TourFlowNavigationColors.activeBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.travel_explore_rounded, color: TourFlowNavigationColors.activeForeground),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: TourFlowNavigationColors.foreground, fontSize: 20, fontWeight: FontWeight.w800)),
                    Text(
                      roleLabel.toUpperCase(),
                      style: const TextStyle(color: TourFlowNavigationColors.activeForeground, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: TourFlowNavigationColors.activeBackground,
                backgroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl!),
                child: avatarUrl == null
                    ? Text(_initials(displayName), style: const TextStyle(color: TourFlowNavigationColors.activeForeground, fontWeight: FontWeight.w800))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: TourFlowNavigationColors.foreground, fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: TourFlowNavigationColors.mutedForeground, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _initials(String value) {
    final words = value.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return '?';
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }
}

class UserSidebar extends StatelessWidget {
  const UserSidebar({
    required this.displayName,
    required this.email,
    required this.selectedIndex,
    this.onItemSelected,
    required this.onLogout,
    this.avatarUrl,
    super.key,
  });

  final String displayName;
  final String email;
  final String? avatarUrl;
  final int selectedIndex;
  final ValueChanged<int>? onItemSelected;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return TourFlowSidebar(
      title: 'TourFlow',
      roleLabel: 'Tourist',
      displayName: displayName,
      email: email,
      avatarUrl: avatarUrl,
      items: userSidebarItems,
      selectedIndex: selectedIndex,
      onItemSelected: onItemSelected,
      onLogout: onLogout,
    );
  }
}
