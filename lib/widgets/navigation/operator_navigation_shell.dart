import 'package:flutter/material.dart';

import '../../screens/staff/attraction_details_page.dart';
import '../../screens/staff/operator_dashboard_page.dart';
import '../../screens/staff/operator_report_queue_page.dart';
import '../../screens/staff/slot_manager_page.dart';
import '../../screens/staff/visitor_statistics_page.dart';
import 'persistent_navigation_shell.dart';
import 'staff_bottom_navigation_bar.dart';

class OperatorNavigationShell extends StatelessWidget {
  const OperatorNavigationShell({this.initialIndex = 0, super.key});

  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return TourFlowPersistentNavigationShell(
      items: operatorNavigationItems,
      initialIndex: initialIndex,
      tabBuilders: [
        (_) => const OperatorDashboardPage(),
        (_) => const AttractionDetailsPage(),
        (_) => const SlotManagerPage(),
        (_) => const OperatorReportQueuePage(),
        (_) => const VisitorStatisticsPage(),
      ],
      bottomBarBuilder: (_, selectedIndex, onItemSelected) =>
          OperatorBottomNavigationBar(
            selectedIndex: selectedIndex,
            onItemSelected: onItemSelected,
          ),
    );
  }
}
