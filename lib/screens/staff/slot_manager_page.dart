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
          builder: (rows) {
            final approvedRows = rows
                .where((row) => row['listing_status'] == 'approved')
                .toList();
            final selectedIsStillApproved = approvedRows.any(
              (row) => row['id'] == _selected,
            );

            return rows.isEmpty
              ? const Text('Create an attraction first.')
              : approvedRows.isEmpty
              ? const Text(
                  'Your attraction is awaiting administrator approval. Slots and maintenance are available after approval.',
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Only administrator-approved attractions can have slots or maintenance periods managed.',
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue:
                          selectedIsStillApproved ? _selected : null,
                      decoration: const InputDecoration(
                        labelText: 'Select approved attraction',
                      ),
                      items: approvedRows
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
                  ],
                );
          },
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
  final _capacity = TextEditingController(text: '20');
  final _reason = TextEditingController();
  DateTime? _startAt;
  DateTime? _endAt;
  String? _scheduleError;
  String _status = 'open';
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    final slot = widget.slot;
    if (slot != null) {
      _startAt = DateTime.parse(slot['starts_at'] as String).toLocal();
      _endAt = DateTime.parse(slot['ends_at'] as String).toLocal();
      _capacity.text = '${slot['maximum_capacity']}';
      _status = slot['status'] == 'closed' ? 'closed' : 'open';
    }
  }

  @override
  void dispose() {
    for (final c in [_capacity, _reason]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? now),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return 'Choose date and time';
    final localizations = MaterialLocalizations.of(context);
    return '${localizations.formatMediumDate(value)} · '
        '${TimeOfDay.fromDateTime(value).format(context)}';
  }

  Future<void> _selectStart() async {
    final picked = await _pickDateTime(_startAt);
    if (picked == null || !mounted) return;
    setState(() {
      _startAt = picked;
      if (_endAt == null || !_endAt!.isAfter(picked)) {
        _endAt = picked.add(const Duration(hours: 1));
      }
      _scheduleError = null;
    });
  }

  Future<void> _selectEnd() async {
    final picked = await _pickDateTime(_endAt ?? _startAt);
    if (picked == null || !mounted) return;
    setState(() {
      _endAt = picked;
      _scheduleError = null;
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final start = _startAt;
    final end = _endAt;
    if (start == null || end == null || !end.isAfter(start)) {
      setState(() {
        _scheduleError = start == null || end == null
            ? 'Choose both a start and end date/time.'
            : 'End must be after start.';
      });
      return;
    }
    setState(() => _busy = true);
    try {
      final values = <String, dynamic>{
        'id': widget.slot?['id'],
        'attraction_id': widget.attractionId,
        'starts_at': start.toUtc().toIso8601String(),
        'ends_at': end.toUtc().toIso8601String(),
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
          const Text('Choose local start and end times for this period.'),
          const SizedBox(height: 12),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: const Color(0xFFF8FAFC),
            leading: const Icon(Icons.calendar_month_outlined),
            title: const Text('Start'),
            subtitle: Text(_formatDateTime(_startAt)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _busy ? null : _selectStart,
          ),
          const SizedBox(height: 10),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: const Color(0xFFF8FAFC),
            leading: const Icon(Icons.schedule_outlined),
            title: const Text('End'),
            subtitle: Text(_formatDateTime(_endAt)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _busy ? null : _selectEnd,
          ),
          if (_scheduleError != null) ...[
            const SizedBox(height: 8),
            Text(
              _scheduleError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
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
