import 'package:flutter/material.dart';

import '../../models/engagement_models.dart';
import '../../repositories/engagement_repository.dart';
import '../../widgets/tourflow_widgets.dart';

class LiveCrowdPage extends StatefulWidget {
  const LiveCrowdPage({super.key});
  static const routeName = '/live-crowd';
  @override
  State<LiveCrowdPage> createState() => _LiveCrowdPageState();
}

class _LiveCrowdPageState extends State<LiveCrowdPage> {
  final _repository = EngagementRepository();
  late Future<CrowdSnapshot?> _snapshot;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _snapshot = _repository.fetchCrowdSnapshot();

  @override
  Widget build(BuildContext context) => TourFlowPage(
    title: 'Live Crowd',
    role: 'TOURFLOW · OPERATOR',
    isStaff: true,
    selectedNavigationIndex: 0,
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
          return const ModuleCard(
            child: Text('No managed attraction is available.'),
          );
        }
        final percent = (crowd.occupancy * 100).round();
        return Column(
          children: [
            ModuleCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    crowd.attractionName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${crowd.currentVisitors} / ${crowd.maximumCapacity} visitors',
                  ),
                  LinearProgressIndicator(value: crowd.occupancy.clamp(0, 1)),
                  Text(
                    '$percent% occupancy · ${crowd.recentArrivals} arrivals in the last 15 minutes',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Current',
                    value: '${crowd.currentVisitors}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Metric(
                    label: 'Available',
                    value: '${crowd.availableCapacity}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Metric(
                    label: 'Recent',
                    value: '+${crowd.recentArrivals}',
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => setState(_reload),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh live data'),
            ),
          ],
        );
      },
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => ModuleCard(
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        Text(label),
      ],
    ),
  );
}
