import 'package:flutter/material.dart';
import '../../repositories/management_repository.dart';
import '../../widgets/navigation/navigation_routes.dart';
import '../../widgets/tourflow_widgets.dart';
import 'management_ui.dart';

class SlotManagerPage extends StatefulWidget {
  const SlotManagerPage({super.key});
  static const routeName = TourFlowRoutes.slotManager;
  @override
  State<SlotManagerPage> createState() => _SlotManagerPageState();
}

class _SlotManagerPageState extends State<SlotManagerPage> {
  final _repository = ManagementRepository();
  late Future<List<ManagementRow>> _attractions;
  Future<List<ManagementRow>>? _slots;
  Future<List<ManagementRow>>? _closures;
  String? _selected;
  @override
  void initState() {
    super.initState();
    _attractions = _repository.attractions();
  }

  void _select(String id) => setState(() {
    _selected = id;
    _slots = _repository.slots(id);
    _closures = _repository.closures(id);
  });
  Future<void> _edit({ManagementRow? slot, bool maintenance = false}) async {
    final selected = _selected;
    if (selected == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => _PeriodEditor(
          repository: _repository,
          attractionId: selected,
          slot: slot,
          maintenance: maintenance,
        ),
      ),
    );
    if (mounted) _select(selected);
  }

  @override
  Widget build(BuildContext context) => TourFlowPage(
    title: 'Slot Manager',
    role: 'TOURFLOW · OPERATOR',
    navigationRole: TourFlowNavigationRole.operator,
    pageLevel: TourFlowPageLevel.topLevel,
    selectedNavigationIndex: 2,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ManagementRows(
          future: _attractions,
          retry: () => setState(() => _attractions = _repository.attractions()),
          builder: (rows) => rows.isEmpty
              ? const Text('Create an attraction first.')
              : DropdownButtonFormField<String>(
                  initialValue: _selected,
                  decoration: const InputDecoration(
                    labelText: 'Select attraction',
                  ),
                  items: rows
                      .map(
                        (r) => DropdownMenuItem(
                          value: r['id'] as String,
                          child: Text(r['name'] as String),
                        ),
                      )
                      .toList(),
                  onChanged: (id) {
                    if (id != null) _select(id);
                  },
                ),
        ),
        if (_selected != null) ...[
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: () => _edit(),
                child: const Text('Create Slot'),
              ),
              OutlinedButton(
                onPressed: () => _edit(maintenance: true),
                child: const Text('Block Maintenance Period'),
              ),
              TextButton(
                onPressed: () => _select(_selected!),
                child: const Text('Refresh'),
              ),
            ],
          ),
          ManagementRows(
            future: _slots!,
            retry: () => _select(_selected!),
            builder: (rows) => Column(
              children: [
                if (rows.isEmpty) const Text('No slots yet.'),
                for (final row in rows)
                  Card(
                    child: ListTile(
                      title: Text(
                        '${DateTime.parse(row['starts_at'] as String).toLocal()}\n'
                        'to ${DateTime.parse(row['ends_at'] as String).toLocal()}',
                      ),
                      subtitle: Text(
                        '${DateTime.parse(row['ends_at'] as String).isBefore(DateTime.now()) ? 'expired' : row['status']} · '
                        '${row['reserved_capacity']}/${row['maximum_capacity']} reserved',
                      ),
                      trailing: const Icon(Icons.edit),
                      onTap: () => _edit(slot: row),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Maintenance periods'),
          ManagementRows(
            future: _closures!,
            retry: () => _select(_selected!),
            builder: (rows) => Column(
              children: [
                if (rows.isEmpty) const Text('No blocked periods.'),
                for (final row in rows)
                  ListTile(
                    title: Text(row['reason'] as String),
                    subtitle: Text(
                      '${DateTime.parse(row['starts_at'] as String).toLocal()}\n'
                      'to ${DateTime.parse(row['ends_at'] as String).toLocal()}',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

class _PeriodEditor extends StatefulWidget {
  const _PeriodEditor({
    required this.repository,
    required this.attractionId,
    this.slot,
    required this.maintenance,
  });
  final ManagementRepository repository;
  final String attractionId;
  final ManagementRow? slot;
  final bool maintenance;
  @override
  State<_PeriodEditor> createState() => _PeriodEditorState();
}

class _PeriodEditorState extends State<_PeriodEditor> {
  final _form = GlobalKey<FormState>();
  final _start = TextEditingController();
  final _end = TextEditingController();
  final _capacity = TextEditingController(text: '20');
  final _reason = TextEditingController();
  String _status = 'open';
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    final slot = widget.slot;
    if (slot != null) {
      _start.text = DateTime.parse(
        slot['starts_at'] as String,
      ).toLocal().toIso8601String().substring(0, 16);
      _end.text = DateTime.parse(
        slot['ends_at'] as String,
      ).toLocal().toIso8601String().substring(0, 16);
      _capacity.text = '${slot['maximum_capacity']}';
      _status = slot['status'] == 'closed' ? 'closed' : 'open';
    }
  }

  @override
  void dispose() {
    for (final c in [_start, _end, _capacity, _reason]) {
      c.dispose();
    }
    super.dispose();
  }

  DateTime? _parse(String? value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$').hasMatch(value ?? '')) {
      return null;
    }
    final result = DateTime.tryParse(value!);
    // DateTime.parse normalizes invalid calendar dates; reject those round trips.
    return result != null && result.toIso8601String().substring(0, 16) == value
        ? result
        : null;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final values = <String, dynamic>{
        'id': widget.slot?['id'],
        'attraction_id': widget.attractionId,
        'starts_at': _parse(_start.text)!.toUtc().toIso8601String(),
        'ends_at': _parse(_end.text)!.toUtc().toIso8601String(),
        'maximum_capacity': int.tryParse(_capacity.text),
        'status': _status,
        'reason': _reason.text.trim(),
      };
      if (widget.maintenance) {
        await widget.repository.addClosure(values);
      } else {
        await widget.repository.saveSlot(values);
      }
      if (mounted) {
        managementMessage(context, 'Saved successfully.');
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) managementMessage(context, managementError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.maintenance ? 'Maintenance Period' : 'Edit Slot'),
    ),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Enter local time as YYYY-MM-DDTHH:mm (for example, 2026-10-01T09:00).',
          ),
          managementField(
            'Start',
            _start,
            validator: (value) =>
                _parse(value) == null ? 'Enter a valid date and time' : null,
          ),
          managementField(
            'End',
            _end,
            validator: (value) {
              final start = _parse(_start.text);
              final end = _parse(value);
              return start == null || end == null || !end.isAfter(start)
                  ? 'End must be after start'
                  : null;
            },
          ),
          if (widget.maintenance) ...[
            managementField('Reason', _reason),
            const Text(
              'New bookings during maintenance will be blocked. Existing bookings are NOT cancelled automatically; coordinate affected visits separately.',
            ),
          ] else ...[
            managementField(
              'Maximum capacity',
              _capacity,
              validator: (value) => (int.tryParse(value ?? '') ?? 0) < 1
                  ? 'Enter a positive whole number'
                  : null,
            ),
            DropdownButtonFormField<String>(
              initialValue: _status,
              items: const [
                DropdownMenuItem(value: 'open', child: Text('Open')),
                DropdownMenuItem(
                  value: 'closed',
                  child: Text('Closed / cancelled'),
                ),
              ],
              onChanged: (value) => setState(() => _status = value!),
            ),
            const Text(
              'Slots with reservations cannot be edited or closed. Closing a slot preserves its history.',
            ),
          ],
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(_busy ? 'Saving…' : 'Save'),
          ),
        ],
      ),
    ),
  );
}
