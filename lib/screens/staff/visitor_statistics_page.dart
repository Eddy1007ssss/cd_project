import 'package:flutter/material.dart';

import '../../models/engagement_models.dart';
import '../../repositories/engagement_repository.dart';
import '../../widgets/tourflow_widgets.dart';

class VisitorStatisticsPage extends StatefulWidget {
  const VisitorStatisticsPage({super.key});

  static const routeName = '/visitor-statistics';

  @override
  State<VisitorStatisticsPage> createState() => _VisitorStatisticsPageState();
}

class _VisitorStatisticsPageState extends State<VisitorStatisticsPage> {
  final _repository = EngagementRepository();

  late Future<List<VisitorTrendEntry>> _visitorTrends;

  String _period = 'daily';
  String? _attractionFilter;

  @override
  void initState() {
    super.initState();
    _visitorTrends = _repository.fetchOperatorVisitorTrends();
  }

  List<VisitorTrendEntry> _filterByPeriod(List<VisitorTrendEntry> entries) {
    final now = DateTime.now();

    if (_period == 'daily') {
      return entries.where((entry) {
        final date = entry.checkedInAt;
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      }).toList();
    }

    if (_period == 'weekly') {
      final today = DateTime(now.year, now.month, now.day);
      final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      return entries.where((entry) {
        return !entry.checkedInAt.isBefore(startOfWeek) &&
            entry.checkedInAt.isBefore(endOfWeek);
      }).toList();
    }

    if (_period == 'monthly') {
      return entries.where((entry) {
        final date = entry.checkedInAt;
        return date.year == now.year && date.month == now.month;
      }).toList();
    }

    return entries;
  }

  List<VisitorTrendEntry> _filterPreviousPeriod(
      List<VisitorTrendEntry> entries,
      ) {
    final now = DateTime.now();

    if (_period == 'daily') {
      final yesterday = now.subtract(const Duration(days: 1));

      return entries.where((entry) {
        final date = entry.checkedInAt;
        return date.year == yesterday.year &&
            date.month == yesterday.month &&
            date.day == yesterday.day;
      }).toList();
    }

    if (_period == 'weekly') {
      final today = DateTime(now.year, now.month, now.day);
      final currentWeekStart = today.subtract(Duration(days: now.weekday - 1));
      final previousWeekStart = currentWeekStart.subtract(
        const Duration(days: 7),
      );

      return entries.where((entry) {
        return !entry.checkedInAt.isBefore(previousWeekStart) &&
            entry.checkedInAt.isBefore(currentWeekStart);
      }).toList();
    }

    if (_period == 'monthly') {
      final previousMonth = DateTime(now.year, now.month - 1);

      return entries.where((entry) {
        final date = entry.checkedInAt;
        return date.year == previousMonth.year &&
            date.month == previousMonth.month;
      }).toList();
    }

    return const [];
  }

  Map<String, int> _buildTrendData(List<VisitorTrendEntry> entries) {
    if (entries.isEmpty) return {};

    if (_period == 'daily') {
      final data = <String, int>{
        for (var hour = 0; hour < 24; hour++)
          '${hour.toString().padLeft(2, '0')}:00': 0,
      };

      for (final entry in entries) {
        final hour = entry.checkedInAt.hour;
        final label = '${hour.toString().padLeft(2, '0')}:00';
        data[label] = data[label]! + entry.visitorCount;
      }

      return data;
    }

    if (_period == 'weekly') {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final data = {for (final day in days) day: 0};

      for (final entry in entries) {
        final label = days[entry.checkedInAt.weekday - 1];
        data[label] = data[label]! + entry.visitorCount;
      }

      return data;
    }

    if (_period == 'monthly') {
      final now = DateTime.now();
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

      final data = <String, int>{
        for (var day = 1; day <= daysInMonth; day++) '$day': 0,
      };

      for (final entry in entries) {
        final label = '${entry.checkedInAt.day}';
        data[label] = data[label]! + entry.visitorCount;
      }

      return data;
    }

    return {};
  }

  void _refresh() {
    setState(() {
      _visitorTrends = _repository.fetchOperatorVisitorTrends();
    });
  }

  @override
  Widget build(BuildContext context) {
    return TourFlowPage(
      title: 'Visitor Statistics',
      role: 'TOURFLOW · OPERATOR',
      navigationRole: TourFlowNavigationRole.operator,
      pageLevel: TourFlowPageLevel.topLevel,
      selectedNavigationIndex: 5,
      child: FutureBuilder<List<VisitorTrendEntry>>(
        future: _visitorTrends,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 50),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return ModuleCard(
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFFF5252),
                    size: 32,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Unable to load visitor statistics.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: TourFlowColors.heading,
                      fontSize: 12,
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
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          final allEntries = snapshot.data ?? const <VisitorTrendEntry>[];

          if (allEntries.isEmpty) {
            return const ModuleCard(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(
                      Icons.groups_outlined,
                      size: 36,
                      color: TourFlowColors.muted,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'No visitor history is available yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: TourFlowColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final attractionNames =
          allEntries.map((entry) => entry.attractionName).toSet().toList()
            ..sort();

          final attractionFilteredEntries = _attractionFilter == null
              ? allEntries
              : allEntries
              .where(
                (entry) => entry.attractionName == _attractionFilter,
          )
              .toList();

          final filteredEntries = _filterByPeriod(attractionFilteredEntries);

          final previousEntries = _filterPreviousPeriod(
            attractionFilteredEntries,
          );

          final totalVisitors = filteredEntries.fold<int>(
            0,
                (sum, entry) => sum + entry.visitorCount,
          );

          final previousTotalVisitors = previousEntries.fold<int>(
            0,
                (sum, entry) => sum + entry.visitorCount,
          );

          final visitorChange = totalVisitors - previousTotalVisitors;

          final trendData = _buildTrendData(filteredEntries);

          final averageVisitors = trendData.isEmpty
              ? 0.0
              : totalVisitors / trendData.length;

          MapEntry<String, int>? peakEntry;

          if (trendData.isNotEmpty) {
            peakEntry = trendData.entries.reduce(
                  (current, next) => next.value > current.value ? next : current,
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.insights_outlined,
                      color: Color(0xFFFF9800),
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'View visitor trends based on actual attraction check-ins.',
                        style: TextStyle(
                          color: Color(0xFF8A5A00),
                          fontSize: 11,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

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
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF667085),
                      ),
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

              const SizedBox(height: 16),

              const Text(
                'Period',
                style: TextStyle(
                  color: TourFlowColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 7),

              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'daily',
                      label: Text(
                        'Daily',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                    ButtonSegment<String>(
                      value: 'weekly',
                      label: Text(
                        'Weekly',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                    ButtonSegment<String>(
                      value: 'monthly',
                      label: Text(
                        'Monthly',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                  selected: {_period},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _period = selection.first;
                    });
                  },
                ),
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 12,
                    color: TourFlowColors.muted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _periodDateLabel(_period),
                    style: const TextStyle(
                      color: TourFlowColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              ModuleCard(
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4E5),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.groups_outlined,
                        color: Color(0xFFFF9800),
                        size: 22,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Visitors',
                            style: TextStyle(
                              color: TourFlowColors.heading,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _periodLabel(_period),
                                style: const TextStyle(
                                  color: TourFlowColors.muted,
                                  fontSize: 9,
                                ),
                              ),
                              const SizedBox(height: 3),
                              _VisitorChangeIndicator(
                                change: visitorChange,
                                previousTotal: previousTotalVisitors,
                                period: _period,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Text(
                      '$totalVisitors',
                      style: const TextStyle(
                        color: Color(0xFF8A5A00),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 105,
                      child: ModuleCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.analytics_outlined,
                                  size: 17,
                                  color: Color(0xFF2563EB),
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Average Visitors',
                                    style: TextStyle(
                                      color: TourFlowColors.muted,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              averageVisitors.toStringAsFixed(1),
                              style: const TextStyle(
                                color: TourFlowColors.heading,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _averageLabel(_period),
                              style: const TextStyle(
                                color: TourFlowColors.muted,
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: SizedBox(
                      height: 105,
                      child: ModuleCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.trending_up_rounded,
                                  size: 17,
                                  color: Color(0xFFFF9800),
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Peak Period',
                                    style: TextStyle(
                                      color: TourFlowColors.muted,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              peakEntry == null
                                  ? '-'
                                  : _peakPeriodLabel(
                                _period,
                                peakEntry.key,
                              ),
                              style: const TextStyle(
                                color: TourFlowColors.heading,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              peakEntry == null
                                  ? 'No visitors'
                                  : '${peakEntry.value} visitors',
                              style: const TextStyle(
                                color: TourFlowColors.muted,
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _VisitorTrendChart(data: trendData),

              if (filteredEntries.isEmpty) ...[
                const SizedBox(height: 12),
                const ModuleCard(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: TourFlowColors.muted,
                          size: 19,
                        ),
                        SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'No check-ins were recorded for the selected period.',
                            style: TextStyle(
                              color: TourFlowColors.muted,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }
}

class _VisitorChangeIndicator extends StatelessWidget {
  const _VisitorChangeIndicator({
    required this.change,
    required this.previousTotal,
    required this.period,
  });

  final int change;
  final int previousTotal;
  final String period;

  @override
  Widget build(BuildContext context) {
    if (previousTotal == 0) {
      return Text(
        'No ${_comparisonLabel(period)} data',
        style: const TextStyle(
          color: TourFlowColors.muted,
          fontSize: 8,
        ),
      );
    }

    final isIncrease = change > 0;
    final isDecrease = change < 0;

    final icon = isIncrease
        ? Icons.arrow_upward_rounded
        : isDecrease
        ? Icons.arrow_downward_rounded
        : Icons.remove_rounded;

    final color = isIncrease
        ? const Color(0xFF16A34A)
        : isDecrease
        ? const Color(0xFFDC2626)
        : TourFlowColors.muted;

    return Row(
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(
          '${change.abs()} vs ${_comparisonLabel(period)}',
          style: TextStyle(
            color: color,
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _VisitorTrendChart extends StatelessWidget {
  const _VisitorTrendChart({
    required this.data,
  });

  final Map<String, int> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final entries = data.entries.toList();

    return ModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Visitor Trend',
            style: TextStyle(
              color: TourFlowColors.heading,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Visitors recorded during the selected period.',
            style: TextStyle(
              color: TourFlowColors.muted,
              fontSize: 9,
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            height: 190,
            width: double.infinity,
            child: CustomPaint(
              painter: _VisitorLineChartPainter(
                entries: entries,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitorLineChartPainter extends CustomPainter {
  const _VisitorLineChartPainter({
    required this.entries,
  });

  final List<MapEntry<String, int>> entries;

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    const leftPadding = 30.0;
    const rightPadding = 8.0;
    const topPadding = 18.0;
    const bottomPadding = 30.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    final maxValue = entries
        .map((entry) => entry.value)
        .fold<int>(
      0,
          (max, value) => value > max ? value : max,
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

    final pointBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var i = 0; i <= 4; i++) {
      final y = topPadding + chartHeight * i / 4;

      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );

      final value = (safeMax * (4 - i) / 4).round();

      final painter = TextPainter(
        text: TextSpan(
          text: '$value',
          style: const TextStyle(
            color: Color(0xFF98A2B3),
            fontSize: 7,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      painter.paint(
        canvas,
        Offset(
          leftPadding - painter.width - 6,
          y - painter.height / 2,
        ),
      );
    }

    final points = <Offset>[];
    final isDaily = entries.length == 24;

    for (var i = 0; i < entries.length; i++) {
      final x = entries.length == 1
          ? leftPadding + chartWidth / 2
          : leftPadding +
          chartWidth *
              i /
              (isDaily ? 24 : entries.length - 1);

      final ratio = entries[i].value / safeMax;
      final y = topPadding + chartHeight * (1 - ratio);

      points.add(Offset(x, y));
    }

    if (points.length > 1) {
      final path = Path()
        ..moveTo(
          points.first.dx,
          points.first.dy,
        );

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
      final point = points[i];

      if (entries[i].value > 0) {
        canvas.drawCircle(point, 4, pointPaint);
        canvas.drawCircle(point, 4, pointBorderPaint);
      }
    }

    for (var i = 0; i < entries.length; i++) {
      if (!_showLabel(i, entries.length)) continue;

      final point = points[i];

      final painter = TextPainter(
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

      var x = point.dx - painter.width / 2;

      if (x < leftPadding) {
        x = leftPadding;
      }

      if (x + painter.width > size.width - rightPadding) {
        x = size.width - rightPadding - painter.width;
      }

      painter.paint(
        canvas,
        Offset(
          x,
          size.height - bottomPadding + 8,
        ),
      );
    }

    if (isDaily) {
      final painter = TextPainter(
        text: const TextSpan(
          text: '24:00',
          style: TextStyle(
            color: Color(0xFF98A2B3),
            fontSize: 7,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      painter.paint(
        canvas,
        Offset(
          size.width - rightPadding - painter.width,
          size.height - bottomPadding + 8,
        ),
      );
    }
  }

  bool _showLabel(int index, int total) {
    if (total <= 7) return true;

    if (total == 24) {
      return index % 4 == 0;
    }

    return index == 0 ||
        index % 5 == 0 ||
        index == total - 1;
  }

  @override
  bool shouldRepaint(
      covariant _VisitorLineChartPainter oldDelegate,
      ) {
    return oldDelegate.entries != entries;
  }
}

String _periodLabel(String period) {
  return switch (period) {
    'daily' => 'Today',
    'weekly' => 'This week',
    'monthly' => 'This month',
    _ => '',
  };
}

String _averageLabel(String period) {
  return switch (period) {
    'daily' => 'per hour',
    'weekly' => 'per day',
    'monthly' => 'per day',
    _ => '',
  };
}

String _peakPeriodLabel(
    String period,
    String value,
    ) {
  if (period == 'daily') {
    return value;
  }

  if (period == 'weekly') {
    return switch (value) {
      'Mon' => 'Monday',
      'Tue' => 'Tuesday',
      'Wed' => 'Wednesday',
      'Thu' => 'Thursday',
      'Fri' => 'Friday',
      'Sat' => 'Saturday',
      'Sun' => 'Sunday',
      _ => value,
    };
  }

  if (period == 'monthly') {
    final now = DateTime.now();

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

    return '$value ${months[now.month - 1]}';
  }

  return value;
}

String _periodDateLabel(String period) {
  final now = DateTime.now();

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

  if (period == 'daily') {
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  if (period == 'weekly') {
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(
      Duration(days: now.weekday - 1),
    );
    final end = start.add(
      const Duration(days: 6),
    );

    if (start.month == end.month) {
      return '${start.day} - ${end.day} '
          '${months[start.month - 1]} ${start.year}';
    }

    return '${start.day} ${months[start.month - 1]} - '
        '${end.day} ${months[end.month - 1]} ${end.year}';
  }

  if (period == 'monthly') {
    return '${months[now.month - 1]} ${now.year}';
  }

  return '';
}

String _comparisonLabel(String period) {
  return switch (period) {
    'daily' => 'yesterday',
    'weekly' => 'last week',
    'monthly' => 'last month',
    _ => 'previous period',
  };
}