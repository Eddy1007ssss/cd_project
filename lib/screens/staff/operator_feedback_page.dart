import 'package:flutter/material.dart';

import '../../widgets/tourflow_widgets.dart';

class OperatorFeedbackPage extends StatelessWidget {
  const OperatorFeedbackPage({super.key});

  static const routeName = '/operator-feedback';

  @override
  Widget build(BuildContext context) {
    return TourFlowPage(
      title: 'All Feedback',
      role: 'TOURFLOW · OPERATOR',
      isStaff: true,
      selectedNavigationIndex: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: _FeedbackSummaryCard(
                  label: 'Today',
                  value: '10',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _FeedbackSummaryCard(
                  label: 'This Week',
                  value: '75',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _FeedbackSummaryCard(
                  label: 'This Month',
                  value: '270',
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          const _FeedbackCard(
            username: 'weinee',
            attraction: 'National Museum',
            time: '8 days ago',
            rating: 4,
            comment: 'Such a beautiful place.',
          ),

          const SizedBox(height: 10),

          const _FeedbackCard(
            username: 'liqj09',
            attraction: 'Petronas Twin Tower',
            time: '3 weeks ago',
            rating: 4,
            comment: 'Beautiful places.',
            showImage: true,
          ),
        ],
      ),
    );
  }
}

class _FeedbackSummaryCard extends StatelessWidget {
  const _FeedbackSummaryCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE3E7ED),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: TourFlowColors.muted,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF8A5A00),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.username,
    required this.attraction,
    required this.time,
    required this.rating,
    required this.comment,
    this.showImage = false,
  });

  final String username;
  final String attraction;
  final String time;
  final int rating;
  final String comment;
  final bool showImage;

  @override
  Widget build(BuildContext context) {
    return ModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                username,
                style: const TextStyle(
                  color: TourFlowColors.heading,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(width: 8),

              Row(
                children: List.generate(
                  5,
                      (index) => Icon(
                    Icons.star_rounded,
                    size: 17,
                    color: index < rating
                        ? const Color(0xFFFFA000)
                        : const Color(0xFFD9DDE3),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            '$attraction · $time',
            style: const TextStyle(
              color: TourFlowColors.muted,
              fontSize: 9,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            comment,
            style: const TextStyle(
              color: TourFlowColors.body,
              fontSize: 11,
            ),
          ),

          if (showImage) ...[
            const SizedBox(height: 12),

            Container(
              width: 105,
              height: 85,
              decoration: BoxDecoration(
                color: TourFlowColors.lavender,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFE1E5EB),
                ),
              ),
              child: const Icon(
                Icons.image_outlined,
                size: 34,
                color: TourFlowColors.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}