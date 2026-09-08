import 'package:flutter/material.dart';

import '../../models/engagement_models.dart';
import '../../models/support_ticket_models.dart';
import '../../repositories/engagement_repository.dart';
import '../../widgets/tourflow_widgets.dart';

class AdminComplaintManagementPage extends StatefulWidget {
  const AdminComplaintManagementPage({super.key});

  @override
  State<AdminComplaintManagementPage> createState() =>
      _AdminComplaintManagementPageState();
}

class _AdminComplaintManagementPageState
    extends State<AdminComplaintManagementPage> {
  final EngagementRepository _repository = EngagementRepository();
  List<IssueReport> _reports = const [];
  String _status = 'all';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final reports = await _repository.fetchAdminReports(
        status: _status == 'all' ? null : _status,
      );
      if (!mounted) return;
      setState(() {
        _reports = reports;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _open(IssueReport report) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${report.code} · ${report.category}'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _line('Attraction', report.attractionName ?? 'Unavailable'),
                _line('Tourist', report.requesterName ?? 'Tourist'),
                _line('Status', _statusLabel(report.status)),
                _line('Priority', report.priority),
                _line(
                  'Submission language',
                  supportTicketSubmissionLanguageLabel(
                    report.submissionLanguage,
                  ),
                ),
                _line('Location', report.location),
                const Divider(height: 24),
                const Text('Complaint details',
                  style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(report.description),
                if (report.resolutionNote?.trim().isNotEmpty == true) ...[
                  const Divider(height: 24),
                  const Text('Resolution',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(report.resolutionNote!),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => TourFlowPage(
    title: 'Complaint Management',
    role: 'TOURFLOW · ADMINISTRATOR',
    navigationRole: TourFlowNavigationRole.administrator,
    pageLevel: TourFlowPageLevel.topLevel,
    selectedNavigationIndex: 3,
    actions: [
      IconButton(
        tooltip: 'Refresh',
        onPressed: _loading ? null : _load,
        icon: const Icon(Icons.refresh_rounded),
      ),
    ],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          'All attraction complaints',
          subtitle:
              'Complaints are separate from application support tickets.',
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          children: const {
            'all': 'All',
            'new': 'Pending',
            'in_progress': 'In Progress',
            'resolved': 'Resolved',
          }.entries.map((entry) => ChoiceChip(
            label: Text(entry.value),
            selected: _status == entry.key,
            onSelected: (_) {
              setState(() => _status = entry.key);
              _load();
            },
          )).toList(),
        ),
        const SizedBox(height: 16),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          ModuleCard(child: Text(_error!))
        else if (_reports.isEmpty)
          const ModuleCard(child: Text('No complaints found.'))
        else
          ..._reports.map((report) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ModuleCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                onTap: () => _open(report),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFF3C4),
                  child: Icon(Icons.report_problem_outlined),
                ),
                title: Text('${report.code} · ${report.category}',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(
                  '${report.requesterName ?? 'Tourist'} · ${report.attractionName ?? 'Attraction unavailable'}\n'
                  'Language: ${supportTicketSubmissionLanguageLabel(report.submissionLanguage)}',
                ),
                isThreeLine: true,
                trailing: StatusChip(
                  label: _statusLabel(report.status).toUpperCase(),
                  color: report.status == 'resolved'
                      ? TourFlowColors.success
                      : TourFlowColors.warning,
                ),
              ),
            ),
          )),
      ],
    ),
  );
}

Widget _line(String label, String value) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    SizedBox(width: 150, child: Text(label,
      style: const TextStyle(color: TourFlowColors.muted))),
    Expanded(child: Text(value)),
  ]),
);

String _statusLabel(String status) => switch (status) {
  'new' => 'Pending',
  'in_progress' => 'In Progress',
  'resolved' => 'Resolved',
  _ => status,
};
