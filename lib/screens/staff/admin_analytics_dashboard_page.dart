import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/navigation/navigation_routes.dart';
import '../../widgets/tourflow_widgets.dart';

class AdminAnalyticsDashboardPage extends StatefulWidget {
  const AdminAnalyticsDashboardPage({super.key});

  static const routeName = TourFlowRoutes.adminAnalyticsDashboard;

  @override
  State<AdminAnalyticsDashboardPage> createState() => _AdminAnalyticsDashboardPageState();
}

class _AdminAnalyticsDashboardPageState extends State<AdminAnalyticsDashboardPage> {
  final _client = Supabase.instance.client;
  late Future<_AdminDashboardData> _dashboard;

  @override
  void initState() {
    super.initState();
    _dashboard = _loadDashboard();
  }

  Future<_AdminDashboardData> _loadDashboard() async {
    final checkInRows = await _client
        .from('attraction_check_ins')
        .select(
      'booking_id, checked_in_at, '
          'attraction:attractions(id, name), '
          'booking:bookings(visitor_count, slot_id)',
    )
        .order('checked_in_at', ascending: false);

    final feedbackRows = await _client.from('feedback').select('overall_rating');

    final slotRows = await _client
        .from('attraction_slots')
        .select('id, maximum_capacity');

    final visitorEvents = <_VisitorEvent>[];
    final seenBookings = <String>{};

    for (final row in checkInRows) {
      final bookingId = row['booking_id']?.toString() ?? '';

      if (bookingId.isNotEmpty && seenBookings.contains(bookingId)) {
        continue;
      }

      if (bookingId.isNotEmpty) {
        seenBookings.add(bookingId);
      }

      final attraction = (row['attraction'] as Map?)?.cast<String, dynamic>();
      final booking = (row['booking'] as Map?)?.cast<String, dynamic>();

      final checkedInAtValue = row['checked_in_at'];
      if (checkedInAtValue == null) continue;

      visitorEvents.add(
        _VisitorEvent(
          attractionId: attraction?['id']?.toString() ?? '',
          attractionName: attraction?['name']?.toString() ?? 'Unknown Attraction',
          slotId: booking?['slot_id']?.toString() ?? '',
          visitors: (booking?['visitor_count'] as num?)?.toInt() ?? 1,
          checkedInAt: DateTime.parse(checkedInAtValue.toString()).toLocal(),
        ),
      );
    }

    final totalVisitors = visitorEvents.fold<int>(
      0,
          (sum, event) => sum + event.visitors,
    );

    double averageRating = 0.0;

    if (feedbackRows.isNotEmpty) {
      final validRatings = feedbackRows
          .map((row) => (row['overall_rating'] as num?)?.toDouble())
          .whereType<double>()
          .toList();

      if (validRatings.isNotEmpty) {
        averageRating = validRatings.reduce((a, b) => a + b) / validRatings.length;
      }
    }

    final capacityBySlot = <String, int>{};

    for (final row in slotRows) {
      final slotId = row['id']?.toString() ?? '';
      final maximumCapacity = (row['maximum_capacity'] as num?)?.toInt() ?? 0;

      if (slotId.isNotEmpty && maximumCapacity > 0) {
        capacityBySlot[slotId] = maximumCapacity;
      }
    }

    final visitorsBySlot = <String, int>{};

    for (final event in visitorEvents) {
      if (event.slotId.isEmpty) continue;

      visitorsBySlot[event.slotId] =
          (visitorsBySlot[event.slotId] ?? 0) + event.visitors;
    }

    final occupancyValues = <double>[];

    visitorsBySlot.forEach((slotId, visitors) {
      final capacity = capacityBySlot[slotId];

      if (capacity != null && capacity > 0) {
        final occupancy = (visitors / capacity).clamp(0.0, 1.0).toDouble();
        occupancyValues.add(occupancy);
      }
    });

    final double averageOccupancy = occupancyValues.isEmpty
        ? 0.0
        : occupancyValues.reduce((a, b) => a + b) / occupancyValues.length;

    final attractionVisitors = <String, _TopAttraction>{};

    for (final event in visitorEvents) {
      if (event.attractionId.isEmpty) continue;

      final existing = attractionVisitors[event.attractionId];

      if (existing == null) {
        attractionVisitors[event.attractionId] = _TopAttraction(
          name: event.attractionName,
          visitors: event.visitors,
        );
      } else {
        attractionVisitors[event.attractionId] = _TopAttraction(
          name: existing.name,
          visitors: existing.visitors + event.visitors,
        );
      }
    }

    final topAttractions = attractionVisitors.values.toList()
      ..sort((a, b) => b.visitors.compareTo(a.visitors));

    return _AdminDashboardData(
      totalVisitors: totalVisitors,
      averageOccupancy: averageOccupancy,
      averageRating: averageRating,
      visitorTrend: _buildLast8Months(visitorEvents),
      topAttractions: topAttractions.take(5).toList(),
    );
  }

  List<_MonthlyVisitors> _buildLast8Months(List<_VisitorEvent> events) {
    final now = DateTime.now();
    final result = <_MonthlyVisitors>[];

    for (var i = 7; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(month.year, month.month + 1, 1);

      final visitors = events
          .where(
            (event) =>
        !event.checkedInAt.isBefore(month) &&
            event.checkedInAt.isBefore(nextMonth),
      )
          .fold<int>(0, (sum, event) => sum + event.visitors);

      result.add(
        _MonthlyVisitors(
          date: month,
          visitors: visitors,
        ),
      );
    }

    return result;
  }

  String _formatNumber(int value) {
    final text = value.toString();
    final result = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      final remaining = text.length - i;
      result.write(text[i]);

      if (remaining > 1 && remaining % 3 == 1) {
        result.write(',');
      }
    }

    return result.toString();
  }

  void _refresh() {
    setState(() {
      _dashboard = _loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return TourFlowPage(
      title: 'Analytics Dashboard',
      role: 'TOURFLOW · ADMINISTRATOR',
      navigationRole: TourFlowNavigationRole.administrator,
      pageLevel: TourFlowPageLevel.topLevel,
      selectedNavigationIndex: 0,
      child: FutureBuilder<_AdminDashboardData>(
        future: _dashboard,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 70),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return ModuleCard(
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.redAccent,
                    size: 30,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Unable to load analytics.',
                    style: TextStyle(
                      color: TourFlowColors.heading,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: TourFlowColors.muted,
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded, size: 17),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Overview',
                style: TextStyle(
                  color: TourFlowColors.heading,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Overall attraction performance',
                style: TextStyle(
                  color: TourFlowColors.muted,
                  fontSize: 9.5,
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.groups_rounded,
                      value: _formatNumber(data.totalVisitors),
                      label: 'Total Visitors',
                      iconBackground: const Color(0xFFEAF1FF),
                      iconColor: const Color(0xFF536FDC),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.pie_chart_outline_rounded,
                      value:
                      '${(data.averageOccupancy * 100).toStringAsFixed(0)}%',
                      label: 'Avg. Occupancy',
                      iconBackground: const Color(0xFFFFEDF4),
                      iconColor: const Color(0xFFD9578C),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.star_rounded,
                      value: data.averageRating == 0
                          ? '-'
                          : data.averageRating.toStringAsFixed(1),
                      label: 'Avg. Rating',
                      iconBackground: const Color(0xFFFFF5DD),
                      iconColor: const Color(0xFFE6A01C),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              ModuleCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF1FF),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.show_chart_rounded,
                            color: Color(0xFF5C6DDF),
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Visitors Over Time',
                                style: TextStyle(
                                  color: TourFlowColors.heading,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Monthly visitor trends',
                                style: TextStyle(
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
                            color: const Color(0xFFF5F6F8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Last 8 Months',
                            style: TextStyle(
                              color: TourFlowColors.body,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 190,
                      child: CustomPaint(
                        painter: _VisitorChartPainter(
                          data: data.visitorTrend,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              ModuleCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4DF),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.emoji_events_outlined,
                            color: Color(0xFFD68B00),
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Top Attractions',
                              style: TextStyle(
                                color: TourFlowColors.heading,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Ranked by total visitors',
                              style: TextStyle(
                                color: TourFlowColors.muted,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if (data.topAttractions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 22),
                        child: Center(
                          child: Text(
                            'No visitor data available.',
                            style: TextStyle(
                              color: TourFlowColors.muted,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      )
                    else
                      ...List.generate(
                        data.topAttractions.length,
                            (index) {
                          final attraction = data.topAttractions[index];
                          final maxVisitors = data.topAttractions.first.visitors;

                          return _AttractionRankingRow(
                            rank: index + 1,
                            name: attraction.name,
                            visitors: attraction.visitors,
                            visitorText: _formatNumber(attraction.visitors),
                            progress: maxVisitors == 0
                                ? 0
                                : attraction.visitors / maxVisitors,
                          );
                        },
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              _GenerateReportCard(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    TourFlowRoutes.adminGenerateReport,
                  );
                },
              ),

              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconBackground,
    required this.iconColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color iconBackground;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE4E7EC),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  color: TourFlowColors.heading,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: TourFlowColors.muted,
              fontSize: 7.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttractionRankingRow extends StatelessWidget {
  const _AttractionRankingRow({
    required this.rank,
    required this.name,
    required this.visitors,
    required this.visitorText,
    required this.progress,
  });

  final int rank;
  final String name;
  final int visitors;
  final String visitorText;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            width: 27,
            height: 27,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? const Color(0xFFFFF1D8)
                  : const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                color: rank <= 3
                    ? const Color(0xFFAA7000)
                    : TourFlowColors.muted,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: TourFlowColors.heading,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      visitorText,
                      style: const TextStyle(
                        color: TourFlowColors.heading,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 7),

                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: const Color(0xFFF0F2F5),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFFFC66D),
                    ),
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

class _GenerateReportCard extends StatelessWidget {
  const _GenerateReportCard({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF5E5),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFFFDFAD),
            ),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 38,
                height: 38,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFFFFE7BD),
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    color: Color(0xFF9A6500),
                    size: 20,
                  ),
                ),
              ),

              SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Generate Report',
                      style: TextStyle(
                        color: TourFlowColors.heading,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'View performance and sustainability reports',
                      style: TextStyle(
                        color: TourFlowColors.muted,
                        fontSize: 8.5,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFF9A6500),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisitorChartPainter extends CustomPainter {
  const _VisitorChartPainter({
    required this.data,
  });

  final List<_MonthlyVisitors> data;

  String _monthLabel(int month) {
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

    return months[month - 1];
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const leftPadding = 30.0;
    const rightPadding = 8.0;
    const topPadding = 10.0;
    const bottomPadding = 28.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;
    final bottomY = topPadding + chartHeight;

    final maxValue = data.fold<int>(
      0,
          (max, item) => item.visitors > max ? item.visitors : max,
    );

    final safeMax = maxValue == 0 ? 1 : maxValue;

    final gridPaint = Paint()
      ..color = const Color(0xFFE9ECF2)
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color = const Color(0xFF6578E7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pointPaint = Paint()
      ..color = const Color(0xFF6578E7)
      ..style = PaintingStyle.fill;

    for (var i = 0; i <= 3; i++) {
      final y = topPadding + chartHeight * i / 3;

      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );

      final value = (safeMax * (3 - i) / 3).round();

      final valuePainter = TextPainter(
        text: TextSpan(
          text: '$value',
          style: const TextStyle(
            color: Color(0xFF98A2B3),
            fontSize: 7,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      valuePainter.paint(
        canvas,
        Offset(
          leftPadding - valuePainter.width - 5,
          y - valuePainter.height / 2,
        ),
      );
    }

    final points = <Offset>[];

    for (var i = 0; i < data.length; i++) {
      final x = data.length == 1
          ? leftPadding + chartWidth / 2
          : leftPadding + chartWidth * i / (data.length - 1);

      final ratio = data[i].visitors / safeMax;
      final y = bottomY - ratio * chartHeight;

      points.add(
        Offset(x, y),
      );

      final labelPainter = TextPainter(
        text: TextSpan(
          text: _monthLabel(data[i].date.month),
          style: const TextStyle(
            color: Color(0xFF98A2B3),
            fontSize: 7,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      labelPainter.paint(
        canvas,
        Offset(
          x - labelPainter.width / 2,
          bottomY + 10,
        ),
      );
    }

    if (points.length > 1) {
      final linePath = Path()
        ..moveTo(
          points.first.dx,
          points.first.dy,
        );

      for (var i = 1; i < points.length; i++) {
        final previous = points[i - 1];
        final current = points[i];
        final controlX = (previous.dx + current.dx) / 2;

        linePath.cubicTo(
          controlX,
          previous.dy,
          controlX,
          current.dy,
          current.dx,
          current.dy,
        );
      }

      final fillPath = Path.from(linePath)
        ..lineTo(points.last.dx, bottomY)
        ..lineTo(points.first.dx, bottomY)
        ..close();

      final fillPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x356578E7),
            Color(0x006578E7),
          ],
        ).createShader(
          Rect.fromLTWH(
            leftPadding,
            topPadding,
            chartWidth,
            chartHeight,
          ),
        );

      canvas.drawPath(fillPath, fillPaint);
      canvas.drawPath(linePath, linePaint);
    }

    for (var i = 0; i < points.length; i++) {
      if (data[i].visitors > 0) {
        canvas.drawCircle(
          points[i],
          3.5,
          pointPaint,
        );

        canvas.drawCircle(
          points[i],
          1.5,
          Paint()..color = Colors.white,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _VisitorChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

class _AdminDashboardData {
  const _AdminDashboardData({
    required this.totalVisitors,
    required this.averageOccupancy,
    required this.averageRating,
    required this.visitorTrend,
    required this.topAttractions,
  });

  final int totalVisitors;
  final double averageOccupancy;
  final double averageRating;
  final List<_MonthlyVisitors> visitorTrend;
  final List<_TopAttraction> topAttractions;
}

class _VisitorEvent {
  const _VisitorEvent({
    required this.attractionId,
    required this.attractionName,
    required this.slotId,
    required this.visitors,
    required this.checkedInAt,
  });

  final String attractionId;
  final String attractionName;
  final String slotId;
  final int visitors;
  final DateTime checkedInAt;
}

class _MonthlyVisitors {
  const _MonthlyVisitors({
    required this.date,
    required this.visitors,
  });

  final DateTime date;
  final int visitors;
}

class _TopAttraction {
  const _TopAttraction({
    required this.name,
    required this.visitors,
  });

  final String name;
  final int visitors;
}