import 'package:flutter/material.dart';

import '../../models/engagement_models.dart';
import '../../repositories/engagement_repository.dart';
import '../../widgets/tourflow_widgets.dart';
import '../../widgets/navigation/navigation_routes.dart';
import 'resolve_report_page.dart';

class OperatorReportQueuePage extends StatefulWidget {
  const OperatorReportQueuePage({super.key});
  static const routeName = TourFlowRoutes.operatorReports;
  @override
  State<OperatorReportQueuePage> createState() =>
      _OperatorReportQueuePageState();
}

class _OperatorReportQueuePageState extends State<OperatorReportQueuePage> {
  final _repository = EngagementRepository();
  String? _status = 'new';
  late Future<List<IssueReport>> _reports;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() =>
      _reports = _repository.fetchOperatorReports(status: _status);

  @override
  Widget build(BuildContext context) => TourFlowPage(
    title: 'Operator Report Queue',
    role: 'TOURFLOW · OPERATOR',
    navigationRole: TourFlowNavigationRole.operator,
    pageLevel: TourFlowPageLevel.topLevel,
    selectedNavigationIndex: 3,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<String?>(
          segments: const [
            ButtonSegment(value: 'new', label: Text('New')),
            ButtonSegment(value: 'in_progress', label: Text('In progress')),
            ButtonSegment(value: 'resolved', label: Text('Resolved')),
            ButtonSegment(value: null, label: Text('All')),
          ],
          selected: {_status},
          onSelectionChanged: (value) => setState(() {
            _status = value.first;
            _reload();
          }),
        ),
        const SizedBox(height: 14),
        FutureBuilder<List<IssueReport>>(
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
              return const ModuleCard(child: Text('No reports in this queue.'));
            }
            return Column(
              children: reports
                  .map(
                    (report) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ModuleCard(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          title: Text(report.description),
                          subtitle: Text(
                            '${report.location} · #${report.code} · ${report.priority}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.pushNamed(
                              context,
                              ResolveReportPage.routeName,
                              arguments: report,
                            );
                            setState(_reload);
                          },
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    ),
  );
}
