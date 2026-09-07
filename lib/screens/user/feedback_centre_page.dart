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
      selectedNavigationIndex: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =====================================================
          // INTRODUCTION CARD
          // =====================================================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TourFlowText(
                  'How was your visit?',
                  style: TextStyle(
                    color: Color(0xFF8A5A00),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                TourFlowText(
                  'Your feedback improves crowd planning and attraction quality.',
                  style: TextStyle(
                    color: Color(0xFF475467),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // =====================================================
          // SUBMIT RATING & FEEDBACK
          // =====================================================
          _FeedbackMenuCard(
            icon: Icons.reviews_outlined,
            iconColor: const Color(0xFF39C52F),
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

          // =====================================================
          // MY FEEDBACK
          // =====================================================
          _FeedbackMenuCard(
            icon: Icons.rate_review_outlined,
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

          // =====================================================
          // REPORT ISSUE
          // =====================================================
          _FeedbackMenuCard(
            icon: Icons.warning_rounded,
            iconColor: const Color(0xFFFF4D57),
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

          // =====================================================
          // VIEW REPORT STATUS
          // =====================================================
          _FeedbackMenuCard(
            icon: Icons.analytics_outlined,
            iconColor: const Color(0xFFFF6B35),
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

// =============================================================
// FEEDBACK MENU CARD
// =============================================================

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
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: double.infinity,

          // 原本 vertical: 15
          // 改大一点
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0xFFDDE3EC),
              width: 1,
            ),
          ),

          child: Row(
            children: [
              // ICON
              SizedBox(
                width: 38,
                child: Icon(
                  icon,
                  color: iconColor,

                  // 原本 28
                  size: 30,
                ),
              ),

              const SizedBox(width: 14),

              // TITLE + SUBTITLE
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TourFlowText(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF101828),

                        // 原本 14
                        fontSize: 15,

                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 6),

                    TourFlowText(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF667085),

                        // 原本 10
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // ARROW
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.black,

                // 原本 31
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }
}