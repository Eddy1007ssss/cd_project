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
  late Future<CrowdSnapshot?> _snapshot;
  @override
  void initState() {
    super.initState();
    _snapshot = _repository.fetchCrowdSnapshot();
  }

  @override
  Widget build(BuildContext context) => TourFlowPage(
    title: 'Visitor Statistics',
    role: 'TOURFLOW · OPERATOR',
    navigationRole: TourFlowNavigationRole.operator,
    pageLevel: TourFlowPageLevel.topLevel,
    selectedNavigationIndex: 4,
    child: FutureBuilder<CrowdSnapshot?>(
      future: _snapshot,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ModuleCard(child: Text(snapshot.error.toString()));
        }
        final crowd = snapshot.data;
        if (crowd == null) {
          return const ModuleCard(child: Text('No visitor data is available.'));
        }
        return Column(
          children: [
            ModuleCard(
              child: ListTile(
                title: Text(crowd.attractionName),
                subtitle: const Text('Current authenticated check-ins'),
                trailing: Text(
                  '${crowd.currentVisitors}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ModuleCard(
              child: ListTile(
                title: const Text('Arrivals in the last 15 minutes'),
                trailing: Text('${crowd.recentArrivals}'),
              ),
            ),
            const SizedBox(height: 12),
            const ModuleCard(
              child: Text(
                'Historical charts populate as check-in records accumulate. '
                'Live totals include booking visitor counts rather than sample values.',
              ),
            ),
          ],
        );
      },
    ),
  );
}
