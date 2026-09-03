import 'package:flutter/material.dart';

import '../../models/engagement_models.dart';
import '../../repositories/engagement_repository.dart';
import '../../widgets/tourflow_widgets.dart';

class ReportStatusPage extends StatefulWidget {
  const ReportStatusPage({super.key});
  static const routeName = '/report-status';
  @override
  State<ReportStatusPage> createState() => _ReportStatusPageState();
}

class _ReportStatusPageState extends State<ReportStatusPage> {
  final _repository = EngagementRepository();
  late Future<List<IssueReport>> _reports;
  @override
  void initState() {
    super.initState();
    _reports = _repository.fetchMyReports();
  }

  @override
  Widget build(BuildContext context) => TourFlowPage(
    title: 'My Report Status',
    role: 'TOURIST',
    selectedNavigationIndex: 4,
    child: FutureBuilder<List<IssueReport>>(
      future: _reports,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ModuleCard(child: Text(snapshot.error.toString()));
        }
        final reports = snapshot.data ?? const [];
        if (reports.isEmpty) {
          return const ModuleCard(
            child: Text('No issue reports submitted yet.'),
          );
        }
        return Column(
          children: reports
              .map(
                (report) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ReportCard(report: report),
                ),
              )
              .toList(),
        );
      },
    ),
  );
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});
  final IssueReport report;
  @override
  Widget build(BuildContext context) => ModuleCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                report.description,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Chip(label: Text(report.status.replaceAll('_', ' ').toUpperCase())),
          ],
        ),
        Text('${report.location} · ${report.attractionName ?? 'General'}'),
        Text('${report.category} · Report #${report.code}'),
        if (report.resolutionNote != null) ...[
          const Divider(),
          Text('Resolution: ${report.resolutionNote}'),
        ],
      ],
    ),
  );
}
