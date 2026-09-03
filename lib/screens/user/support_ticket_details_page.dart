import 'package:flutter/material.dart';

import '../../widgets/tourflow_widgets.dart';

class SupportTicketDetailsArguments {
  const SupportTicketDetailsArguments({
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

class SupportTicketDetailsPage extends StatefulWidget {
  const SupportTicketDetailsPage({super.key});

  static const routeName = '/user/support-ticket-details';

  @override
  State<SupportTicketDetailsPage> createState() =>
      _SupportTicketDetailsPageState();
}

class _SupportTicketDetailsPageState extends State<SupportTicketDetailsPage> {
  final TextEditingController _replyController = TextEditingController();
  bool _replySent = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routeArguments = ModalRoute.of(context)?.settings.arguments;
    final ticket = routeArguments is SupportTicketDetailsArguments
        ? routeArguments
        : const SupportTicketDetailsArguments(
            id: 'TF-SUP-1032',
            subject: 'Crowd level did not update',
            category: 'Technical Issue',
            status: 'In Progress',
            date: '30 Aug 2026, 3:15 PM',
            assignedTo: 'Old Town Square Operator',
            description:
                'The attraction page continued showing Low crowd level during a very busy period.',
          );

    return TourFlowPage(
      title: 'Ticket Details',
      role: 'TOURFLOW · TOURIST',
      selectedNavigationIndex: 3,
      displayName: 'Alex Tan',
      email: 'alex@example.com',
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
                    _StatusChip(status: ticket.status),
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
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _Metadata(
                      icon: Icons.category_outlined,
                      text: ticket.category,
                    ),
                    _Metadata(icon: Icons.schedule_rounded, text: ticket.date),
                  ],
                ),
                const Divider(height: 26),
                const Text(
                  'Your message',
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
          const SectionTitle('Ticket activity'),
          const SizedBox(height: 12),
          _TimelineItem(
            title: 'Ticket submitted',
            subtitle: ticket.date,
            icon: Icons.send_outlined,
            complete: true,
          ),
          _TimelineItem(
            title: 'Assigned to ${ticket.assignedTo}',
            subtitle: '30 Aug 2026, 3:28 PM',
            icon: Icons.support_agent_rounded,
            complete: true,
          ),
          const _TimelineItem(
            title: 'Operator response',
            subtitle:
                'We are checking the crowd sensor and live dashboard connection. We will update you shortly.',
            icon: Icons.forum_outlined,
            complete: false,
          ),
          if (_replySent)
            const _TimelineItem(
              title: 'Your reply sent',
              subtitle: 'Thank you. I will wait for the update.',
              icon: Icons.reply_rounded,
              complete: false,
            ),
          const SizedBox(height: 16),
          ModuleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add a reply',
                  style: TextStyle(
                    color: TourFlowColors.heading,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 9),
                TextField(
                  controller: _replyController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Write additional information...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () {
                      if (_replyController.text.trim().isEmpty) return;
                      setState(() => _replySent = true);
                      _replyController.clear();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: TourFlowColors.primary,
                      foregroundColor: TourFlowColors.primaryText,
                    ),
                    icon: const Icon(Icons.reply_rounded),
                    label: const Text('Send Reply'),
                  ),
                ),
              ],
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

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.complete,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ModuleCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: complete
                  ? const Color(0xFFDCFCE7)
                  : TourFlowColors.lavender,
              foregroundColor: complete
                  ? TourFlowColors.success
                  : TourFlowColors.primaryText,
              child: Icon(icon, size: 19),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: TourFlowColors.heading,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: TourFlowColors.muted,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

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
