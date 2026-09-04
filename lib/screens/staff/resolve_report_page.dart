import 'package:flutter/material.dart';

import '../../models/engagement_models.dart';
import '../../repositories/engagement_repository.dart';
import '../../widgets/tourflow_widgets.dart';

class ResolveReportPage extends StatefulWidget {
  const ResolveReportPage({super.key});
  static const routeName = '/resolve-report';
  @override
  State<ResolveReportPage> createState() => _ResolveReportPageState();
}

class _ResolveReportPageState extends State<ResolveReportPage> {
  final _repository = EngagementRepository();
  final _note = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final report = ModalRoute.of(context)?.settings.arguments as IssueReport?;
    return TourFlowPage(
      title: 'Resolve Report',
      role: 'TOURFLOW · OPERATOR',
      navigationRole: TourFlowNavigationRole.operator,
      selectedNavigationIndex: 0,
      child: report == null
          ? const ModuleCard(child: Text('No report was selected.'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ModuleCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report #${report.code}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(report.description),
                      Text(
                        '${report.location} · ${report.category} · ${report.priority}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _note,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Resolution note',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : () => _resolve(report),
                    child: Text(_saving ? 'Saving…' : 'Mark as Resolved'),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _resolve(IssueReport report) async {
    if (_note.text.trim().length < 3) return;
    setState(() => _saving = true);
    try {
      await _repository.resolveReport(report.id, _note.text);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
