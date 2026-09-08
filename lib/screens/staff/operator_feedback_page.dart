import 'package:flutter/material.dart';

import '../../models/engagement_models.dart';
import '../../repositories/engagement_repository.dart';
import '../../widgets/tourflow_widgets.dart';

class OperatorFeedbackPage extends StatefulWidget {
  const OperatorFeedbackPage({super.key});

  static const routeName = '/operator-feedback';

  @override
  State<OperatorFeedbackPage> createState() => _OperatorFeedbackPageState();
}

class _OperatorFeedbackPageState extends State<OperatorFeedbackPage> {
  final _repository = EngagementRepository();
  late Future<List<OperatorFeedbackEntry>> _feedback;

  int? _ratingFilter;
  String? _attractionFilter;
  String _sort = 'newest';

  @override
  void initState() {
    super.initState();
    _feedback = _repository.fetchOperatorFeedback();
  }

  void _refresh() {
    setState(() {
      _feedback = _repository.fetchOperatorFeedback();
    });
  }

  List<OperatorFeedbackEntry> _prepareFeedback(
    List<OperatorFeedbackEntry> entries,
  ) {
    var result = [...entries];

    if (_attractionFilter != null) {
      result = result
          .where((entry) => entry.attractionName == _attractionFilter)
          .toList();
    }

    if (_ratingFilter != null) {
      result = result
          .where((entry) => entry.overallRating == _ratingFilter)
          .toList();
    }

    if (_sort == 'newest') {
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sort == 'oldest') {
      result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else if (_sort == 'highest') {
      result.sort((a, b) => b.overallRating.compareTo(a.overallRating));
    } else if (_sort == 'lowest') {
      result.sort((a, b) => a.overallRating.compareTo(b.overallRating));
    }

    return result;
  }

  int _todayCount(List<OperatorFeedbackEntry> entries) {
    final now = DateTime.now();

    return entries.where((entry) {
      final date = entry.createdAt;
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;
  }

  int _weekCount(List<OperatorFeedbackEntry> entries) {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));

    return entries.where((entry) => !entry.createdAt.isBefore(start)).length;
  }

  int _monthCount(List<OperatorFeedbackEntry> entries) {
    final now = DateTime.now();

    return entries.where((entry) {
      return entry.createdAt.year == now.year &&
          entry.createdAt.month == now.month;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return TourFlowPage(
      title: 'Tourist Feedback',
      role: 'TOURFLOW · OPERATOR',
      navigationRole: TourFlowNavigationRole.operator,
      selectedNavigationIndex: 5,
      child: FutureBuilder<List<OperatorFeedbackEntry>>(
        future: _feedback,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 50),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return _ErrorPanel(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }

          final allEntries = snapshot.data ?? const [];

          final attractionNames =
              allEntries.map((entry) => entry.attractionName).toSet().toList()
                ..sort();

          final entries = _prepareFeedback(allEntries);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _FeedbackSummaryCard(
                      label: 'Today',
                      value: '${_todayCount(allEntries)}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FeedbackSummaryCard(
                      label: 'This Week',
                      value: '${_weekCount(allEntries)}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FeedbackSummaryCard(
                      label: 'This Month',
                      value: '${_monthCount(allEntries)}',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              const Text(
                'Filter Feedback',
                style: TextStyle(
                  color: TourFlowColors.heading,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Attraction',
                style: TextStyle(
                  color: TourFlowColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 7),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE1E5EB)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _attractionFilter,
                    isExpanded: true,
                    hint: const Text(
                      'All Attractions',
                      style: TextStyle(fontSize: 11, color: Color(0xFF667085)),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          'All Attractions',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                      ...attractionNames.map(
                        (name) => DropdownMenuItem<String?>(
                          value: name,
                          child: Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _attractionFilter = value;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                'Rating',
                style: TextStyle(
                  color: TourFlowColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 7),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _RatingFilterChip(
                      label: 'All',
                      selected: _ratingFilter == null,
                      onTap: () {
                        setState(() {
                          _ratingFilter = null;
                        });
                      },
                    ),
                    const SizedBox(width: 7),
                    for (int rating = 5; rating >= 1; rating--) ...[
                      _RatingFilterChip(
                        label: '$rating ★',
                        selected: _ratingFilter == rating,
                        onTap: () {
                          setState(() {
                            _ratingFilter = rating;
                          });
                        },
                      ),
                      if (rating != 1) const SizedBox(width: 7),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tourist Feedback (${entries.length})',
                      style: const TextStyle(
                        color: TourFlowColors.heading,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  PopupMenuButton<String>(
                    tooltip: 'Sort feedback',
                    initialValue: _sort,
                    onSelected: (value) {
                      setState(() {
                        _sort = value;
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'newest',
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 17,
                              color: Color(0xFF667085),
                            ),
                            SizedBox(width: 9),
                            Text(
                              'Newest First',
                              style: TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'oldest',
                        child: Row(
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 17,
                              color: Color(0xFF667085),
                            ),
                            SizedBox(width: 9),
                            Text(
                              'Oldest First',
                              style: TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'highest',
                        child: Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 17,
                              color: Color(0xFFFFA000),
                            ),
                            SizedBox(width: 9),
                            Text(
                              'Highest Rating',
                              style: TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'lowest',
                        child: Row(
                          children: [
                            Icon(
                              Icons.star_border_rounded,
                              size: 17,
                              color: Color(0xFF667085),
                            ),
                            SizedBox(width: 9),
                            Text(
                              'Lowest Rating',
                              style: TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4E5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.swap_vert_rounded,
                        color: Color(0xFFFF9800),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              if (entries.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 30,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE1E5EB)),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.rate_review_outlined,
                        color: Color(0xFF98A2B3),
                        size: 35,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'No feedback available.',
                        style: TextStyle(
                          color: TourFlowColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

              for (final entry in entries) ...[
                _FeedbackCard(entry: entry),
                const SizedBox(height: 11),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _FeedbackSummaryCard extends StatelessWidget {
  const _FeedbackSummaryCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE3E7ED)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(color: TourFlowColors.muted, fontSize: 8.5),
          ),

          const SizedBox(height: 4),

          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF8A5A00),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingFilterChip extends StatelessWidget {
  const _RatingFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFA000) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? const Color(0xFFFFA000) : const Color(0xFFE1E5EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF667085),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.entry});

  final OperatorFeedbackEntry entry;

  @override
  Widget build(BuildContext context) {
    return ModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF4E5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Color(0xFFFF9800),
                  size: 20,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.touristName,
                      style: const TextStyle(
                        color: TourFlowColors.heading,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: index < entry.overallRating
                              ? const Color(0xFFFFA000)
                              : const Color(0xFFD9DDE3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                _dateLabel(entry.createdAt),
                style: const TextStyle(
                  color: TourFlowColors.muted,
                  fontSize: 9,
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Color(0xFF98A2B3),
                size: 15,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  entry.attractionName,
                  style: const TextStyle(
                    color: TourFlowColors.body,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          if (entry.bookingCode.isNotEmpty) ...[
            const SizedBox(height: 6),

            Text(
              'Booking: ${entry.bookingCode}',
              style: const TextStyle(color: TourFlowColors.muted, fontSize: 9),
            ),
          ],

          const SizedBox(height: 12),

          Text(
            entry.comment.trim().isEmpty
                ? 'No written comment.'
                : entry.comment,
            style: const TextStyle(
              color: TourFlowColors.body,
              fontSize: 11,
              height: 1.5,
            ),
          ),

          if (entry.tags.isNotEmpty) ...[
            const SizedBox(height: 12),

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
                    color: const Color(0xFFFFF8E8),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFFD98A)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: Color(0xFFB36A00),
                      ),

                      const SizedBox(width: 4),

                      Text(
                        tag,
                        style: const TextStyle(
                          color: Color(0xFFB36A00),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 13),

          const Divider(height: 1, color: Color(0xFFEAECF0)),

          const SizedBox(height: 10),

          Row(
            children: [
              const Text(
                'Crowd Comfort',
                style: TextStyle(
                  color: TourFlowColors.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const Spacer(),

              Row(
                children: [
                  const Icon(
                    Icons.people_outline_rounded,
                    size: 14,
                    color: Color(0xFFFF9800),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.crowdComfort}/5',
                    style: const TextStyle(
                      color: Color(0xFF8A5A00),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E5EB)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFFF5252),
            size: 30,
          ),

          const SizedBox(height: 10),

          const Text(
            'Unable to load feedback.',
            style: TextStyle(
              color: TourFlowColors.heading,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: TourFlowColors.muted, fontSize: 9),
          ),

          const SizedBox(height: 13),

          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

String _dateLabel(DateTime date) {
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

  return '${local.day} ${months[local.month - 1]} ${local.year}';
}
