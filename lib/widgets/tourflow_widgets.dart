import 'package:flutter/material.dart';

import 'navigation/user_bottom_navigation_bar.dart';
import 'navigation/user_sidebar.dart';
import 'navigation/staff_bottom_navigation_bar.dart';
import 'navigation/staff_sidebar.dart';

abstract final class TourFlowColors {
  static const background = Color(0xFFFAF8FF);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFFFFD08B);
  static const primaryStrong = Color(0xFFFFCC87);
  static const primaryText = Color(0xFF79571E);
  static const heading = Color(0xFF131B2E);
  static const body = Color(0xFF4F4539);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFD2C4B4);
  static const lavender = Color(0xFFF2F3FF);
  static const lavenderStrong = Color(0xFFEAEDFF);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFBA1A1A);
}

class TourFlowPage extends StatelessWidget {
  const TourFlowPage({
    required this.title,
    required this.role,
    required this.child,
    this.showBackButton = true,
    this.actions = const [],
    this.isStaff = false,
    this.selectedNavigationIndex = 0,
    this.displayName = 'Alex Thompson',
    this.email = 'alex.thompson@tourflow.com',
    this.onNavigationSelected,
    this.onLogout,
    super.key,
  });

  final String title;
  final String role;
  final Widget child;
  final bool showBackButton;
  final List<Widget> actions;
  final bool isStaff;
  final int selectedNavigationIndex;
  final String displayName;
  final String email;
  final ValueChanged<int>? onNavigationSelected;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TourFlowColors.background,
      drawer: isStaff
          ? StaffSidebar(
              displayName: displayName,
              email: email,
              selectedIndex: selectedNavigationIndex,
              onItemSelected: (index) => _handleNavigation(context, index),
              onLogout: () => _handleLogout(context),
            )
          : UserSidebar(
              displayName: displayName,
              email: email,
              selectedIndex: selectedNavigationIndex,
              onItemSelected: (index) => _handleNavigation(context, index),
              onLogout: () => _handleLogout(context),
            ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: showBackButton ? 96 : 56,
        leading: Builder(
          builder: (context) => Row(
            children: [
              if (showBackButton)
                IconButton(
                  tooltip: 'Back',
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              IconButton(
                tooltip: 'Open menu',
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu_rounded),
              ),
            ],
          ),
        ),
        centerTitle: false,
        elevation: 1,
        shadowColor: const Color(0x140F172A),
        backgroundColor: TourFlowColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: TourFlowColors.heading,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              role,
              style: const TextStyle(
                color: TourFlowColors.primaryText,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: actions,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          child: child,
        ),
      ),
      bottomNavigationBar: isStaff
          ? StaffBottomNavigationBar(
              selectedIndex: selectedNavigationIndex,
              onItemSelected: (index) => _handleNavigation(context, index),
            )
          : UserBottomNavigationBar(
              selectedIndex: selectedNavigationIndex,
              onItemSelected: (index) => _handleNavigation(context, index),
            ),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    if (onNavigationSelected != null) {
      onNavigationSelected!(index);
      return;
    }

    if (isStaff && index == 0) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/operator-dashboard',
        (route) => route.isFirst,
      );
    } else if (!isStaff && index == 4) {
      Navigator.pushNamed(context, '/profile-security');
    }
  }

  void _handleLogout(BuildContext context) {
    if (onLogout != null) {
      onLogout!();
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/sign-in',
      (route) => false,
    );
  }
}

class ModuleCard extends StatelessWidget {
  const ModuleCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = TourFlowColors.surface,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: TourFlowColors.border.withOpacity(0.45)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: TourFlowColors.heading,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: const TextStyle(
              color: TourFlowColors.muted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

class StaticField extends StatelessWidget {
  const StaticField({
    required this.label,
    required this.value,
    this.icon,
    this.maxLines = 1,
    this.trailing,
    super.key,
  });

  final String label;
  final String value;
  final IconData? icon;
  final int maxLines;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: TourFlowColors.body,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          constraints: BoxConstraints(minHeight: maxLines > 1 ? 96 : 48),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          decoration: BoxDecoration(
            color: TourFlowColors.surface,
            border: Border.all(color: TourFlowColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: maxLines > 1
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 19, color: TourFlowColors.muted),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TourFlowColors.heading,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 19),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: TourFlowColors.primary,
          foregroundColor: TourFlowColors.primaryText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class OutlineActionButton extends StatelessWidget {
  const OutlineActionButton({
    required this.label,
    required this.onPressed,
    this.color = TourFlowColors.primaryText,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.55)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    required this.color,
    super.key,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.note,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return ModuleCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: TourFlowColors.primaryText, size: 22),
              if (note != null)
                Text(
                  note!,
                  style: const TextStyle(
                    color: TourFlowColors.success,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(color: TourFlowColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: TourFlowColors.heading,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
