import 'package:flutter/material.dart';
import '../../repositories/management_repository.dart';
import '../../widgets/navigation/navigation_routes.dart';
import '../../widgets/tourflow_widgets.dart';
import 'attraction_configuration_page.dart';
import 'management_ui.dart';

class AttractionDetailsPage extends StatefulWidget {
  const AttractionDetailsPage({super.key});
  static const routeName = TourFlowRoutes.attractionDetails;
  @override
  State<AttractionDetailsPage> createState() => _AttractionDetailsPageState();
}

class _AttractionDetailsPageState extends State<AttractionDetailsPage> {
  final _repository = ManagementRepository();
  late Future<List<ManagementRow>> _rows;
  @override
  void initState() {
    super.initState();
    _rows = _repository.attractions();
  }

  void _refresh() => setState(() => _rows = _repository.attractions());
  Future<void> _edit([ManagementRow? row]) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AttractionConfigurationPage(attraction: row),
      ),
    );
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) => TourFlowPage(
    title: 'Attraction Details',
    role: 'TOURFLOW · OPERATOR',
    navigationRole: TourFlowNavigationRole.operator,
    pageLevel: TourFlowPageLevel.topLevel,
    selectedNavigationIndex: 1,
    child: Column(
      children: [
        FilledButton.icon(
          onPressed: () => _edit(),
          icon: const Icon(Icons.add),
          label: const Text('Register Attraction'),
        ),
        TextButton(onPressed: _refresh, child: const Text('Refresh')),
        ManagementRows(
          future: _rows,
          retry: _refresh,
          builder: (rows) => Column(
            children: [
              if (rows.isEmpty)
                const Text(
                  'No attractions yet. Register your first attraction.',
                ),
              for (final row in rows)
                Card(
                  child: ListTile(
                    title: Text(row['name'] as String),
                    subtitle: Text(
                      '${row['listing_status']} · ${row['attraction_type']}\n${row['review_note'] ?? ''}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _edit(row),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
