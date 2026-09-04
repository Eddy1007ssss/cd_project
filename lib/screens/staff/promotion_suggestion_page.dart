import 'package:flutter/material.dart';

import '../../widgets/tourflow_widgets.dart';

class PromotionSuggestionPage extends StatelessWidget {
  const PromotionSuggestionPage({super.key});

  static const routeName = '/promotion-suggestion';

  @override
  Widget build(BuildContext context) {
    return TourFlowPage(
      title: 'Suggested Promotion',
      role: 'TOURFLOW · OPERATOR',
      navigationRole: TourFlowNavigationRole.operator,
      selectedNavigationIndex: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Suggestion header
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
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Color(0xFFD68A00),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Off-Peak Promotion Suggestion',
                        style: TextStyle(
                          color: Color(0xFF8A5A00),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Generated based on recent visitor trend analysis.',
                  style: TextStyle(color: TourFlowColors.body, fontSize: 11),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Suggested time
          const ModuleCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.schedule_outlined,
                  color: TourFlowColors.primaryText,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Suggested Time',
                        style: TextStyle(
                          color: TourFlowColors.muted,
                          fontSize: 10,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Tuesday, 3:00 PM – 5:00 PM',
                        style: TextStyle(
                          color: TourFlowColors.heading,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Reason
          const ModuleCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: TourFlowColors.primaryText,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reason',
                        style: TextStyle(
                          color: TourFlowColors.muted,
                          fontSize: 10,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Visitor attendance is lower during this period while attraction capacity remains available.',
                        style: TextStyle(
                          color: TourFlowColors.body,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Suggested offer
          ModuleCard(
            color: const Color(0xFFEAF9EE),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.local_offer_outlined,
                  color: Color(0xFF22A95B),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Suggested Offer',
                        style: TextStyle(
                          color: TourFlowColors.muted,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        '15% Off Off-Peak Slots',
                        style: TextStyle(
                          color: Color(0xFF188847),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Offer a discount for visitors who book during the suggested off-peak period.',
                        style: TextStyle(
                          color: TourFlowColors.body,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Expected benefit
          const ModuleCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  color: TourFlowColors.primaryText,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expected Benefit',
                        style: TextStyle(
                          color: TourFlowColors.muted,
                          fontSize: 10,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Encourage more visitors to choose less crowded periods and improve visitor distribution throughout the day.',
                        style: TextStyle(
                          color: TourFlowColors.body,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
