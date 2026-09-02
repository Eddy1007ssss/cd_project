import 'package:flutter/material.dart';

import '../../widgets/tourflow_widgets.dart';

class ReportStatusPage extends StatelessWidget {
  const ReportStatusPage({super.key});

  static const routeName = '/report-status';

  @override
  Widget build(BuildContext context) {
    return TourFlowPage(
      title: 'My Report Status',
      role: 'TOURIST',
      selectedNavigationIndex: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Expanded(
                child: _SummaryCard(
                  number: '3',
                  label: 'All',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  number: '1',
                  label: 'Pending',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  number: '1',
                  label: 'In progress',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  number: '1',
                  label: 'Resolved',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Text(
            'Your Reports',
            style: TextStyle(
              color: TourFlowColors.heading,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 10),

          const _ReportCard(
            title: 'Crowding at main entrance',
            details: 'Main entrance · submitted 32 minutes ago',
            category: 'Accessibility',
            reportId: '#R-2059',
            status: 'Pending',
            statusType: _StatusType.pending,
          ),

          const SizedBox(height: 10),

          const _ReportCard(
            title: 'Lift unavailable',
            details: 'West wing · submitted 3 days ago',
            category: 'Accessibility',
            reportId: '#R-2038',
            status: 'In Progress',
            statusType: _StatusType.inProgress,
          ),

          const SizedBox(height: 10),

          const _ReportCard(
            title: 'Washroom not clean',
            details: 'submitted 20 June 2026',
            category: 'Accessibility',
            reportId: '#R-2011',
            status: 'Resolved',
            statusType: _StatusType.resolved,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.number,
    required this.label,
  });

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE4E8EF),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            number,
            style: const TextStyle(
              color: Color(0xFF8A5A00),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
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

enum _StatusType {
  pending,
  inProgress,
  resolved,
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.title,
    required this.details,
    required this.category,
    required this.reportId,
    required this.status,
    required this.statusType,
  });

  final String title;
  final String details;
  final String category;
  final String reportId;
  final String status;
  final _StatusType statusType;

  Color get _statusBackground {
    switch (statusType) {
      case _StatusType.pending:
        return const Color(0xFFFFE7E9);
      case _StatusType.inProgress:
        return const Color(0xFFFFF5DC);
      case _StatusType.resolved:
        return const Color(0xFFE4F8E9);
    }
  }

  Color get _statusText {
    switch (statusType) {
      case _StatusType.pending:
        return const Color(0xFFFF3F4E);
      case _StatusType.inProgress:
        return const Color(0xFFE8A500);
      case _StatusType.resolved:
        return const Color(0xFF26A853);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModuleCard(
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
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _statusBackground,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: _statusText,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            details,
            style: const TextStyle(
              color: TourFlowColors.body,
              fontSize: 10,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            '$category · Report $reportId',
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