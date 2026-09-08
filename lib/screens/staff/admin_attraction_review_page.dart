import 'package:flutter/material.dart';
import '../../widgets/navigation/navigation_routes.dart';
import 'management_admin_page.dart';

class AdminAttractionReviewPage extends StatelessWidget {
  const AdminAttractionReviewPage({super.key});
  static const routeName = TourFlowRoutes.adminAttractionReview;
  @override
  Widget build(BuildContext context) =>
      const ManagementAdminPage(attractionReview: true);
}
