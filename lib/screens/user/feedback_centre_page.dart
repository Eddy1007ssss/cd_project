import 'package:flutter/material.dart';

import '../../widgets/tourflow_widgets.dart';

class FeedbackCentrePage extends StatelessWidget {
  const FeedbackCentrePage({super.key});

  static const routeName = '/feedback-centre';

  @override
  Widget build(BuildContext context) {
    return TourFlowPage(
      title: 'Feedback Centre',
      role: 'TOURIST',
      showBackButton: false,
      selectedNavigationIndex: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =========================
          // INTRODUCTION CARD
          // =========================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How was your visit?',
                  style: TextStyle(
                    color: Color(0xFF8A5700),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your feedback improves crowd planning and attraction quality.',
                  style: TextStyle(
                    color: TourFlowColors.body,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // =========================
          // SUBMIT RATING & FEEDBACK
          // =========================
          _FeedbackMenuCard(
            icon: Icons.rate_review_outlined,
            iconColor: const Color(0xFF00C853),
            title: 'Submit Rating & Feedback',
            subtitle: 'Share your experience',
            onTap: () {
              Navigator.pushNamed(
                context,
                '/submit-feedback',
              );
            },
          ),

          const SizedBox(height: 10),

          // =========================
          // MY FEEDBACK
          // =========================
          _FeedbackMenuCard(
            icon: Icons.history_rounded,
            iconColor: const Color(0xFF7E57C2),
            title: 'My Feedback',
            subtitle: 'View your submitted ratings and feedback',
            onTap: () {
              Navigator.pushNamed(
                context,
                '/my-feedback',
              );
            },
          ),

          const SizedBox(height: 10),

          // =========================
          // REPORT ISSUE
          // =========================
          _FeedbackMenuCard(
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFFF5252),
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

          // =========================
          // VIEW REPORT STATUS
          // =========================
          _FeedbackMenuCard(
            icon: Icons.analytics_outlined,
            iconColor: const Color(0xFFFF6D00),
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
    );
  }
}

// ==========================================================
// FEEDBACK MENU CARD
// ==========================================================
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFE0E0E0),
            ),
          ),
          child: Row(
            children: [
              // ICON
              Icon(
                icon,
                color: iconColor,
                size: 22,
              ),

              const SizedBox(width: 14),

              // TITLE + SUBTITLE
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: TourFlowColors.heading,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: TourFlowColors.muted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ARROW
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.black,
                size: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }
}