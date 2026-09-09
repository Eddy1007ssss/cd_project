import 'package:flutter/material.dart';
import '../../repositories/management_repository.dart';
import '../../widgets/tourflow_widgets.dart';
import 'management_ui.dart';

class ManagementAdminPage extends StatefulWidget {
  const ManagementAdminPage({
    super.key,
    this.attractionReview = false,
    this.repository,
  });
  final bool attractionReview;
  final ManagementRepository? repository;
  @override
  State<ManagementAdminPage> createState() => _ManagementAdminPageState();
}

class _ManagementAdminPageState extends State<ManagementAdminPage> {
  late final _repository = widget.repository ?? ManagementRepository();
  late Future<List<ManagementRow>> _rows;
  _AdminManagementSection _section = _AdminManagementSection.pendingOperators;
  String _accountRole = 'all';
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _rows = widget.attractionReview
        ? _repository.attractions(administrator: true)
        : _section.isAccountSection
        ? _repository.users()
        : _repository.applications();
  }

  void _refresh() => setState(_load);
  Future<void> _act(ManagementRow row, String decision) async {
    if (_busy) return;
    // Keep the current list mode stable while the confirmation dialog is open.
    final accountAction = _section.isAccountSection;
    final note = await managementDecision(
      context,
      'Confirm $decision?',
      requireNote: decision == 'rejected' || decision == 'suspended',
    );
    if (note == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final id = row['id'] as String;
      if (widget.attractionReview) {
        await _repository.reviewAttraction(id, decision, note);
      } else if (accountAction) {
        await _repository.setAccountStatus(id, decision);
      } else {
        await _repository.reviewApplication(id, decision, note);
      }
      if (mounted) {
        _refresh();
        managementMessage(context, 'Saved successfully.');
      }
    } catch (error) {
      if (mounted) managementMessage(context, managementError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openDocument(String path) async {
    try {
      final url = await _repository.documentUrl(path);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: InteractiveViewer(
                  child: Image.network(
                    url,
                    errorBuilder: (_, _, _) => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Document preview unavailable. Only image scans are supported here.',
                      ),
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    } catch (error) {
      if (mounted) managementMessage(context, managementError(error));
    }
  }

  Widget _action(ManagementRow row, String decision, String label) =>
      TextButton(
        onPressed: _busy ? null : () => _act(row, decision),
        child: Text(label),
      );

  @override
  Widget build(BuildContext context) => TourFlowPage(
    title: widget.attractionReview ? 'Attraction Review' : 'User Management',
    role: 'TOURFLOW · ADMINISTRATOR',
    navigationRole: TourFlowNavigationRole.administrator,
    pageLevel: TourFlowPageLevel.topLevel,
    selectedNavigationIndex: widget.attractionReview ? 2 : 1,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.attractionReview) ...[
          const Text(
            'Choose a group to review. Accounts are separated by current access status.',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _AdminManagementSection.values
                .map(
                  (section) => ChoiceChip(
                    label: Text(section.label),
                    selected: _section == section,
                    onSelected: _busy
                        ? null
                        : (_) => setState(() {
                            _section = section;
                            _load();
                          }),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),
          if (_section.isAccountSection) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: const {'all': 'All roles', 'tourist': 'Tourists', 'operator': 'Operators', 'staff': 'Staff', 'administrator': 'Administrators'}.entries.map((entry) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(entry.value), selected: _accountRole == entry.key, onSelected: _busy ? null : (_) => setState(() => _accountRole = entry.key)))).toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
        TextButton(
          onPressed: _busy ? null : _refresh,
          child: const Text('Refresh'),
        ),
        if (_busy) const LinearProgressIndicator(),
        ManagementRows(
          future: _rows,
          retry: _refresh,
          builder: (rows) {
            var visibleRows = widget.attractionReview
                ? rows
                : rows.where(_matchesSelectedSection).toList();
            if (!widget.attractionReview && _section.isAccountSection && _accountRole != 'all') {
              visibleRows = visibleRows.where((row) => row['role'] == _accountRole).toList();
            }
            return Column(
            children: [
              if (visibleRows.isEmpty) const Text('No records available.'),
              for (final row in visibleRows)
                Card(
                  child: ExpansionTile(
                    key: ValueKey(
                      '${widget.attractionReview}-${_section.name}-${row['id']}',
                    ),
                    title: Text(
                      '${row['name'] ?? row['full_name'] ?? row['business_name']}',
                    ),
                    subtitle: Text(
                      '${row['role'] ?? ''} ${row['listing_status'] ?? row['status']}',
                    ),
                    childrenPadding: const EdgeInsets.all(16),
                    children: [
                      // The row is already filtered by RLS; do not fetch Auth admin data in the client.
                      SelectableText(
                        row.entries
                            .where((e) => !e.key.endsWith('_path'))
                            .map(
                              (e) =>
                                  '${e.key.replaceAll('_', ' ')}: ${e.value ?? '—'}',
                            )
                            .join('\n'),
                      ),
                      if (!widget.attractionReview &&
                          !_section.isAccountSection)
                        for (final field in const {
                          'registration_certificate_path':
                              'Registration certificate',
                          'identity_document_path': 'Identity document',
                          'operating_licence_path': 'Operating licence',
                        }.entries)
                          if (row[field.key] is String &&
                              (row[field.key] as String).isNotEmpty)
                            TextButton(
                              onPressed: () =>
                                  _openDocument(row[field.key] as String),
                              child: Text('Open ${field.value}'),
                            ),
                      if (widget.attractionReview)
                        _AttractionAssets(
                          id: row['id'] as String,
                          repository: _repository,
                        ),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (_section.isAccountSection &&
                              !widget.attractionReview &&
                              row['id'] != _repository.userId)
                            _action(
                              row,
                              row['status'] == 'active'
                                  ? 'deactivated'
                                  : 'active',
                              row['status'] == 'active'
                                  ? 'Deactivate'
                                  : 'Activate',
                            ),
                          if ((!_section.isAccountSection &&
                                  !widget.attractionReview &&
                                  row['status'] == 'pending') ||
                              (widget.attractionReview &&
                                  row['listing_status'] == 'pending')) ...[
                            _action(row, 'approved', 'Approve'),
                            _action(row, 'rejected', 'Reject'),
                          ],
                          if (widget.attractionReview &&
                              row['listing_status'] == 'approved')
                            _action(row, 'suspended', 'Suspend'),
                          if (widget.attractionReview &&
                              row['listing_status'] == 'suspended')
                            _action(row, 'approved', 'Restore'),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          );
          },
        ),
      ],
    ),
  );

  bool _matchesSelectedSection(ManagementRow row) => switch (_section) {
    _AdminManagementSection.pendingOperators => row['status'] == 'pending',
    _AdminManagementSection.reviewedOperators => row['status'] != 'pending',
    _AdminManagementSection.activeAccounts => row['status'] == 'active',
    _AdminManagementSection.deactivatedAccounts => row['status'] == 'deactivated',
  };
}

enum _AdminManagementSection {
  pendingOperators('Pending operators', false),
  activeAccounts('Active accounts', true),
  deactivatedAccounts('Deactivated accounts', true),
  reviewedOperators('Reviewed applications', false);

  const _AdminManagementSection(this.label, this.isAccountSection);
  final String label;
  final bool isAccountSection;
}

class _AttractionAssets extends StatefulWidget {
  const _AttractionAssets({required this.id, required this.repository});
  final String id;
  final ManagementRepository repository;
  @override
  State<_AttractionAssets> createState() => _AttractionAssetsState();
}

class _AttractionAssetsState extends State<_AttractionAssets> {
  late final _hours = widget.repository.hours(widget.id);
  late final _images = widget.repository.images(widget.id);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      FutureBuilder<List<ManagementRow>>(
        future: _hours,
        builder: (_, snapshot) => Text(
          snapshot.hasError
              ? 'Hours unavailable. Refresh before approving.'
              : (snapshot.data ?? [])
                    .map(
                      (h) =>
                          '${const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][h['day_of_week'] as int]}: '
                          '${h['is_closed'] == true ? 'Closed' : '${h['opens_at']}–${h['closes_at']}'}',
                    )
                    .join('\n'),
        ),
      ),
      FutureBuilder<List<ManagementRow>>(
        future: _images,
        builder: (_, snapshot) => Column(
          children: [
            if (snapshot.hasError)
              const Text('Images unavailable. Refresh before approving.'),
            for (final image in snapshot.data ?? <ManagementRow>[])
              Padding(
                padding: const EdgeInsets.all(8),
                child: Image.network(
                  widget.repository.imageUrl(image['storage_path'] as String),
                  height: 140,
                  errorBuilder: (_, _, _) => const Text('Image unavailable'),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}
