import 'package:flutter/material.dart';

import '../../models/support_ticket_models.dart';
import '../../services/support_ticket_service.dart';
import '../../widgets/navigation/navigation_routes.dart';
import '../../widgets/tourflow_widgets.dart';
import 'staff_support_ticket_details_page.dart';

class SupportTicketManagementPage extends StatefulWidget {
  const SupportTicketManagementPage({
    this.navigationRole = TourFlowNavigationRole.staff,
    super.key,
  });

  static const routeName = TourFlowRoutes.staffSupportTickets;
  final TourFlowNavigationRole navigationRole;

  @override
  State<SupportTicketManagementPage> createState() =>
      _SupportTicketManagementPageState();
}

class _SupportTicketManagementPageState
    extends State<SupportTicketManagementPage> {
  final SupportTicketService _service = SupportTicketService();

  List<SupportTicket> _tickets = const [];
  String _selectedStatus = 'all';
  String _query = '';
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
      final tickets = await _service.fetchManagedTickets();
      if (!mounted) return;
      setState(() {
        _tickets = tickets;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _message(error);
      });
    }
  }

  Future<void> _openTicket(SupportTicket ticket) async {
    await Navigator.pushNamed(
      context,
      StaffSupportTicketDetailsPage.routeName,
      arguments: StaffSupportTicketArguments(
        navigationRole: widget.navigationRole,
        ticketId: ticket.id,
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final visible = _tickets.where((ticket) {
      final statusMatches =
          _selectedStatus == 'all' || ticket.status == _selectedStatus;
      final queryMatches = query.isEmpty ||
          ticket.code.toLowerCase().contains(query) ||
          ticket.subject.toLowerCase().contains(query) ||
          ticket.requesterName.toLowerCase().contains(query) ||
          ticket.attractionName.toLowerCase().contains(query) ||
          ticket.submissionLanguageLabel.toLowerCase().contains(query);
      return statusMatches && queryMatches;
    }).toList();

    final pending = _tickets.where((item) => item.status == 'pending').length;
    final inProgress =
        _tickets.where((item) => item.status == 'in_progress').length;
    final resolved = _tickets.where((item) => item.status == 'resolved').length;

    return TourFlowPage(
      title: 'Support Tickets',
      role: widget.navigationRole == TourFlowNavigationRole.administrator
          ? 'TOURFLOW · ADMINISTRATOR'
          : 'TOURFLOW · STAFF',
      navigationRole: widget.navigationRole,
      pageLevel: TourFlowPageLevel.topLevel,
      selectedNavigationIndex:
          widget.navigationRole == TourFlowNavigationRole.administrator ? 2 : 0,
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
            'Support overview',
            subtitle:
                'Review tourist complaints, reply, and update ticket progress.',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  label: 'Pending',
                  value: '$pending',
                  icon: Icons.pending_actions_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricCard(
                  label: 'In Progress',
                  value: '$inProgress',
                  icon: Icons.autorenew_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          MetricCard(
            label: 'Resolved',
            value: '$resolved',
            icon: Icons.task_alt_rounded,
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText:
                  'Search ticket ID, subject, tourist, attraction, or language',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: const {
                'all': 'All',
                'pending': 'Pending',
                'in_progress': 'In Progress',
                'resolved': 'Resolved',
              }.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(entry.value),
                    selected: _selectedStatus == entry.key,
                    onSelected: (_) =>
                        setState(() => _selectedStatus = entry.key),
                    selectedColor: TourFlowColors.primary,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const ModuleCard(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_error != null)
            ModuleCard(
              child: Column(
                children: [
                  Text(_error!, textAlign: TextAlign.center),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          else if (visible.isEmpty)
            const ModuleCard(child: Text('No support tickets found.'))
          else
            ...visible.map(
              (ticket) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ModuleCard(
                  padding: EdgeInsets.zero,
                  child: InkWell(
                    onTap: () => _openTicket(ticket),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  ticket.code,
                                  style: const TextStyle(
                                    color: TourFlowColors.primaryText,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              StatusChip(
                                label: ticket.priorityLabel.toUpperCase(),
                                color: ticket.priority == 'urgent'
                                    ? TourFlowColors.danger
                                    : TourFlowColors.warning,
                              ),
                              const SizedBox(width: 7),
                              StatusChip(
                                label: ticket.statusLabel.toUpperCase(),
                                color: _statusColor(ticket.status),
                              ),
                            ],
                          ),
                          const SizedBox(height: 9),
                          Text(
                            ticket.subject,
                            style: const TextStyle(
                              color: TourFlowColors.heading,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${ticket.requesterName} · ${ticket.attractionName}',
                            style: const TextStyle(
                              color: TourFlowColors.muted,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                Icons.translate_rounded,
                                size: 14,
                                color: TourFlowColors.primaryText,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  'Submission language: '
                                  '${ticket.submissionLanguageLabel}',
                                  style: const TextStyle(
                                    color: TourFlowColors.primaryText,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _dateTime(ticket.createdAt),
                            style: const TextStyle(
                              color: TourFlowColors.muted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Color _statusColor(String status) => switch (status) {
  'resolved' => TourFlowColors.success,
  'in_progress' => const Color(0xFF1D4ED8),
  _ => TourFlowColors.warning,
};

String _message(Object error) =>
    error.toString().replaceFirst('Exception: ', '').trim();

String _dateTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month/${value.year} $hour:$minute';
}
