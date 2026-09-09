import 'package:flutter/material.dart';

import '../../models/support_ticket_models.dart';
import '../../services/support_ticket_service.dart';
import '../../widgets/tourflow_widgets.dart';
import '../../widgets/navigation/navigation_routes.dart';
import 'support_ticket_details_page.dart';

class SupportTicketListPage extends StatefulWidget {
  const SupportTicketListPage({super.key});

  static const routeName = TourFlowRoutes.supportTicketList;

  @override
  State<SupportTicketListPage> createState() => _SupportTicketListPageState();
}

class _SupportTicketListPageState extends State<SupportTicketListPage> {
  final SupportTicketService _service = SupportTicketService();

  List<SupportTicket> _tickets = const [];
  String _selectedStatus = 'all';
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
        _loading = false;
        _error = _message(error);
      });
    }
  }

  Future<void> _openTicket(SupportTicket ticket) async {
    await Navigator.pushNamed(
      context,
      SupportTicketDetailsPage.routeName,
      arguments: SupportTicketDetailsArguments(ticketId: ticket.id),
    );
    if (mounted) await _load();
  }

  Future<void> _deleteTicket(SupportTicket ticket) async {
    if (ticket.status != 'pending') return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const TourFlowText('Delete pending ticket?'),
        content: TourFlowText(
          '${ticket.code} and its attachments will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const TourFlowText('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const TourFlowText('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final result = await _service.deletePendingTicket(ticket.id);
      if (!mounted) return;
      setState(
        () => _tickets = _tickets
            .where((existing) => existing.id != ticket.id)
            .toList(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TourFlowText(
            result.cleanupWarning ?? 'Support ticket deleted.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: TourFlowText(_message(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _selectedStatus == 'all'
        ? _tickets
        : _tickets.where((ticket) => ticket.status == _selectedStatus).toList();

    return TourFlowPage(
      title: 'My Support Tickets',
      role: 'TOURFLOW · TOURIST',
      selectedNavigationIndex: 3,
      actions: [
        IconButton(
          tooltip: context.tr('Refresh'),
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            'Track your support requests',
            subtitle:
                'View current status, staff responses, attachments, and the complete processing history.',
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  const {
                    'all': 'All',
                    'pending': 'Pending',
                    'in_progress': 'In Progress',
                    'resolved': 'Resolved',
                    'closed': 'Closed',
                  }.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: TourFlowText(entry.value),
                        selected: _selectedStatus == entry.key,
                        onSelected: (_) =>
                            setState(() => _selectedStatus = entry.key),
                        selectedColor: TourFlowColors.primary,
                        side: const BorderSide(color: TourFlowColors.border),
                      ),
                    );
                  }).toList(),
            ),
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
            _ErrorCard(message: _error!, onRetry: _load)
          else if (visible.isEmpty)
            ModuleCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.support_agent_rounded,
                      size: 44,
                      color: TourFlowColors.muted,
                    ),
                    const SizedBox(height: 9),
                    TourFlowText(
                      _tickets.isEmpty
                          ? 'You have not submitted any support tickets.'
                          : 'No tickets match this status.',
                    ),
                    if (_tickets.isEmpty) ...[
                      const SizedBox(height: 8),
                      const TourFlowText(
                        'Ask TourFlow Assistant to create a support ticket.',
                      ),
                    ],
                  ],
                ),
              ),
            )
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
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              TourFlowText(
                                ticket.code,
                                style: const TextStyle(
                                  color: TourFlowColors.primaryText,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              _TicketStatusChip(status: ticket.status),
                              if (ticket.status == 'pending') ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  tooltip: context.tr('Delete ticket'),
                                  onPressed: () => _deleteTicket(ticket),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: TourFlowColors.danger,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 9),
                          TourFlowText(
                            ticket.subject,
                            style: const TextStyle(
                              color: TourFlowColors.heading,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TourFlowText(
                            '${ticket.categoryLabel} · ${ticket.attractionName}',
                            style: const TextStyle(
                              color: TourFlowColors.body,
                              fontSize: 11,
                            ),
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 15,
                                color: TourFlowColors.muted,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: TourFlowText(
                                  _dateTime(ticket.createdAt),
                                  style: const TextStyle(
                                    color: TourFlowColors.muted,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              const TourFlowText(
                                'View details',
                                style: TextStyle(
                                  color: TourFlowColors.primaryText,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded),
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
      ),
    );
  }
}

class _TicketStatusChip extends StatelessWidget {
  const _TicketStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'resolved' => TourFlowColors.success,
      'in_progress' => const Color(0xFF1D4ED8),
      'closed' => TourFlowColors.muted,
      _ => TourFlowColors.warning,
    };
    return StatusChip(
      label: supportTicketStatusLabel(status).toUpperCase(),
      color: color,
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ModuleCard(
    child: Column(
      children: [
        TourFlowText(message, textAlign: TextAlign.center),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const TourFlowText('Try Again'),
        ),
      ],
    ),
  );
}

String _message(Object error) =>
    error.toString().replaceFirst('Exception: ', '').trim();

String _dateTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month/${value.year} $hour:$minute';
}
