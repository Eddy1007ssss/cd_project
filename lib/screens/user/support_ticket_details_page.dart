import 'package:flutter/material.dart';

import '../../models/support_ticket_models.dart';
import '../../services/support_ticket_service.dart';
import '../../widgets/fullscreen_network_image_viewer.dart';
import '../../widgets/tourflow_widgets.dart';

class SupportTicketDetailsArguments {
  const SupportTicketDetailsArguments({required this.ticketId});

  final String ticketId;
}

class SupportTicketDetailsPage extends StatefulWidget {
  const SupportTicketDetailsPage({super.key});

  static const routeName = '/user/support-ticket-details';

  @override
  State<SupportTicketDetailsPage> createState() =>
      _SupportTicketDetailsPageState();
}

class _SupportTicketDetailsPageState extends State<SupportTicketDetailsPage> {
  final SupportTicketService _service = SupportTicketService();

  SupportTicketDetailsData? _details;
  String? _ticketId;
  String? _error;
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ticketId != null) return;
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is! SupportTicketDetailsArguments) {
      setState(() {
        _loading = false;
        _error = 'Support ticket ID is missing.';
      });
      return;
    }
    _ticketId = arguments.ticketId;
    _load();
  }

  Future<void> _load() async {
    final id = _ticketId;
    if (id == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final details = await _service.fetchTicketDetails(id);
      if (!mounted) return;
      setState(() {
        _details = details;
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

  Future<void> _delete() async {
    final details = _details;
    final id = _ticketId;
    if (details?.ticket.status != 'pending' || id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const TourFlowText('Delete pending ticket?'),
        content: const TourFlowText(
          'This ticket and its attachments will be permanently deleted.',
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
      final result = await _service.deletePendingTicket(id);
      if (!mounted) return;
      if (result.cleanupWarning != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: TourFlowText(result.cleanupWarning!)));
      }
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: TourFlowText(_message(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TourFlowPage(
      title: 'Ticket Details',
      role: 'TOURFLOW · TOURIST',
      selectedNavigationIndex: 3,
      actions: [
        if (_details?.ticket.status == 'pending')
          IconButton(
            tooltip: context.tr('Delete ticket'),
            onPressed: _loading ? null : _delete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        IconButton(
          tooltip: context.tr('Refresh'),
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator()),
            )
          : _error != null
          ? _ErrorView(message: _error!, onRetry: _load)
          : _TicketDetailsBody(details: _details!),
    );
  }
}

class _TicketDetailsBody extends StatelessWidget {
  const _TicketDetailsBody({required this.details});

  final SupportTicketDetailsData details;

  @override
  Widget build(BuildContext context) {
    final ticket = details.ticket;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ModuleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TourFlowText(
                      ticket.code,
                      style: const TextStyle(
                        color: TourFlowColors.primaryText,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .6,
                      ),
                    ),
                  ),
                  StatusChip(
                    label: ticket.statusLabel.toUpperCase(),
                    color: _statusColor(ticket.status),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TourFlowText(
                ticket.subject,
                style: const TextStyle(
                  color: TourFlowColors.heading,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _Metadata(
                icon: Icons.attractions_outlined,
                text: ticket.attractionName,
              ),
              const SizedBox(height: 7),
              _Metadata(
                icon: Icons.category_outlined,
                text: ticket.categoryLabel,
              ),
              if (ticket.bookingCode != null) ...[
                const SizedBox(height: 7),
                _Metadata(
                  icon: Icons.confirmation_number_outlined,
                  text: ticket.bookingCode!,
                ),
              ],
              const SizedBox(height: 7),
              _Metadata(
                icon: Icons.schedule_rounded,
                text: _dateTime(ticket.createdAt),
              ),
              const Divider(height: 26),
              const TourFlowText(
                'Complaint details',
                style: TextStyle(
                  color: TourFlowColors.heading,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              TourFlowText(
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
        if (details.attachments.isNotEmpty) ...[
          const SizedBox(height: 16),
          const SectionTitle('Attachments'),
          const SizedBox(height: 10),
          ...details.attachments.map(
            (attachment) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ModuleCard(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FullscreenNetworkImageViewer(
                      imageUrl: attachment.signedUrl,
                      fileName: attachment.fileName,
                      heroTag: 'user-ticket-attachment-${attachment.id}',
                    ),
                    const SizedBox(height: 8),
                    TourFlowText(
                      attachment.fileName,
                      style: const TextStyle(
                        color: TourFlowColors.body,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        const SectionTitle(
          'Complete processing history',
          subtitle:
              'Status changes and staff responses are shown in time order.',
        ),
        const SizedBox(height: 10),
        if (details.events.isEmpty)
          const ModuleCard(
            child: TourFlowText('No activity has been recorded yet.'),
          )
        else
          ...details.events.map((event) => _TimelineEvent(event: event)),
      ],
    );
  }
}

class _TimelineEvent extends StatelessWidget {
  const _TimelineEvent({required this.event});

  final SupportTicketEvent event;

  @override
  Widget build(BuildContext context) {
    final (icon, title) = switch (event.eventType) {
      'created' => (Icons.add_task_rounded, 'Ticket submitted'),
      'status_changed' => (
        Icons.sync_alt_rounded,
        'Status changed to ${supportTicketStatusLabel(event.toStatus)}',
      ),
      'attachment' => (Icons.attach_file_rounded, 'Attachment added'),
      _ => (Icons.forum_outlined, '${event.actorName} replied'),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ModuleCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: TourFlowColors.lavender,
              foregroundColor: TourFlowColors.primaryText,
              child: Icon(icon, size: 19),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TourFlowText(
                    title,
                    style: const TextStyle(
                      color: TourFlowColors.heading,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  TourFlowText(
                    '${event.actorName} · ${_dateTime(event.createdAt)}',
                    style: const TextStyle(
                      color: TourFlowColors.muted,
                      fontSize: 10,
                    ),
                  ),
                  if (event.message?.isNotEmpty == true) ...[
                    const SizedBox(height: 7),
                    TourFlowText(
                      event.message!,
                      style: const TextStyle(
                        color: TourFlowColors.body,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metadata extends StatelessWidget {
  const _Metadata({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: TourFlowColors.muted),
      const SizedBox(width: 6),
      Expanded(
        child: TourFlowText(
          text,
          style: const TextStyle(color: TourFlowColors.muted, fontSize: 11),
        ),
      ),
    ],
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ModuleCard(
    child: Column(
      children: [
        TourFlowText(message, textAlign: TextAlign.center),
        const SizedBox(height: 10),
        TextButton(onPressed: onRetry, child: const TourFlowText('Try Again')),
      ],
    ),
  );
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
