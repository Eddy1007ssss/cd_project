import 'package:flutter/material.dart';

abstract final class TourFlowNavigationColors {
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFD2C4B4);
  static const Color activeBackground = Color(0xFFFFCC87);
  static const Color activeForeground = Color(0xFF7A541A);
  static const Color foreground = Color(0xFF4F4539);
  static const Color mutedForeground = Color(0xFF64748B);
  static const Color danger = Color(0xFFDC2626);
}

class TourFlowNavigationItem {
  const TourFlowNavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.routeName,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String? routeName;
}

const List<TourFlowNavigationItem> userNavigationItems = [
  TourFlowNavigationItem(
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    routeName: '/user/home',
  ),
  TourFlowNavigationItem(
    label: 'Discover',
    icon: Icons.explore_outlined,
    selectedIcon: Icons.explore_rounded,
    routeName: '/attraction-discovery',
  ),
  TourFlowNavigationItem(
    label: 'Trips',
    icon: Icons.confirmation_num_outlined,
    selectedIcon: Icons.confirmation_num_rounded,
    routeName: '/user/trips',
  ),
  TourFlowNavigationItem(
    label: 'Chat',
    icon: Icons.chat_bubble_outline_rounded,
    selectedIcon: Icons.chat_bubble_rounded,
    routeName: '/user/chat',
  ),
  TourFlowNavigationItem(
    label: 'Profile',
    icon: Icons.person_outline_rounded,
    selectedIcon: Icons.person_rounded,
    routeName: '/profile-security',
  ),
];

class TourFlowBottomNavigationBar extends StatelessWidget {
  const TourFlowBottomNavigationBar({
    required this.items,
    required this.selectedIndex,
    this.onItemSelected,
    super.key,
  });

  final List<TourFlowNavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int>? onItemSelected;

  @override
  Widget build(BuildContext context) {
    assert(items.isNotEmpty);
    assert(selectedIndex >= 0 && selectedIndex < items.length);

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: TourFlowNavigationColors.surface,
        border: Border(top: BorderSide(color: TourFlowNavigationColors.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x140F172A),
            offset: Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(
              items.length,
              (index) => Expanded(
                child: _NavigationButton(
                  item: items[index],
                  isSelected: index == selectedIndex,
                  onTap: () {
                    final routeName = items[index].routeName;
                    if (routeName != null) {
                      if (ModalRoute.of(context)?.settings.name != routeName) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          routeName,
                          (route) => false,
                        );
                      }
                      return;
                    }
                    onItemSelected?.call(index);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  const _NavigationButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final TourFlowNavigationItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? TourFlowNavigationColors.activeForeground
        : TourFlowNavigationColors.foreground;

    return Semantics(
      selected: isSelected,
      button: true,
      label: item.label,
      child: InkResponse(
        onTap: onTap,
        radius: 30,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minWidth: 54, minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? TourFlowNavigationColors.activeBackground
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  size: 20,
                  color: color,
                ),
                const SizedBox(height: 1),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UserBottomNavigationBar extends StatelessWidget {
  const UserBottomNavigationBar({
    required this.selectedIndex,
    this.onItemSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int>? onItemSelected;

  @override
  Widget build(BuildContext context) {
    return TourFlowBottomNavigationBar(
      items: userNavigationItems,
      selectedIndex: selectedIndex,
      onItemSelected: onItemSelected,
    );
  }
}
