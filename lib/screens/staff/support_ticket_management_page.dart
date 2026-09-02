import 'package:flutter/material.dart';

import '../../widgets/tourflow_widgets.dart';
import 'staff_support_ticket_details_page.dart';

class SupportTicketManagementPage extends StatefulWidget {
  const SupportTicketManagementPage({super.key});

  static const routeName = '/staff/support-tickets';

  @override
  State<SupportTicketManagementPage> createState() =>
      _SupportTicketManagementPageState();
}

class _SupportTicketManagementPageState
    extends State<SupportTicketManagementPage> {
  String _selectedStatus = 'All';
  String _query = '';

  static const _tickets = [
    _StaffTicket(
      id: 'TF-SUP-1048',
      subject: 'Unable to reschedule museum booking',
      tourist: 'Alex Tan',
      category: 'Booking Problem',
      status: 'Pending',
      priority: 'High',
      submitted: '12 minutes ago',
      assignee: 'Unassigned',
      description:
          'The new time slot appears available, but the reschedule button does not complete the request.',
    ),
    _StaffTicket(
      id: 'TF-SUP-1044',
      subject: 'Crowd level did not update',
      tourist: 'Maya Lee',
      category: 'Technical Issue',
      status: 'In Progress',
      priority: 'Medium',
      submitted: '1 hour ago',
      assignee: 'Old Town Square Operator',
      description:
          'The attraction page continued showing Low crowd level during a very busy period.',
    ),
    _StaffTicket(
      id: 'TF-SUP-1039',
      subject: 'Safety concern near entrance',
      tourist: 'Daniel Wong',
      category: 'Safety Concern',
      status: 'Pending',
      priority: 'Critical',
      submitted: '2 hours ago',
      assignee: 'National Museum Operator',
      description:
          'The accessible entrance was temporarily blocked by maintenance equipment.',
    ),
    _StaffTicket(
      id: 'TF-SUP-1021',
      subject: 'Wheelchair entrance information',
      tourist: 'Siti Aminah',
      category: 'Attraction Information',
      status: 'Resolved',
      priority: 'Low',
      submitted: 'Yesterday',
      assignee: 'National Museum Operator',
      description:
          'The tourist requested confirmation about the accessible entrance.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visible = _tickets.where((ticket) {
      final matchesStatus =
          _selectedStatus == 'All' || ticket.status == _selectedStatus;
      final search = _query.toLowerCase();
      final matchesQuery = ticket.id.toLowerCase().contains(search) ||
          ticket.subject.toLowerCase().contains(search) ||
          ticket.tourist.toLowerCase().contains(search);
      return matchesStatus && matchesQuery;
    }).toList();

    return TourFlowPage(
      title: 'Support Tickets',
      role: 'TOURFLOW · ADMIN / OPERATOR',
      showBackButton: false,
      isStaff: true,
      selectedNavigationIndex: 5,
      displayName: 'Alex Thompson',
      email: 'alex.thompson@tourflow.com',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            'Support overview',
            subtitle:
                'Review tourist enquiries, respond to complaints and update ticket progress.',
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                child: MetricCard(
                  label: 'Pending',
                  value: '12',
                  icon: Icons.pending_actions_rounded,
                  note: '3 high priority',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: MetricCard(
                  label: 'In Progress',
                  value: '8',
                  icon: Icons.autorenew_rounded,
                  note: 'Avg. 4.2 hours',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const MetricCard(
            label: 'Resolved Today',
            value: '24',
            icon: Icons.task_alt_rounded,
            note: '92% within target',
          ),
          const SizedBox(height: 18),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Search ticket ID, subject or tourist',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: TourFlowColors.border),
              ),
            ),
          ),
          const SizedBox(height: 12),
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
                        onSelected: (_) => setState(
                          () => _selectedStatus = status,
                        ),
                        selectedColor: TourFlowColors.primary,
                        side: const BorderSide(color: TourFlowColors.border),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${visible.length} tickets',
                  style: const TextStyle(
                    color: TourFlowColors.heading,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.filter_list_rounded, size: 18),
                label: const Text('More filters'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...visible.map(
            (ticket) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ModuleCard(
                padding: EdgeInsets.zero,
                child: InkWell(
                  onTap: () => Navigator.pushNamed(
                    context,
                    StaffSupportTicketDetailsPage.routeName,
                    arguments: StaffSupportTicketArguments(
                      id: ticket.id,
                      subject: ticket.subject,
                      tourist: ticket.tourist,
                      category: ticket.category,
                      status: ticket.status,
                      priority: ticket.priority,
                      submitted: ticket.submitted,
                      assignee: ticket.assignee,
                      description: ticket.description,
                    ),
                  ),
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
                                ticket.id,
                                style: const TextStyle(
                                  color: TourFlowColors.primaryText,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            _PriorityChip(priority: ticket.priority),
                            const SizedBox(width: 7),
                            _StatusChip(status: ticket.status),
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
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            _Metadata(
                              icon: Icons.person_outline_rounded,
                              text: ticket.tourist,
                            ),
                            _Metadata(
                              icon: Icons.category_outlined,
                              text: ticket.category,
                            ),
                            _Metadata(
                              icon: Icons.schedule_rounded,
                              text: ticket.submitted,
                            ),
                          ],
                        ),
                        const Divider(height: 22),
                        Row(
                          children: [
                            Icon(
                              ticket.assignee == 'Unassigned'
                                  ? Icons.person_add_alt_outlined
                                  : Icons.support_agent_rounded,
                              size: 16,
                              color: TourFlowColors.muted,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                ticket.assignee,
                                style: const TextStyle(
                                  color: TourFlowColors.muted,
                                  fontSize: 10,
                                ),
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
        ],
      ),
    );
  }
}

class _Metadata extends StatelessWidget {
  const _Metadata({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: TourFlowColors.muted),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: TourFlowColors.muted, fontSize: 10),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Resolved' => TourFlowColors.success,
      'In Progress' => const Color(0xFF1D4ED8),
      _ => TourFlowColors.warning,
    };
    return StatusChip(label: status.toUpperCase(), color: color);
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});

  final String priority;

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      'Critical' => TourFlowColors.danger,
      'High' => const Color(0xFFEA580C),
      'Medium' => TourFlowColors.warning,
      _ => TourFlowColors.muted,
    };
    return StatusChip(label: priority.toUpperCase(), color: color);
  }
}

class _StaffTicket {
  const _StaffTicket({
    required this.id,
    required this.subject,
    required this.tourist,
    required this.category,
    required this.status,
    required this.priority,
    required this.submitted,
    required this.assignee,
    required this.description,
  });

  final String id;
  final String subject;
  final String tourist;
  final String category;
  final String status;
  final String priority;
  final String submitted;
  final String assignee;
  final String description;
}
