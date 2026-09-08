import 'package:flutter/material.dart';
import '../../widgets/navigation/navigation_routes.dart';
import 'management_admin_page.dart';

class AdminUserManagementPage extends StatelessWidget {
  const AdminUserManagementPage({super.key});
  static const routeName = TourFlowRoutes.adminDashboard;
  @override
  Widget build(BuildContext context) => const ManagementAdminPage();
}
