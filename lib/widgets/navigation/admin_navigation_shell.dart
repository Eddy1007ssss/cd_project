import 'package:flutter/material.dart';

import '../../screens/staff/admin_attraction_review_page.dart';
import '../../screens/staff/admin_user_management_page.dart';
import '../../screens/staff/support_ticket_management_page.dart';
import '../tourflow_widgets.dart';
import 'admin_bottom_navigation_bar.dart';
import 'persistent_navigation_shell.dart';

class AdminNavigationShell extends StatelessWidget {
  const AdminNavigationShell({this.initialIndex = 0, super.key});

  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return TourFlowPersistentNavigationShell(
      items: adminNavigationItems,
      initialIndex: initialIndex,
      tabBuilders: [
        (_) => const AdminUserManagementPage(),
        (_) => const AdminAttractionReviewPage(),
        (_) => const SupportTicketManagementPage(
          navigationRole: TourFlowNavigationRole.administrator,
        ),
      ],
      bottomBarBuilder: (_, selectedIndex, onItemSelected) =>
          AdminBottomNavigationBar(
            selectedIndex: selectedIndex,
            onItemSelected: onItemSelected,
          ),
    );
  }
}
