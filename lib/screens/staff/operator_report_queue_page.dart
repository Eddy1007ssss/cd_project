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
  State<OperatorReportQueuePage> createState() => _OperatorReportQueuePageState();
}

class _OperatorReportQueuePageState extends State<OperatorReportQueuePage> {
  final _repository = EngagementRepository();

  String? _status = 'new';
  String? _attractionFilter;
  late Future<List<IssueReport>> _reports;

  Future<void>? _refreshTask;

  @override
  void initState() {
    super.initState();
    _reports = _repository.fetchOperatorReports(status: _status);
  }

  Future<void> _refresh() {
    return _refreshTask ??= _performRefresh().whenComplete(() {
      _refreshTask = null;
    });
  }

  Future<void> _performRefresh() async {
    if (!mounted) return;

    final request = _repository.fetchOperatorReports(status: _status);

    setState(() => _reports = request);

    try {
      await request;
    } catch (_) {
      // FutureBuilder displays the loading error.
    }
  }

  void _changeStatus(String? status) {
    setState(() {
      _status = status;
      _attractionFilter = null;
      _reports = _repository.fetchOperatorReports(status: _status);
    });
  }

  Future<void> _openReport(IssueReport report) async {
    await Navigator.pushNamed(
      context,
      ResolveReportPage.routeName,
      arguments: report,
    );

    if (!mounted) return;

    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const _QueueScrollBehavior(),
      child: RefreshIndicator(
        color: const Color(0xFFFF9800),
        onRefresh: _refresh,
        child: TourFlowPage(
          title: 'Operator Report Queue',
          role: 'TOURFLOW · OPERATOR',
          navigationRole: TourFlowNavigationRole.operator,
          pageLevel: TourFlowPageLevel.topLevel,
          selectedNavigationIndex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _StatusFilterChip(
                      label: 'Pending',
                      icon: Icons.schedule_rounded,
                      selected: _status == 'new',
                      onTap: () => _changeStatus('new'),
                    ),
                    const SizedBox(width: 8),
                    _StatusFilterChip(
                      label: 'In Progress',
                      icon: Icons.timelapse_rounded,
                      selected: _status == 'in_progress',
                      onTap: () => _changeStatus('in_progress'),
                    ),
                    const SizedBox(width: 8),
                    _StatusFilterChip(
                      label: 'Resolved',
                      icon: Icons.check_circle_outline_rounded,
                      selected: _status == 'resolved',
                      onTap: () => _changeStatus('resolved'),
                    ),
                    const SizedBox(width: 8),
                    _StatusFilterChip(
                      label: 'All',
                      icon: Icons.grid_view_rounded,
                      selected: _status == null,
                      onTap: () => _changeStatus(null),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              FutureBuilder<List<IssueReport>>(
                future: _reports,
                builder: (context, snapshot) {
                  final loading = snapshot.connectionState != ConnectionState.done;

                  if (loading && !snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError && !loading) {
                    return const ModuleCard(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Unable to load reports. Pull down to try again.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final reports = snapshot.data ?? const <IssueReport>[];

                  final attractionNames = reports
                      .map((report) => report.attractionName)
                      .whereType<String>()
                      .where((name) => name.trim().isNotEmpty)
                      .toSet()
                      .toList()
                    ..sort();

                  final filteredReports = _attractionFilter == null
                      ? reports
                      : reports
                      .where(
                        (report) => report.attractionName == _attractionFilter,
                  )
                      .toList();

                  if (reports.isEmpty) {
                    return const ModuleCard(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 40,
                              color: Color(0xFFFF9800),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No reports in this queue.',
                              style: TextStyle(
                                color: TourFlowColors.heading,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Pull down to refresh.',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                          border: Border.all(
                            color: const Color(0xFFE1E5EB),
                          ),
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

                      const SizedBox(height: 14),

                      ...filteredReports.map(
                            (report) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ModuleCard(
                            padding: EdgeInsets.zero,
                            child: InkWell(
                              onTap: () => _openReport(report),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFF1F1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.warning_amber_rounded,
                                            color: Color(0xFFFF5252),
                                            size: 20,
                                          ),
                                        ),

                                        const SizedBox(width: 10),

                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                report.category,
                                                style: const TextStyle(
                                                  color: TourFlowColors.heading,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),

                                              const SizedBox(height: 4),

                                              Text(
                                                report.attractionName ??
                                                    'Attraction unavailable',
                                                style: const TextStyle(
                                                  color: TourFlowColors.muted,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        _ReportStatusBadge(
                                          status: report.status,
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    if (report.location.trim().isNotEmpty)
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on_outlined,
                                            size: 14,
                                            color: Color(0xFF98A2B3),
                                          ),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              report.location,
                                              style: const TextStyle(
                                                color: TourFlowColors.body,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                    const SizedBox(height: 10),

                                    Text(
                                      report.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: TourFlowColors.body,
                                        fontSize: 11,
                                        height: 1.5,
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    const Divider(
                                      height: 1,
                                      color: Color(0xFFEAECF0),
                                    ),

                                    const SizedBox(height: 10),

                                    Row(
                                      children: [
                                        _PriorityChip(
                                          priority: report.priority,
                                        ),

                                        const Spacer(),

                                        Text(
                                          '#${report.code}',
                                          style: const TextStyle(
                                            color: TourFlowColors.muted,
                                            fontSize: 9,
                                          ),
                                        ),

                                        const SizedBox(width: 5),

                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: Color(0xFF98A2B3),
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 39,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFFFF4E5)
                : Colors.white,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: selected
                  ? const Color(0xFFFFB74D)
                  : const Color(0xFFE1E5EB),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected
                    ? const Color(0xFFFF9800)
                    : const Color(0xFF98A2B3),
              ),

              const SizedBox(width: 6),

              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFFB86A00)
                      : const Color(0xFF667085),
                  fontSize: 9.5,
                  fontWeight: selected
                      ? FontWeight.w800
                      : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportStatusBadge extends StatelessWidget {
  const _ReportStatusBadge({
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final foreground = switch (status) {
      'new' => const Color(0xFFE53935),
      'in_progress' => const Color(0xFFD99000),
      'resolved' => const Color(0xFF159447),
      _ => TourFlowColors.muted,
    };

    final background = switch (status) {
      'new' => const Color(0xFFFFECEB),
      'in_progress' => const Color(0xFFFFF8E5),
      'resolved' => const Color(0xFFE7FAEC),
      _ => const Color(0xFFF0F2F5),
    };

    final label = switch (status) {
      'new' => 'Pending',
      'in_progress' => 'In Progress',
      'resolved' => 'Resolved',
      _ => status.replaceAll('_', ' '),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({
    required this.priority,
  });

  final String priority;

  @override
  Widget build(BuildContext context) {
    final urgent = priority.toLowerCase() == 'urgent';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: urgent
            ? const Color(0xFFFFECEB)
            : const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          color: urgent
              ? const Color(0xFFE53935)
              : const Color(0xFFB36A00),
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _QueueScrollBehavior extends MaterialScrollBehavior {
  const _QueueScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const AlwaysScrollableScrollPhysics(
      parent: ClampingScrollPhysics(),
    );
  }
}