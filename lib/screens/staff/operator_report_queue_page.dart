import 'package:flutter/material.dart';

import '../../widgets/tourflow_widgets.dart';

class OperatorReportQueuePage extends StatefulWidget {
  const OperatorReportQueuePage({super.key});

  static const routeName = '/operator-report-queue';

  @override
  State<OperatorReportQueuePage> createState() =>
      _OperatorReportQueuePageState();
}

class _OperatorReportQueuePageState
    extends State<OperatorReportQueuePage> {
  String _selectedFilter = 'New';

  final List<String> _filters = [
    'New',
    'Urgent',
    'Overcrowding',
    'All',
  ];

  @override
  Widget build(BuildContext context) {
    return TourFlowPage(
      title: 'Operator Report Queue',
      role: 'TOURFLOW · OPERATOR',
      isStaff: true,
      selectedNavigationIndex: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: _QueueSummaryCard(
                  value: '4',
                  label: 'New',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _QueueSummaryCard(
                  value: '3',
                  label: 'In progress',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _QueueSummaryCard(
                  value: '18',
                  label: 'Resolved',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Text(
            'Queue filter',
            style: TextStyle(
              color: TourFlowColors.heading,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _filters.map((filter) {
              final selected = _selectedFilter == filter;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFFFE5E7)
                        : const Color(0xFFFFF3F4),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFFFA6AD)
                          : const Color(0xFFFFD8DC),
                    ),
                  ),
                  child: Text(
                    filter,
                    style: TextStyle(
                      color: const Color(0xFFFF4D5A),
                      fontSize: 10,
                      fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // Report 1
          _OperatorReportCard(
            title: 'Emergency path obstructed',
            location: 'Gallery 3 entrance',
            submitted: 'submitted 6 minutes ago',
            category: 'Overcrowding',
            reportId: '#R-2041',
            priority: 'Urgent',
            priorityType: _PriorityType.urgent,
            onTap: () {
              Navigator.pushNamed(
                context,
                '/resolve-report',
              );
            },
          ),

          const SizedBox(height: 10),

          // Report 2
          _OperatorReportCard(
            title: 'Lift unavailable',
            location: 'West wing',
            submitted: 'submitted 3 days ago',
            category: 'Accessibility',
            reportId: '#R-2038',
            priority: 'Medium',
            priorityType: _PriorityType.medium,
            onTap: () {
              Navigator.pushNamed(
                context,
                '/resolve-report',
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QueueSummaryCard extends StatelessWidget {
  const _QueueSummaryCard({
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
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
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

enum _PriorityType {
  urgent,
  medium,
}

class _OperatorReportCard extends StatelessWidget {
  const _OperatorReportCard({
    required this.title,
    required this.location,
    required this.submitted,
    required this.category,
    required this.reportId,
    required this.priority,
    required this.priorityType,
    required this.onTap,
  });

  final String title;
  final String location;
  final String submitted;
  final String category;
  final String reportId;
  final String priority;
  final _PriorityType priorityType;
  final VoidCallback onTap;

  Color get priorityBackground {
    switch (priorityType) {
      case _PriorityType.urgent:
        return const Color(0xFFFFE3E6);
      case _PriorityType.medium:
        return const Color(0xFFFFF4D8);
    }
  }

  Color get priorityColor {
    switch (priorityType) {
      case _PriorityType.urgent:
        return const Color(0xFFFF4050);
      case _PriorityType.medium:
        return const Color(0xFFE6A000);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModuleCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: TourFlowColors.heading,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: priorityBackground,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 7,
                          color: priorityColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          priority,
                          style: TextStyle(
                            color: priorityColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Text(
                '$location · $submitted',
                style: const TextStyle(
                  color: TourFlowColors.body,
                  fontSize: 10,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$category · Report $reportId',
                      style: const TextStyle(
                        color: TourFlowColors.muted,
                        fontSize: 9,
                      ),
                    ),
                  ),

                  const Icon(
                    Icons.chevron_right_rounded,
                    color: TourFlowColors.muted,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}