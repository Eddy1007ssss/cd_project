import 'package:flutter/material.dart';

import '../../widgets/tourflow_widgets.dart';
import 'support_ticket_details_page.dart';
import 'support_ticket_form_page.dart';

class SupportTicketListPage extends StatefulWidget {
  const SupportTicketListPage({super.key});

  static const routeName = '/user/support-tickets';

  @override
  State<SupportTicketListPage> createState() => _SupportTicketListPageState();
}

class _SupportTicketListPageState extends State<SupportTicketListPage> {
  String _selectedStatus = 'All';

  static const _tickets = [
    _SupportTicket(
      id: 'TF-SUP-1048',
      subject: 'Unable to reschedule museum booking',
      category: 'Booking Problem',
      status: 'Pending',
      date: '1 Sep 2026, 9:42 AM',
      assignedTo: 'TourFlow Administrator',
      description:
          'The new time slot appears available, but the reschedule button does not complete the request.',
    ),
    _SupportTicket(
      id: 'TF-SUP-1032',
      subject: 'Crowd level did not update',
      category: 'Technical Issue',
      status: 'In Progress',
      date: '30 Aug 2026, 3:15 PM',
      assignedTo: 'Old Town Square Operator',
      description:
          'The attraction page continued showing Low crowd level during a very busy period.',
    ),
    _SupportTicket(
      id: 'TF-SUP-0987',
      subject: 'Wheelchair entrance information',
      category: 'Attraction Information',
      status: 'Resolved',
      date: '24 Aug 2026, 11:08 AM',
      assignedTo: 'National Museum Operator',
      description:
          'I needed confirmation about the accessible entrance before my visit.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visible = _selectedStatus == 'All'
        ? _tickets
        : _tickets.where((ticket) => ticket.status == _selectedStatus).toList();

    return TourFlowPage(
      title: 'My Support Tickets',
      role: 'TOURFLOW · TOURIST',
      selectedNavigationIndex: 3,
      displayName: 'Alex Tan',
      email: 'alex@example.com',
      actions: [
        IconButton(
          tooltip: 'Create ticket',
          onPressed: () =>
              Navigator.pushNamed(context, SupportTicketFormPage.routeName),
          icon: const Icon(Icons.add_circle_outline_rounded),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            'Track your enquiries',
            subtitle:
                'View administrator or attraction-operator responses and follow each ticket status.',
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Pending', 'In Progress', 'Resolved']
                  .map(
                    (status) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(status),
                        selected: _selectedStatus == status,
                        onSelected: (_) =>
                            setState(() => _selectedStatus = status),
                        selectedColor: TourFlowColors.primary,
                        side: const BorderSide(color: TourFlowColors.border),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          ...visible.map(
            (ticket) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ModuleCard(
                padding: EdgeInsets.zero,
                child: InkWell(
                  onTap: () => Navigator.pushNamed(
                    context,
                    SupportTicketDetailsPage.routeName,
                    arguments: SupportTicketDetailsArguments(
                      id: ticket.id,
                      subject: ticket.subject,
                      category: ticket.category,
                      status: ticket.status,
                      date: ticket.date,
                      assignedTo: ticket.assignedTo,
                      description: ticket.description,
                    ),
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                ticket.id,
                                style: const TextStyle(
                                  color: TourFlowColors.primaryText,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .5,
                                ),
                              ),
                            ),
                            _TicketStatusChip(status: ticket.status),
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
                        const SizedBox(height: 5),
                        Text(
                          ticket.category,
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
                              child: Text(
                                ticket.date,
                                style: const TextStyle(
                                  color: TourFlowColors.muted,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const Text(
                              'View details',
                              style: TextStyle(
                                color: TourFlowColors.primaryText,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: TourFlowColors.primaryText,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, SupportTicketFormPage.routeName),
              style: FilledButton.styleFrom(
                backgroundColor: TourFlowColors.primary,
                foregroundColor: TourFlowColors.primaryText,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create New Ticket'),
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
    final (background, foreground) = switch (status) {
      'Resolved' => (const Color(0xFFDCFCE7), TourFlowColors.success),
      'In Progress' => (const Color(0xFFDBEAFE), const Color(0xFF1D4ED8)),
      _ => (const Color(0xFFFFE2A8), TourFlowColors.primaryText),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SupportTicket {
  const _SupportTicket({
    required this.id,
    required this.subject,
    required this.category,
    required this.status,
    required this.date,
    required this.assignedTo,
    required this.description,
  });

  final String id;
  final String subject;
  final String category;
  final String status;
  final String date;
  final String assignedTo;
  final String description;
}
