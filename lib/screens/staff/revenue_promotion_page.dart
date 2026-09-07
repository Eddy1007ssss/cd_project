import 'package:flutter/material.dart';

import '../../models/engagement_models.dart';
import '../../repositories/engagement_repository.dart';
import '../../widgets/tourflow_widgets.dart';

class RevenuePromotionPage extends StatefulWidget {
  const RevenuePromotionPage({super.key});

  static const routeName = '/revenue-promotion';

  @override
  State<RevenuePromotionPage> createState() => _RevenuePromotionPageState();
}

class _RevenuePromotionPageState extends State<RevenuePromotionPage> {
  final _repository = EngagementRepository();

  late Future<List<RevenueEntry>> _revenue;
  late Future<List<VisitorTrendEntry>> _visitorTrends;

  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _revenue = _repository.fetchOperatorRevenue();
    _visitorTrends = _repository.fetchOperatorVisitorTrends();
  }

  double _currentMonthRevenue(List<RevenueEntry> entries) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month, now.day + 1);

    return entries
        .where((entry) =>
    !entry.completedAt.isBefore(start) &&
        entry.completedAt.isBefore(end))
        .fold<double>(0, (sum, entry) => sum + entry.revenue);
  }

  double _previousMonthToDateRevenue(List<RevenueEntry> entries) {
    final now = DateTime.now();
    final previousMonth = DateTime(now.year, now.month - 1, 1);

    final daysInPreviousMonth =
        DateTime(previousMonth.year, previousMonth.month + 1, 0).day;

    final comparisonDay =
    now.day > daysInPreviousMonth ? daysInPreviousMonth : now.day;

    final start =
    DateTime(previousMonth.year, previousMonth.month, 1);

    final end = DateTime(
      previousMonth.year,
      previousMonth.month,
      comparisonDay + 1,
    );

    return entries
        .where((entry) =>
    !entry.completedAt.isBefore(start) &&
        entry.completedAt.isBefore(end))
        .fold<double>(0, (sum, entry) => sum + entry.revenue);
  }

  String _growthValue(List<RevenueEntry> entries) {
    final current = _currentMonthRevenue(entries);
    final previous = _previousMonthToDateRevenue(entries);

    if (previous == 0) {
      if (current > 0) return 'New';
      return '0%';
    }

    final percentage = ((current - previous) / previous) * 100;

    if (percentage > 0) return '+${percentage.toStringAsFixed(1)}%';
    if (percentage < 0) return '${percentage.toStringAsFixed(1)}%';

    return '0%';
  }

  int _currentMonthVisitors(List<VisitorTrendEntry> entries) {
    final now = DateTime.now();

    return entries
        .where((entry) =>
    entry.checkedInAt.year == now.year &&
        entry.checkedInAt.month == now.month)
        .fold<int>(0, (sum, entry) => sum + entry.visitorCount);
  }

  String _formatRevenue(double value) {
    if (value >= 1000) {
      return 'RM ${(value / 1000).toStringAsFixed(1)}k';
    }

    return 'RM ${value.toStringAsFixed(0)}';
  }

  List<_DailyAnalyticsData> _buildDailyAnalytics(
      List<RevenueEntry> revenueEntries,
      List<VisitorTrendEntry> visitorEntries,
      ) {
    final selected = _selectedDate ?? DateTime.now();

    final endDate =
    DateTime(selected.year, selected.month, selected.day);

    final startDate = endDate.subtract(const Duration(days: 6));
    final result = <_DailyAnalyticsData>[];

    for (var i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      final nextDate = date.add(const Duration(days: 1));

      final revenue = revenueEntries
          .where((entry) =>
      !entry.completedAt.isBefore(date) &&
          entry.completedAt.isBefore(nextDate))
          .fold<double>(0, (sum, entry) => sum + entry.revenue);

      final visitors = visitorEntries
          .where((entry) =>
      !entry.checkedInAt.isBefore(date) &&
          entry.checkedInAt.isBefore(nextDate))
          .fold<int>(0, (sum, entry) => sum + entry.visitorCount);

      result.add(
        _DailyAnalyticsData(
          date: date,
          revenue: revenue,
          visitors: visitors,
        ),
      );
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return TourFlowPage(
      title: 'Revenue & Promotion',
      role: 'TOURFLOW · OPERATOR',
      navigationRole: TourFlowNavigationRole.operator,
      selectedNavigationIndex: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<List<RevenueEntry>>(
            future: _revenue,
            builder: (context, revenueSnapshot) {
              final revenueEntries =
                  revenueSnapshot.data ?? const <RevenueEntry>[];

              final revenue = _currentMonthRevenue(revenueEntries);
              final growth = _growthValue(revenueEntries);

              return FutureBuilder<List<VisitorTrendEntry>>(
                future: _visitorTrends,
                builder: (context, visitorSnapshot) {
                  final visitorEntries =
                      visitorSnapshot.data ?? const <VisitorTrendEntry>[];

                  final visitors =
                  _currentMonthVisitors(visitorEntries);

                  return ModuleCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SummaryStat(
                            icon: Icons.payments_outlined,
                            label: 'Revenue',
                            value: _formatRevenue(revenue),
                            note: 'This month',
                          ),
                        ),
                        const _SummaryDivider(),
                        Expanded(
                          child: _SummaryStat(
                            icon: Icons.trending_up_rounded,
                            label: 'Growth',
                            value: growth,
                            note: 'vs prev. period',
                          ),
                        ),
                        const _SummaryDivider(),
                        Expanded(
                          child: _SummaryStat(
                            icon: Icons.groups_outlined,
                            label: 'Visitors',
                            value: '$visitors',
                            note: 'This month',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 14),

          FutureBuilder<List<RevenueEntry>>(
            future: _revenue,
            builder: (context, revenueSnapshot) {
              final revenueEntries =
                  revenueSnapshot.data ?? const <RevenueEntry>[];

              return FutureBuilder<List<VisitorTrendEntry>>(
                future: _visitorTrends,
                builder: (context, visitorSnapshot) {
                  final visitorEntries =
                      visitorSnapshot.data ??
                          const <VisitorTrendEntry>[];

                  final data = _buildDailyAnalytics(
                    revenueEntries,
                    visitorEntries,
                  );

                  return ModuleCard(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Revenue & Visitors',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: TourFlowColors.heading,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Daily performance',
                                    style: TextStyle(
                                      color: TourFlowColors.muted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            SizedBox(
                              height: 36,
                              child: OutlinedButton(
                                onPressed: _selectDate,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                  TourFlowColors.heading,
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                                  side: const BorderSide(
                                    color: Color(0xFFE1E5EA),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(18),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _selectedDate == null
                                          ? 'Date'
                                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        _DailyAnalyticsChart(data: data),
                      ],
                    ),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 14),

          _PromotionActionCard(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/promotion-suggestion',
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate:
      _selectedDate != null && !_selectedDate!.isAfter(today)
          ? _selectedDate!
          : today,
      firstDate: DateTime(2025),
      lastDate: today,
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.note,
  });

  final IconData icon;
  final String label;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1DC),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF956000),
              size: 16,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            label,
            style: const TextStyle(
              color: TourFlowColors.muted,
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 3),

          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  color: TourFlowColors.heading,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(height: 3),

          Text(
            note,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: TourFlowColors.muted,
              fontSize: 6.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 62,
      color: const Color(0xFFE8EBEF),
    );
  }
}

class _PromotionActionCard extends StatelessWidget {
  const _PromotionActionCard({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF0D7),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0xFFFFD89A),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD28A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_offer_outlined,
                  color: Color(0xFF805300),
                  size: 21,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Promotion Suggestions',
                      style: TextStyle(
                        color: TourFlowColors.heading,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      'View data-based promotion recommendations',
                      style: TextStyle(
                        color: TourFlowColors.muted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9A6500),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyAnalyticsData {
  const _DailyAnalyticsData({
    required this.date,
    required this.revenue,
    required this.visitors,
  });

  final DateTime date;
  final double revenue;
  final int visitors;
}

class _DailyAnalyticsChart extends StatelessWidget {
  const _DailyAnalyticsChart({
    required this.data,
  });

  final List<_DailyAnalyticsData> data;

  String _formatBarRevenue(double value) {
    if (value >= 1000) {
      return 'RM${(value / 1000).toStringAsFixed(1)}k';
    }

    return 'RM${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 190,
        child: Center(
          child: Text(
            'No data available.',
            style: TextStyle(
              color: TourFlowColors.muted,
              fontSize: 10,
            ),
          ),
        ),
      );
    }

    final maxRevenue = data.fold<double>(
      0,
          (max, item) => item.revenue > max ? item.revenue : max,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB74D),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 5),
            const Text(
              'Revenue',
              style: TextStyle(
                color: TourFlowColors.heading,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Container(
          height: 125,
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
          decoration: BoxDecoration(
            color: const Color(0xFFFCFCFD),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map((item) {
              final ratio =
              maxRevenue == 0 ? 0.0 : item.revenue / maxRevenue;

              double barHeight = ratio * 70;

              if (item.revenue > 0 && barHeight < 8) {
                barHeight = 8;
              }

              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (item.revenue > 0) ...[
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _formatBarRevenue(item.revenue),
                                style: const TextStyle(
                                  color: Color(0xFF8A5A00),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                          ],

                          Container(
                            width: 20,
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: item.revenue > 0
                                  ? const Color(0xFFFFB74D)
                                  : const Color(0xFFFFF0D8),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      '${item.date.day}/${item.date.month}',
                      style: const TextStyle(
                        color: TourFlowColors.muted,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 5),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 14),

        const Text(
          'Visitors',
          style: TextStyle(
            color: TourFlowColors.heading,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 7),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFAF3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: data.map((item) {
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      '${item.visitors}',
                      style: TextStyle(
                        color: item.visitors > 0
                            ? const Color(0xFF805300)
                            : TourFlowColors.muted,
                        fontSize: 11,
                        fontWeight: item.visitors > 0
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      '${item.date.day}/${item.date.month}',
                      style: const TextStyle(
                        color: TourFlowColors.muted,
                        fontSize: 6.5,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}