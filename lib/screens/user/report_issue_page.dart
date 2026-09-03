import 'package:flutter/material.dart';

import '../../models/engagement_models.dart';
import '../../repositories/engagement_repository.dart';
import '../../widgets/tourflow_widgets.dart';
import 'report_status_page.dart';

class ReportIssuePage extends StatefulWidget {
  const ReportIssuePage({super.key});
  static const routeName = '/report-issue';
  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  final _repository = EngagementRepository();
  final _location = TextEditingController();
  final _description = TextEditingController();
  static const _categories = [
    'Overcrowding',
    'Safety',
    'Facility',
    'Accessibility',
    'Others',
  ];
  String _category = _categories.first;
  List<VisitOption> _visits = const [];
  VisitOption? _visit;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _repository.fetchUpcomingVisits().then((visits) {
      if (mounted) {
        setState(() {
          _visits = visits;
          _visit = visits.firstOrNull;
        });
      }
    });
  }

  @override
  void dispose() {
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TourFlowPage(
    title: 'Report an Issue',
    role: 'TOURIST',
    selectedNavigationIndex: 4,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_visits.isNotEmpty)
          DropdownButtonFormField<VisitOption>(
            initialValue: _visit,
            decoration: const InputDecoration(
              labelText: 'Related visit',
              border: OutlineInputBorder(),
            ),
            items: _visits
                .map(
                  (visit) => DropdownMenuItem(
                    value: visit,
                    child: Text(
                      '${visit.attractionName} · ${visit.bookingCode}',
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _visit = value),
          ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _category,
          decoration: const InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(),
          ),
          items: _categories
              .map(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              )
              .toList(),
          onChanged: (value) => setState(() => _category = value ?? _category),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _location,
          maxLength: 200,
          decoration: const InputDecoration(
            labelText: 'Location',
            border: OutlineInputBorder(),
          ),
        ),
        TextField(
          controller: _description,
          maxLength: 2000,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saving ? null : _submit,
            child: Text(_saving ? 'Submitting…' : 'Submit Issue Report'),
          ),
        ),
      ],
    ),
  );

  Future<void> _submit() async {
    if (_visit == null) {
      _snack(
        'A confirmed visit is required so the report reaches its operator.',
      );
      return;
    }
    if (_location.text.trim().length < 2 ||
        _description.text.trim().length < 5) {
      _snack('Enter a location and a clear description.');
      return;
    }
    setState(() => _saving = true);
    try {
      await _repository.submitIssue(
        category: _category,
        location: _location.text,
        description: _description.text,
        visit: _visit,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, ReportStatusPage.routeName);
    } catch (error) {
      if (mounted) _snack(error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}
