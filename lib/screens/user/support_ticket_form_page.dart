import 'package:flutter/material.dart';

import '../../widgets/navigation/navigation_routes.dart';
import '../../widgets/tourflow_widgets.dart';
import 'chat_support_page.dart';

/// Kept only as a compatibility route for older links.
/// Support tickets are created through TourFlow Assistant, never by this page.
class SupportTicketFormPage extends StatelessWidget {
  const SupportTicketFormPage({super.key});

  static const routeName = TourFlowRoutes.supportTicketForm;

  @override
  Widget build(BuildContext context) => TourFlowPage(
    title: 'Contact Support',
    role: 'TOURFLOW · TOURIST',
    selectedNavigationIndex: 3,
    child: ModuleCard(
      child: Column(
        children: [
          const Icon(Icons.support_agent_rounded, size: 48),
          const SizedBox(height: 12),
          const TourFlowText(
            'TourFlow Assistant will guide you through the support request.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => Navigator.pushReplacementNamed(
              context,
              ChatSupportPage.routeName,
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: const TourFlowText('Open TourFlow Assistant'),
          ),
        ],
      ),
    ),
  );
}
