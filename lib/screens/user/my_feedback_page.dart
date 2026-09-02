import 'package:flutter/material.dart';

import '../../widgets/tourflow_widgets.dart';

class MyFeedbackPage extends StatelessWidget {
  const MyFeedbackPage({super.key});

  static const routeName = '/my-feedback';

  // Temporary storage before connecting Supabase.
  // The latest submitted feedback will be stored here.
  static Map<String, dynamic>? latestFeedback;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? feedback = latestFeedback;

    return TourFlowPage(
      title: 'My Feedback',
      role: 'TOURIST',
      selectedNavigationIndex: 4,
      child: feedback == null
          ? _buildEmptyState(context)
          : _buildFeedbackContent(context, feedback),
    );
  }

  // ==========================================================
  // EMPTY STATE
  // ==========================================================

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      children: [
        ModuleCard(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                const SizedBox(height: 10),

                const Icon(
                  Icons.rate_review_outlined,
                  size: 45,
                  color: TourFlowColors.muted,
                ),

                const SizedBox(height: 14),

                const Text(
                  'No feedback submitted yet',
                  style: TextStyle(
                    color: TourFlowColors.heading,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 7),

                const Text(
                  'Your submitted attraction ratings and feedback will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: TourFlowColors.muted,
                    fontSize: 10,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(
                context,
                '/feedback-centre',
              );
            },
            child: const Text(
              'Back to Feedback Centre',
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // FEEDBACK CONTENT
  // ==========================================================

  Widget _buildFeedbackContent(
      BuildContext context,
      Map<String, dynamic> feedback,
      ) {
    final String attraction =
        feedback['attraction']?.toString() ?? 'National Museum';

    final String booking =
        feedback['booking']?.toString() ?? 'NM-170926-1600-A1';

    final int overallRating =
    feedback['overallRating'] is int
        ? feedback['overallRating'] as int
        : 0;

    final int crowdComfort =
    feedback['crowdComfort'] is int
        ? feedback['crowdComfort'] as int
        : 0;

    final String comment =
        feedback['comment']?.toString() ?? '';

    final String submittedDate =
        feedback['submittedDate']?.toString() ?? '';

    final List<String> tags =
    feedback['tags'] is List
        ? List<String>.from(feedback['tags'])
        : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ModuleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // ATTRACTION
              // ==================================================

              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.museum_outlined,
                      color: Color(0xFFFF8F00),
                      size: 22,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attraction,
                          style: const TextStyle(
                            color: TourFlowColors.heading,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'Booking $booking',
                          style: const TextStyle(
                            color: TourFlowColors.muted,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Submitted',
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const Divider(
                height: 1,
              ),

              const SizedBox(height: 18),

              // ==================================================
              // OVERALL RATING
              // ==================================================

              const Text(
                'Overall Rating',
                style: TextStyle(
                  color: TourFlowColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 7),

              Row(
                children: [
                  ...List.generate(
                    5,
                        (index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Icon(
                          Icons.star_rounded,
                          size: 23,
                          color: index < overallRating
                              ? const Color(0xFFFFA000)
                              : const Color(0xFFD8DDE5),
                        ),
                      );
                    },
                  ),

                  const SizedBox(width: 8),

                  Text(
                    '$overallRating/5',
                    style: const TextStyle(
                      color: TourFlowColors.heading,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ==================================================
              // CROWD COMFORT
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.groups_outlined,
                      color: Color(0xFF7E57C2),
                      size: 20,
                    ),

                    const SizedBox(width: 10),

                    const Expanded(
                      child: Text(
                        'Crowd Comfort',
                        style: TextStyle(
                          color: TourFlowColors.body,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    Text(
                      '$crowdComfort/5',
                      style: const TextStyle(
                        color: TourFlowColors.heading,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // TAGS
              // ==================================================

              if (tags.isNotEmpty) ...[
                const SizedBox(height: 20),

                const Text(
                  'What you liked',
                  style: TextStyle(
                    color: TourFlowColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 9),

                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: tags.map((tag) {
                    return _FeedbackTag(
                      label: tag,
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 20),

              // ==================================================
              // COMMENT
              // ==================================================

              const Text(
                'Your Comment',
                style: TextStyle(
                  color: TourFlowColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  comment.isEmpty
                      ? 'No written comment.'
                      : comment,
                  style: const TextStyle(
                    color: TourFlowColors.body,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Divider(
                height: 1,
              ),

              const SizedBox(height: 13),

              // ==================================================
              // SUBMITTED DATE
              // ==================================================

              Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 16,
                    color: Color(0xFF2E7D32),
                  ),

                  const SizedBox(width: 7),

                  Text(
                    submittedDate.isEmpty
                        ? 'Feedback submitted'
                        : 'Submitted $submittedDate',
                    style: const TextStyle(
                      color: TourFlowColors.muted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ======================================================
        // BACK BUTTON
        // ======================================================

        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(
                context,
                '/feedback-centre',
              );
            },
            child: const Text(
              'Back to Feedback Centre',
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================================
// FEEDBACK TAG
// ==========================================================

class _FeedbackTag extends StatelessWidget {
  const _FeedbackTag({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF8A5A00),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}