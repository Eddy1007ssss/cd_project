import 'package:flutter/material.dart';

import '../../widgets/tourflow_widgets.dart';

class StaffSupportTicketArguments {
  const StaffSupportTicketArguments({
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

class StaffSupportTicketDetailsPage extends StatefulWidget {
  const StaffSupportTicketDetailsPage({super.key});

  static const routeName = '/staff/support-ticket-details';

  @override
  State<StaffSupportTicketDetailsPage> createState() =>
      _StaffSupportTicketDetailsPageState();
}

class _StaffSupportTicketDetailsPageState
    extends State<StaffSupportTicketDetailsPage> {
  final TextEditingController _responseController = TextEditingController();
  String _status = 'Pending';
  String _assignee = 'Unassigned';
  bool _initialized = false;
  bool _responseSent = false;

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routeArguments = ModalRoute.of(context)?.settings.arguments;
    final ticket = routeArguments is StaffSupportTicketArguments
        ? routeArguments
        : const StaffSupportTicketArguments(
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
          );

    if (!_initialized) {
      _status = ticket.status;
      _assignee = ticket.assignee;
      _initialized = true;
    }

    return TourFlowPage(
      title: 'Support Ticket Details',
      role: 'TOURFLOW · ADMIN / OPERATOR',
      isStaff: true,
      selectedNavigationIndex: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ModuleCard(
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
                          fontWeight: FontWeight.w800,
                          letterSpacing: .6,
                        ),
                      ),
                    ),
                    StatusChip(
                      label: ticket.priority.toUpperCase(),
                      color: ticket.priority == 'Critical'
                          ? TourFlowColors.danger
                          : TourFlowColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  ticket.subject,
                  style: const TextStyle(
                    color: TourFlowColors.heading,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 12,
                  runSpacing: 7,
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
                const Divider(height: 26),
                const Text(
                  'Tourist message',
                  style: TextStyle(
                    color: TourFlowColors.heading,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  ticket.description,
                  style: const TextStyle(
                    color: TourFlowColors.body,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionTitle('Assignment and status'),
          const SizedBox(height: 12),
          ModuleCard(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _assignee,
                  decoration: InputDecoration(
                    labelText: 'Assign ticket to',
                    prefixIcon: const Icon(Icons.support_agent_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    'Unassigned',
                    'TourFlow Administrator',
                    'National Museum Operator',
                    'Old Town Square Operator',
                  ]
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _assignee = value);
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: InputDecoration(
                    labelText: 'Ticket status',
                    prefixIcon: const Icon(Icons.flag_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const ['Pending', 'In Progress', 'Resolved']
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _status = value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionTitle('Respond to tourist'),
          const SizedBox(height: 12),
          ModuleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _responseController,
                  minLines: 4,
                  maxLines: 7,
                  decoration: InputDecoration(
                    hintText: 'Write a clear response or request more information...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.attach_file_rounded),
                      label: const Text('Attach'),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () {
                        if (_responseController.text.trim().isEmpty) return;
                        setState(() {
                          _responseSent = true;
                          if (_status == 'Pending') _status = 'In Progress';
                        });
                        _responseController.clear();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: TourFlowColors.primary,
                        foregroundColor: TourFlowColors.primaryText,
                      ),
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Send Response'),
                    ),
                  ],
                ),
                if (_responseSent) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Response sent to the tourist successfully.',
                      style: TextStyle(
                        color: TourFlowColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Ticket updated: $_status · $_assignee',
                  ),
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: TourFlowColors.primary,
                foregroundColor: TourFlowColors.primaryText,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Ticket Update'),
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
        Icon(icon, size: 15, color: TourFlowColors.muted),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(color: TourFlowColors.muted, fontSize: 10),
        ),
      ],
    );
  }
}
