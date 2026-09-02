import 'package:flutter/material.dart';

import '../../widgets/tourflow_widgets.dart';

class VisitorStatisticsPage extends StatefulWidget {
  const VisitorStatisticsPage({super.key});

  static const routeName = '/visitor-statistics';

  @override
  State<VisitorStatisticsPage> createState() =>
      _VisitorStatisticsPageState();
}

class _VisitorStatisticsPageState extends State<VisitorStatisticsPage> {
  String _selectedPeriod = 'Week';

  final List<String> _periods = [
    'Day',
    'Week',
    'Month',
  ];

  @override
  Widget build(BuildContext context) {
    return TourFlowPage(
      title: 'Visitor Statistics',
      role: 'TOURFLOW · OPERATOR',
      isStaff: true,
      selectedNavigationIndex: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =========================
          // SUMMARY
          // =========================
          const Row(
            children: [
              Expanded(
                child: _VisitorSummaryCard(
                  value: '328',
                  label: 'Today',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _VisitorSummaryCard(
                  value: '1,248',
                  label: 'This Week',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _VisitorSummaryCard(
                  value: '4,685',
                  label: 'This Month',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // =========================
          // PERIOD FILTER
          // =========================
          const Text(
            'Visitor Trend',
            style: TextStyle(
              color: TourFlowColors.heading,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: _periods.map((period) {
              final selected = _selectedPeriod == period;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPeriod = period;
                      });
                    },
                    child: Container(
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFFFCC80)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFFFBB55)
                              : const Color(0xFFE1E5EB),
                        ),
                      ),
                      child: Text(
                        period,
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFF7A5200)
                              : TourFlowColors.muted,
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // =========================
          // CHART
          // =========================
          ModuleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visitors by ${_selectedPeriod.toLowerCase()}',
                  style: const TextStyle(
                    color: TourFlowColors.heading,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 22),

                SizedBox(
                  height: 165,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      _VisitorBar(
                        label: 'Mon',
                        height: 55,
                        value: '142',
                      ),
                      _VisitorBar(
                        label: 'Tue',
                        height: 70,
                        value: '178',
                      ),
                      _VisitorBar(
                        label: 'Wed',
                        height: 82,
                        value: '206',
                      ),
                      _VisitorBar(
                        label: 'Thu',
                        height: 68,
                        value: '169',
                      ),
                      _VisitorBar(
                        label: 'Fri',
                        height: 95,
                        value: '236',
                      ),
                      _VisitorBar(
                        label: 'Sat',
                        height: 120,
                        value: '305',
                        highlighted: true,
                      ),
                      _VisitorBar(
                        label: 'Sun',
                        height: 98,
                        value: '252',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // =========================
          // PEAK TIME
          // =========================
          const ModuleCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Color(0xFFFFF1DE),
                  child: Icon(
                    Icons.trending_up_rounded,
                    color: Color(0xFFD68700),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Peak Visiting Time',
                        style: TextStyle(
                          color: TourFlowColors.muted,
                          fontSize: 10,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '2:00 PM – 4:00 PM',
                        style: TextStyle(
                          color: TourFlowColors.heading,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Highest visitor activity',
                        style: TextStyle(
                          color: TourFlowColors.body,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // =========================
          // LOWEST TIME
          // =========================
          const ModuleCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Color(0xFFE9F8EE),
                  child: Icon(
                    Icons.trending_down_rounded,
                    color: Color(0xFF23A95B),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lowest Visiting Time',
                        style: TextStyle(
                          color: TourFlowColors.muted,
                          fontSize: 10,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '9:00 AM – 10:00 AM',
                        style: TextStyle(
                          color: TourFlowColors.heading,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Lowest visitor activity',
                        style: TextStyle(
                          color: TourFlowColors.body,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // =========================
          // WEEKLY SUMMARY
          // =========================
          const ModuleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visitor Summary',
                  style: TextStyle(
                    color: TourFlowColors.heading,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 14),

                _SummaryRow(
                  label: 'Average visitors per day',
                  value: '178',
                ),

                Divider(height: 22),

                _SummaryRow(
                  label: 'Busiest day',
                  value: 'Saturday',
                ),

                Divider(height: 22),

                _SummaryRow(
                  label: 'Growth',
                  value: '+8%',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitorSummaryCard extends StatelessWidget {
  const _VisitorSummaryCard({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

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
            value,
            style: const TextStyle(
              color: Color(0xFF8A5A00),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: TourFlowColors.muted,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitorBar extends StatelessWidget {
  const _VisitorBar({
    required this.label,
    required this.height,
    required this.value,
    this.highlighted = false,
  });

  final String label;
  final double height;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: TourFlowColors.muted,
            fontSize: 8,
          ),
        ),

        const SizedBox(height: 4),

        Container(
          width: 25,
          height: height,
          decoration: BoxDecoration(
            color: highlighted
                ? const Color(0xFFFFC46B)
                : const Color(0xFFFFF1DE),
            borderRadius: BorderRadius.circular(6),
          ),
        ),

        const SizedBox(height: 7),

        Text(
          label,
          style: const TextStyle(
            color: TourFlowColors.muted,
            fontSize: 8,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: TourFlowColors.body,
              fontSize: 10,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: TourFlowColors.heading,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}