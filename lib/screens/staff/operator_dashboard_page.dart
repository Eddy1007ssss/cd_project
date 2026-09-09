import 'package:flutter/material.dart';

import '../../models/engagement_models.dart';
import '../../repositories/engagement_repository.dart';
import '../../widgets/tourflow_widgets.dart';
import '../../widgets/navigation/navigation_routes.dart';
import '../../widgets/navigation/navigation_scope.dart';
import 'attraction_details_page.dart';
import 'operator_live_crowd_page.dart';
import 'slot_manager_page.dart';

class OperatorDashboardPage extends StatefulWidget {
  const OperatorDashboardPage({super.key});

  static const routeName = TourFlowRoutes.operatorDashboard;

  @override
  State<OperatorDashboardPage> createState() => _OperatorDashboardPageState();
}

class _OperatorDashboardPageState extends State<OperatorDashboardPage> {
  final _repository = EngagementRepository();

  late Future<List<OperatorFeedbackEntry>> _feedback;
  late Future<List<VisitorTrendEntry>> _visitorTrends;
  late Future<List<RevenueEntry>> _revenue;
  late Future<List<ManagedAttractionSummary>> _attractions;
  String _attractionStatus = 'all';
  bool _showAllAttractions = false;

  @override
  void initState() {
    super.initState();

    _feedback = _repository.fetchOperatorFeedback();
    _visitorTrends = _repository.fetchOperatorVisitorTrends();
    _revenue = _repository.fetchOperatorRevenue();
    _attractions = _repository.fetchOperatorAttractions();
  }

  double _currentMonthRevenue(List<RevenueEntry> entries) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month, now.day + 1);

    return entries
        .where(
          (entry) =>
              !entry.completedAt.isBefore(start) &&
              entry.completedAt.isBefore(end),
        )
        .fold<double>(0.0, (sum, entry) => sum + entry.revenue);
  }

  double _previousMonthToDateRevenue(List<RevenueEntry> entries) {
    final now = DateTime.now();

    final previousMonth = DateTime(now.year, now.month - 1, 1);

    final daysInPreviousMonth = DateTime(
      previousMonth.year,
      previousMonth.month + 1,
      0,
    ).day;

    final comparisonDay = now.day > daysInPreviousMonth
        ? daysInPreviousMonth
        : now.day;

    final start = DateTime(previousMonth.year, previousMonth.month, 1);

    final end = DateTime(
      previousMonth.year,
      previousMonth.month,
      comparisonDay + 1,
    );

    return entries
        .where(
          (entry) =>
              !entry.completedAt.isBefore(start) &&
              entry.completedAt.isBefore(end),
        )
        .fold<double>(0.0, (sum, entry) => sum + entry.revenue);
  }

  String _revenueChangeNote(List<RevenueEntry> entries) {
    final current = _currentMonthRevenue(entries);
    final previous = _previousMonthToDateRevenue(entries);

    if (previous == 0) {
      if (current > 0) {
        return '+RM ${current.toStringAsFixed(0)} vs prev.';
      }

      return 'No revenue';
    }

    final percentage = ((current - previous) / previous) * 100;

    if (percentage > 0) {
      return '+${percentage.toStringAsFixed(1)}% vs prev.';
    }

    if (percentage < 0) {
      return '${percentage.toStringAsFixed(1)}% vs prev.';
    }

    return 'No change';
  }

  double _averageRating(List<OperatorFeedbackEntry> entries) {
    if (entries.isEmpty) {
      return 0.0;
    }

    final total = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.overallRating,
    );

    return total / entries.length;
  }

  int _currentMonthVisitors(List<VisitorTrendEntry> entries) {
    final now = DateTime.now();

    return entries
        .where(
          (entry) =>
              entry.checkedInAt.year == now.year &&
              entry.checkedInAt.month == now.month,
        )
        .fold<int>(0, (sum, entry) => sum + entry.visitorCount);
  }

  String _visitorChangeNote(List<VisitorTrendEntry> entries) {
    return 'This month';
  }

  Map<String, int> _buildDashboardVisitorTrend(
    List<VisitorTrendEntry> entries,
  ) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final startDate = today.subtract(const Duration(days: 6));

    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final data = <String, int>{};

    for (var i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));

      final label = dayNames[date.weekday - 1];

      data[label] = 0;
    }

    for (final entry in entries) {
      final date = DateTime(
        entry.checkedInAt.year,
        entry.checkedInAt.month,
        entry.checkedInAt.day,
      );

      if (date.isBefore(startDate) || date.isAfter(today)) {
        continue;
      }

      final label = dayNames[date.weekday - 1];

      data[label] = (data[label] ?? 0) + entry.visitorCount;
    }

    return data;
  }

  int _last7DaysVisitors(List<VisitorTrendEntry> entries) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final startDate = today.subtract(const Duration(days: 6));

    return entries
        .where((entry) {
          final date = DateTime(
            entry.checkedInAt.year,
            entry.checkedInAt.month,
            entry.checkedInAt.day,
          );

          return !date.isBefore(startDate) && !date.isAfter(today);
        })
        .fold<int>(0, (sum, entry) => sum + entry.visitorCount);
  }

  Future<void> _openVisitorStatistics() async {
    await Navigator.pushNamed(context, '/visitor-statistics');

    if (!mounted) return;

    setState(() {
      _visitorTrends = _repository.fetchOperatorVisitorTrends();
    });
  }

  @override
  Widget build(BuildContext context) {
    return TourFlowPage(
      title: 'Operator Dashboard',
      role: 'TOURFLOW · OPERATOR',
      navigationRole: TourFlowNavigationRole.operator,
      pageLevel: TourFlowPageLevel.topLevel,
      selectedNavigationIndex: 0,
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ModuleCard(
            color: TourFlowColors.lavender,
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good morning, Alex',
                        style: TextStyle(
                          color: TourFlowColors.heading,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Manage attractions, visitor capacity and daily operations.',
                        style: TextStyle(
                          color: TourFlowColors.muted,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: TourFlowColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: TourFlowColors.primaryText,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          PrimaryButton(
            label: 'Register New Attraction',
            icon: Icons.add_location_alt_outlined,
            onPressed: () {
              selectNavigationTabOrPush(
                context,
                index: 1,
                routeName: AttractionDetailsPage.routeName,
              );
            },
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 112,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/revenue-promotion');
                    },
                    child: FutureBuilder<List<RevenueEntry>>(
                      future: _revenue,
                      builder: (context, snapshot) {
                        final entries = snapshot.data ?? const <RevenueEntry>[];

                        final revenue = _currentMonthRevenue(entries);

                        final note = _revenueChangeNote(entries);

                        return MetricCard(
                          label: 'Total Revenue',
                          value: 'RM ${revenue.toStringAsFixed(2)}',
                          icon: Icons.payments_outlined,
                          note: note,
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: SizedBox(
                  height: 112,
                  child: FutureBuilder<List<VisitorTrendEntry>>(
                    future: _visitorTrends,
                    builder: (context, snapshot) {
                      final entries =
                          snapshot.data ?? const <VisitorTrendEntry>[];

                      final total = _currentMonthVisitors(entries);

                      final note = _visitorChangeNote(entries);

                      return MetricCard(
                        label: 'Total Visitors',
                        value: '$total',
                        icon: Icons.groups_outlined,
                        note: note,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 112,
                  child: GestureDetector(
                    onTap: () async {
                      await Navigator.pushNamed(context, '/operator-feedback');

                      if (!mounted) return;

                      setState(() {
                        _feedback = _repository.fetchOperatorFeedback();
                      });
                    },
                    child: FutureBuilder<List<OperatorFeedbackEntry>>(
                      future: _feedback,
                      builder: (context, snapshot) {
                        final entries = snapshot.data ?? const [];

                        final average = _averageRating(entries);

                        return MetricCard(
                          label: 'Average Rating',
                          value: '${average.toStringAsFixed(1)} / 5.0',
                          icon: Icons.star_outline_rounded,
                          note: '${entries.length} tourist reviews',
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: SizedBox(
                  height: 112,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        OperatorLiveCrowdPage.routeName,
                      );
                    },
                    child: const MetricCard(
                      label: 'Live Crowd',
                      value: 'Open',
                      icon: Icons.groups_outlined,
                      note: 'Live crowd status',
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          FutureBuilder<List<VisitorTrendEntry>>(
            future: _visitorTrends,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done &&
                  !snapshot.hasData) {
                return const ModuleCard(
                  child: SizedBox(
                    height: 125,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              if (snapshot.hasError) {
                return ModuleCard(
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: TourFlowColors.muted,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Unable to load visitor trends.',
                          style: TextStyle(
                            color: TourFlowColors.muted,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _visitorTrends = _repository
                                  .fetchOperatorVisitorTrends();
                            });
                          },
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final entries = snapshot.data ?? const <VisitorTrendEntry>[];

              final trend = _buildDashboardVisitorTrend(entries);

              final sevenDayTotal = _last7DaysVisitors(entries);

              return GestureDetector(
                onTap: _openVisitorStatistics,
                child: ModuleCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Visitor Trends',
                                  style: TextStyle(
                                    color: TourFlowColors.heading,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Last 7 days',
                                  style: TextStyle(
                                    color: TourFlowColors.muted,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '$sevenDayTotal visitors',
                            style: const TextStyle(
                              color: Color(0xFF8A5A00),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: TourFlowColors.muted,
                            size: 18,
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        height: 105,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _DashboardVisitorTrendPainter(data: trend),
                        ),
                      ),

                      if (sevenDayTotal == 0) ...[
                        const SizedBox(height: 6),
                        const Center(
                          child: Text(
                            'No check-ins recorded in the last 7 days.',
                            style: TextStyle(
                              color: TourFlowColors.muted,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 22),

          FutureBuilder<List<ManagedAttractionSummary>>(
            future: _attractions,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const ModuleCard(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return ModuleCard(
                  child: Column(
                    children: [
                      const Text('Could not load your attractions.'),
                      TextButton(
                        onPressed: () => setState(() {
                          _attractions = _repository.fetchOperatorAttractions();
                        }),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final attractions = snapshot.data ?? const [];
              const statuses = [
                'all',
                'draft',
                'pending',
                'approved',
                'rejected',
                'suspended',
              ];
              final filtered = _attractionStatus == 'all'
                  ? attractions
                  : attractions
                        .where(
                          (item) => item.listingStatus == _attractionStatus,
                        )
                        .toList();
              final visible = _showAllAttractions
                  ? filtered
                  : filtered.take(3).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SectionTitle('Your Attractions'),
                      if (filtered.length > 3)
                        TextButton(
                          onPressed: () => setState(
                            () => _showAllAttractions = !_showAllAttractions,
                          ),
                          child: Text(
                            _showAllAttractions ? 'Show less' : 'View all',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: statuses
                          .where((status) {
                            return status == 'all' ||
                                attractions.any(
                                  (item) => item.listingStatus == status,
                                );
                          })
                          .map((status) {
                            final count = status == 'all'
                                ? attractions.length
                                : attractions
                                      .where(
                                        (item) => item.listingStatus == status,
                                      )
                                      .length;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text('${_title(status)} ($count)'),
                                selected: _attractionStatus == status,
                                onSelected: (_) => setState(() {
                                  _attractionStatus = status;
                                  _showAllAttractions = false;
                                }),
                              ),
                            );
                          })
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (visible.isEmpty)
                    const ModuleCard(
                      child: Text('No attractions match this status.'),
                    )
                  else
                    ...visible.map(
                      (attraction) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AttractionSummaryCard(
                          name: attraction.name,
                          location: attraction.locationName,
                          visitors: attraction.listingStatus == 'approved'
                              ? 'Published attraction'
                              : 'Not yet published',
                          rating: '—',
                          status: attraction.listingStatus.toUpperCase(),
                          statusColor: _listingStatusColor(
                            attraction.listingStatus,
                          ),
                          icon: Icons.attractions_rounded,
                          onTap: () => selectNavigationTabOrPush(
                            context,
                            index: 1,
                            routeName: AttractionDetailsPage.routeName,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: OutlineActionButton(
              label: 'Open Slot Manager',
              icon: Icons.schedule_rounded,
              onPressed: () {
                selectNavigationTabOrPush(
                  context,
                  index: 2,
                  routeName: SlotManagerPage.routeName,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _title(String value) => value.isEmpty
    ? value
    : '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';

Color _listingStatusColor(String status) => switch (status) {
  'approved' => TourFlowColors.success,
  'pending' => TourFlowColors.warning,
  'rejected' || 'suspended' => TourFlowColors.danger,
  _ => TourFlowColors.muted,
};

class _DashboardVisitorTrendPainter extends CustomPainter {
  const _DashboardVisitorTrendPainter({required this.data});

  final Map<String, int> data;

  @override
  void paint(Canvas canvas, Size size) {
    final entries = data.entries.toList();

    if (entries.isEmpty) {
      return;
    }

    const leftPadding = 26.0;
    const rightPadding = 8.0;
    const topPadding = 6.0;
    const bottomPadding = 22.0;

    final chartWidth = size.width - leftPadding - rightPadding;

    final chartHeight = size.height - topPadding - bottomPadding;

    final maxValue = entries.fold<int>(
      0,
      (max, entry) => entry.value > max ? entry.value : max,
    );

    final safeMax = maxValue == 0 ? 1 : maxValue;

    final gridPaint = Paint()
      ..color = const Color(0xFFE9EDF2)
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color = const Color(0xFFFF9800)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pointPaint = Paint()
      ..color = const Color(0xFFFF9800)
      ..style = PaintingStyle.fill;

    for (var i = 0; i <= 3; i++) {
      final y = topPadding + chartHeight * i / 3;

      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );
    }

    final points = <Offset>[];

    for (var i = 0; i < entries.length; i++) {
      final x = leftPadding + chartWidth * i / (entries.length - 1);

      final ratio = entries[i].value / safeMax;

      final y = topPadding + chartHeight * (1 - ratio);

      points.add(Offset(x, y));
    }

    if (points.length > 1) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);

      for (var i = 1; i < points.length; i++) {
        final previous = points[i - 1];
        final current = points[i];

        final controlX = (previous.dx + current.dx) / 2;

        path.cubicTo(
          controlX,
          previous.dy,
          controlX,
          current.dy,
          current.dx,
          current.dy,
        );
      }

      canvas.drawPath(path, linePaint);
    }

    for (var i = 0; i < points.length; i++) {
      if (entries[i].value > 0) {
        canvas.drawCircle(points[i], 3.5, pointPaint);
      }

      final labelPainter = TextPainter(
        text: TextSpan(
          text: entries[i].key,
          style: const TextStyle(
            color: Color(0xFF98A2B3),
            fontSize: 7,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      labelPainter.paint(
        canvas,
        Offset(
          points[i].dx - labelPainter.width / 2,
          size.height - bottomPadding + 8,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashboardVisitorTrendPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

class _AttractionSummaryCard extends StatelessWidget {
  const _AttractionSummaryCard({
    required this.name,
    required this.location,
    required this.visitors,
    required this.rating,
    required this.status,
    required this.statusColor,
    required this.icon,
    required this.onTap,
  });

  final String name;
  final String location;
  final String visitors;
  final String rating;
  final String status;
  final Color statusColor;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ModuleCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: TourFlowColors.lavenderStrong,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: TourFlowColors.primaryText, size: 32),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: TourFlowColors.heading,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: StatusChip(label: status, color: statusColor),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      location,
                      style: const TextStyle(
                        color: TourFlowColors.muted,
                        fontSize: 10,
                      ),
                    ),

                    const SizedBox(height: 9),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            visitors,
                            style: const TextStyle(
                              color: TourFlowColors.body,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.star_rounded,
                          color: TourFlowColors.warning,
                          size: 15,
                        ),
                        Text(
                          rating,
                          style: const TextStyle(
                            color: TourFlowColors.heading,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
