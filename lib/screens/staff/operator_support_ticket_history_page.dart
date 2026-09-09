import 'package:flutter/material.dart';

import '../../models/support_ticket_models.dart';
import '../../services/support_ticket_service.dart';
import '../../widgets/tourflow_widgets.dart';

/// Read-only history for technical reports submitted by the signed-in operator.
/// Operators can create reports but only administrators manage or resolve them.
class OperatorSupportTicketHistoryPage extends StatefulWidget {
  const OperatorSupportTicketHistoryPage({super.key});

  @override
  State<OperatorSupportTicketHistoryPage> createState() =>
      _OperatorSupportTicketHistoryPageState();
}

class _OperatorSupportTicketHistoryPageState
    extends State<OperatorSupportTicketHistoryPage> {
  final _service = SupportTicketService();

  List<SupportTicket> _tickets = const [];
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
      final tickets = await _service.fetchMyTickets();
      if (!mounted) return;
      setState(() {
        _tickets = tickets;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TourFlowPage(
      title: 'My Technical Reports',
      role: 'TOURFLOW · OPERATOR',
      navigationRole: TourFlowNavigationRole.operator,
      selectedNavigationIndex: 4,
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
            'Track your submitted reports',
            subtitle:
                'Administrators review technical reports. You can monitor their current status here.',
          ),
          const SizedBox(height: 16),
          if (_loading)
            const ModuleCard(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_error != null)
            ModuleCard(
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: TourFlowColors.danger,
                  ),
                  const SizedBox(height: 8),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  ),
                ],
              ),
            )
          else if (_tickets.isEmpty)
            const ModuleCard(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(
                      Icons.bug_report_outlined,
                      size: 42,
                      color: TourFlowColors.muted,
                    ),
                    SizedBox(height: 8),
                    Text('You have not submitted any technical reports.'),
                  ],
                ),
              ),
            )
          else
            ..._tickets.map(
              (ticket) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OperatorReportCard(ticket: ticket),
              ),
            ),
        ],
      ),
    );
  }
}

class _OperatorReportCard extends StatelessWidget {
  const _OperatorReportCard({required this.ticket});

  final SupportTicket ticket;

  Color get _statusColor => switch (ticket.status) {
    'resolved' || 'closed' => TourFlowColors.success,
    'in_progress' => TourFlowColors.warning,
    _ => TourFlowColors.primaryText,
  };

  @override
  Widget build(BuildContext context) {
    return ModuleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                ticket.code,
                style: const TextStyle(
                  color: TourFlowColors.primaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  ticket.statusLabel,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ticket.subject,
            style: const TextStyle(
              color: TourFlowColors.heading,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            ticket.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: TourFlowColors.body, fontSize: 12),
          ),
          const Divider(height: 22),
          Text(
            'Last updated ${_formatDate(ticket.updatedAt)}',
            style: const TextStyle(color: TourFlowColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}
