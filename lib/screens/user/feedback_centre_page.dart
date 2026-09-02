import 'package:flutter/material.dart';

import '../../widgets/navigation/user_bottom_navigation_bar.dart';
import '../../widgets/navigation/user_sidebar.dart';
import '../../widgets/tourflow_widgets.dart';

import 'submit_feedback_page.dart';

class FeedbackCentrePage extends StatelessWidget {
  const FeedbackCentrePage({super.key});

  static const routeName = '/feedback-centre';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TourFlowColors.background,

      // Sidebar
      drawer: UserSidebar(
        displayName: 'Alex Thompson',
        email: 'alex.thompson@tourflow.com',
        selectedIndex: 6,
        onLogout: () {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/sign-in',
                (route) => false,
          );
        },
      ),

      // Header
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: const Color(0x140F172A),
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feedback Centre',
              style: TextStyle(
                color: TourFlowColors.heading,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'TourFlow',
              style: TextStyle(
                color: TourFlowColors.primaryText,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5E6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFFE0B2),
              ),
            ),
            child: const Center(
              child: Text(
                'TOURIST',
                style: TextStyle(
                  color: Color(0xFF8A5A00),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // How was your visit?
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How was your visit?',
                    style: TextStyle(
                      color: Color(0xFF8A5A00),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Your feedback improves crowd planning and attraction quality.',
                    style: TextStyle(
                      color: TourFlowColors.body,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Submit Rating & Feedback
            _FeedbackMenuCard(
              icon: Icons.reviews_outlined,
              iconColor: Color(0xFF22C55E),
              title: 'Submit Rating & Feedback',
              subtitle: 'Share your experience',
              onTap: () {
                Navigator.pushNamed(
                  context,
                  SubmitFeedbackPage.routeName,
                );
              },
            ),

            const SizedBox(height: 10),

            // Report Issue
            _FeedbackMenuCard(
              icon: Icons.warning_amber_rounded,
              iconColor: Color(0xFFFF4D5A),
              title: 'Report Issue',
              subtitle: 'Let us know the problem',
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/report-issue',
                );
              },
            ),

            const SizedBox(height: 10),

            // View Report Status
            _FeedbackMenuCard(
              icon: Icons.analytics_outlined,
              iconColor: Color(0xFFFF7A00),
              title: 'View Report Status',
              subtitle: 'Track your reports',
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/report-status',
                );
              },
            ),
          ],
        ),
      ),

      // Follow your screenshot:
      // Profile remains selected at bottom
      bottomNavigationBar: const UserBottomNavigationBar(
        selectedIndex: 4,
      ),
    );
  }
}

class _FeedbackMenuCard extends StatelessWidget {
  const _FeedbackMenuCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFE3E6EC),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: TourFlowColors.heading,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: TourFlowColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                size: 30,
                color: Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }
}