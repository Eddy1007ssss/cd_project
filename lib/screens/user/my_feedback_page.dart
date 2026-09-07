import 'package:flutter/material.dart';

import '../../models/engagement_models.dart';
import '../../repositories/engagement_repository.dart';
import '../../widgets/tourflow_widgets.dart';

class MyFeedbackPage extends StatefulWidget {
  const MyFeedbackPage({super.key});

  static const routeName = '/my-feedback';

  @override
  State<MyFeedbackPage> createState() => _MyFeedbackPageState();
}

class _MyFeedbackPageState extends State<MyFeedbackPage> {
  final _repository = EngagementRepository();
  late Future<List<FeedbackEntry>> _feedback;

  @override
  void initState() {
    super.initState();
    _feedback = _repository.fetchMyFeedback();
  }

  void _retry() {
    setState(() {
      _feedback = _repository.fetchMyFeedback();
    });
  }

  @override
  Widget build(BuildContext context) {
    return TourFlowPage(
      title: 'My Feedback',
      role: 'TOURIST',
      selectedNavigationIndex: 4,
      child: FutureBuilder<List<FeedbackEntry>>(
        future: _feedback,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 50),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return _ErrorState(
              error: snapshot.error.toString(),
              onRetry: _retry,
            );
          }

          final entries = snapshot.data ?? const [];

          if (entries.isEmpty) {
            return const _EmptyState();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...entries.map(
                    (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _FeedbackCard(entry: entry),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FeedbackSummary extends StatelessWidget {
  const _FeedbackSummary({
    required this.count,
    required this.onRefresh,
  });

  final int count;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE1E6F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE8ECFA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.rate_review_outlined,
              color: Color(0xFF5C6FD6),
              size: 20,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Feedback',
                  style: TextStyle(
                    color: Color(0xFF101828),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$count feedback ${count == 1 ? 'submission' : 'submissions'}',
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),

          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onRefresh,
              borderRadius: BorderRadius.circular(9),
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: const Color(0xFFDDE2EA),
                  ),
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFF667085),
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.entry,
  });

  final FeedbackEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE1E5EA),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF1FA),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.place_outlined,
                  color: Color(0xFF5C6FD6),
                  size: 22,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.attractionName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF101828),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Booking ${entry.bookingCode}',
                      style: const TextStyle(
                        color: Color(0xFF98A2B3),
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFECF8F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF2E9C5F),
                      size: 12,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Submitted',
                      style: TextStyle(
                        color: Color(0xFF278653),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF2),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: const Color(0xFFF4E8C9),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overall Rating',
                        style: TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),

                      Row(
                        children: List.generate(
                          5,
                              (index) => Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: Icon(
                              index < entry.overallRating
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: const Color(0xFFF2A900),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: const Color(0xFFF0E1BA),
                    ),
                  ),
                  child: Text(
                    '${entry.overallRating}/5',
                    style: const TextStyle(
                      color: Color(0xFF7A5A00),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F5FC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFE9E3F4),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 29,
                  height: 29,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEAF8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.groups_outlined,
                    size: 16,
                    color: Color(0xFF7357B8),
                  ),
                ),

                const SizedBox(width: 9),

                const Expanded(
                  child: Text(
                    'Crowd Comfort',
                    style: TextStyle(
                      color: Color(0xFF475467),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                Text(
                  '${entry.crowdComfort}/5',
                  style: const TextStyle(
                    color: Color(0xFF101828),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          if (entry.tags.isNotEmpty) ...[
            const SizedBox(height: 15),

            const Text(
              'Highlights',
              style: TextStyle(
                color: Color(0xFF475467),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: entry.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6FA),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE2E6EC),
                    ),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: Color(0xFF475467),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          if (entry.comment.isNotEmpty) ...[
            const SizedBox(height: 15),

            const Text(
              'Your Comment',
              style: TextStyle(
                color: Color(0xFF475467),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFE9ECF0),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.format_quote_rounded,
                    color: Color(0xFF98A2B3),
                    size: 17,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      entry.comment,
                      style: const TextStyle(
                        color: Color(0xFF475467),
                        fontSize: 10.5,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          const Divider(
            height: 1,
            color: Color(0xFFEAECF0),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 14,
                color: Color(0xFF98A2B3),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Submitted ${_formatDate(entry.createdAt)}',
                  style: const TextStyle(
                    color: Color(0xFF98A2B3),
                    fontSize: 8.8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ModuleCard(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            const SizedBox(height: 15),

            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFFEEF1FA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.rate_review_outlined,
                color: Color(0xFF5C6FD6),
                size: 29,
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              'No feedback submitted yet',
              style: TextStyle(
                color: Color(0xFF101828),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 7),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Your submitted attraction ratings and feedback will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 10,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ModuleCard(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            const SizedBox(height: 10),

            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFE5484D),
              size: 38,
            ),

            const SizedBox(height: 12),

            const Text(
              'Unable to load feedback',
              style: TextStyle(
                color: Color(0xFF101828),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 9.5,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 16,
              ),
              label: const Text('Retry'),
            ),

            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final local = date.toLocal();

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final hour = local.hour == 0
      ? 12
      : local.hour > 12
      ? local.hour - 12
      : local.hour;

  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';

  return '${local.day} ${months[local.month - 1]} ${local.year} · '
      '$hour:$minute $period';
}