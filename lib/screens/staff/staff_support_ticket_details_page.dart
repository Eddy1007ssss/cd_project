import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/support_ticket_models.dart';
import '../../services/support_ticket_service.dart';
import '../../widgets/fullscreen_network_image_viewer.dart';
import '../../widgets/tourflow_widgets.dart';

class StaffSupportTicketArguments {
  const StaffSupportTicketArguments({
    required this.ticketId,
    this.navigationRole = TourFlowNavigationRole.staff,
  });

  final String ticketId;
  final TourFlowNavigationRole navigationRole;
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
  final SupportTicketService _service = SupportTicketService();
  final TextEditingController _responseController = TextEditingController();

  StaffSupportTicketArguments? _arguments;
  SupportTicketDetailsData? _details;
  String _status = 'pending';
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Timer? _refreshTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_arguments != null) return;
    final value = ModalRoute.of(context)?.settings.arguments;
    if (value is! StaffSupportTicketArguments) {
      setState(() {
        _loading = false;
        _error = 'Support ticket ID is missing.';
      });
      return;
    }
    _arguments = value;
    _load();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        if (mounted && !_saving && ModalRoute.of(context)?.isCurrent == true) {
          _load(showLoader: false);
        }
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _load({bool showLoader = true}) async {
    final id = _arguments?.ticketId;
    if (id == null) return;
    setState(() {
      if (showLoader) _loading = true;
      _error = null;
    });
    try {
      final details = await _service.fetchTicketDetails(id);
      if (!mounted) return;
      setState(() {
        _details = details;
        _status = details.ticket.status;
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

  Future<void> _sendResponse() async {
    final text = _responseController.text.trim();
    if (text.length < 2 || _saving) {
      if (text.length < 2) _snack('Write a response before sending.');
      return;
    }
    setState(() => _saving = true);
    try {
      final status = await _service.replyToTicket(_arguments!.ticketId, text);
      _responseController.clear();
      _status = status;
      await _load(showLoader: false);
      if (mounted) _snack('Response sent to the tourist.');
    } catch (error) {
      if (mounted) _snack(_message(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveStatus() async {
    if (_saving || _details?.ticket.status == _status) return;
    setState(() => _saving = true);
    try {
      await _service.updateTicketStatus(_arguments!.ticketId, _status);
      await _load(showLoader: false);
      if (mounted) _snack('Ticket status updated.');
    } catch (error) {
      if (mounted) _snack(_message(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _transfer(String handlerType) async {
    if (_saving || _details?.ticket.handlerType == handlerType) return;
    setState(() => _saving = true);
    try {
      await _service.transferTicket(_arguments!.ticketId, handlerType);
      await _load(showLoader: false);
      if (mounted) _snack('Ticket routed to $handlerType.');
    } catch (error) {
      if (mounted) _snack(_message(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigationRole =
        _arguments?.navigationRole ?? TourFlowNavigationRole.staff;
    return TourFlowPage(
      title: 'Support Ticket Details',
      role: navigationRole == TourFlowNavigationRole.administrator
          ? 'TOURFLOW · ADMINISTRATOR'
          : navigationRole == TourFlowNavigationRole.operator
          ? 'TOURFLOW · OPERATOR'
          : 'TOURFLOW · STAFF',
      navigationRole: navigationRole,
      selectedNavigationIndex: navigationRole == TourFlowNavigationRole.operator
          ? 4
          : navigationRole == TourFlowNavigationRole.administrator
          ? 4
          : 0,
      actions: [
        IconButton(
          tooltip: 'Refresh',
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
          ? ModuleCard(
              child: Column(
                children: [
                  Text(_error!, textAlign: TextAlign.center),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : _buildDetails(),
    );
  }

  Widget _buildDetails() {
    final data = _details!;
    final ticket = data.ticket;
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
                    child: Text(
                      ticket.code,
                      style: const TextStyle(
                        color: TourFlowColors.primaryText,
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
              const SizedBox(height: 10),
              Text(
                '${ticket.requesterName} · ${ticket.attractionName}',
                style: const TextStyle(
                  color: TourFlowColors.muted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.translate_rounded,
                      size: 17,
                      color: Color(0xFF1D4ED8),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Submission language:',
                      style: TextStyle(
                        color: TourFlowColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        ticket.submissionLanguageLabel,
                        style: const TextStyle(
                          color: Color(0xFF1D4ED8),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (ticket.bookingCode != null) ...[
                const SizedBox(height: 5),
                Text(
                  'Booking: ${ticket.bookingCode}',
                  style: const TextStyle(
                    color: TourFlowColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
              const SizedBox(height: 7),
              Text(
                'Handler: ${ticket.handlerType == 'operator' ? 'Attraction Operator' : 'TourFlow Admin'}',
                style: const TextStyle(
                  color: TourFlowColors.primaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Divider(height: 25),
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
        if (_arguments?.navigationRole ==
            TourFlowNavigationRole.administrator) ...[
          const SizedBox(height: 16),
          const SectionTitle('Routing'),
          const SizedBox(height: 10),
          ModuleCard(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    ticket.handlerType == 'operator'
                        ? 'Attraction Operator'
                        : 'TourFlow Admin',
                  ),
                ),
                OutlinedButton(
                  onPressed: _saving
                      ? null
                      : () => _transfer(
                          ticket.handlerType == 'operator'
                              ? 'admin'
                              : 'operator',
                        ),
                  child: Text(
                    ticket.handlerType == 'operator'
                        ? 'Move to Admin'
                        : 'Move to Operator',
                  ),
                ),
              ],
            ),
          ),
        ],
        if (data.attachments.isNotEmpty) ...[
          const SizedBox(height: 16),
          const SectionTitle('Attachments'),
          const SizedBox(height: 10),
          ...data.attachments.map(
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
                      heroTag: 'staff-ticket-attachment-${attachment.id}',
                    ),
                    const SizedBox(height: 7),
                    Text(attachment.fileName),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        const SectionTitle('Status'),
        const SizedBox(height: 10),
        ModuleCard(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Ticket status',
                  border: OutlineInputBorder(),
                ),
                items:
                    const {
                          'pending': 'Pending',
                          'in_progress': 'In Progress',
                          'resolved': 'Resolved',
                        }.entries
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _status = value ?? _status),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving || ticket.status == _status
                      ? null
                      : _saveStatus,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Status'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionTitle('Reply to tourist'),
        const SizedBox(height: 10),
        ModuleCard(
          child: Column(
            children: [
              TextField(
                controller: _responseController,
                minLines: 3,
                maxLines: 6,
                maxLength: 4000,
                enabled: !_saving,
                decoration: const InputDecoration(
                  hintText:
                      'Write a clear response or request more information…',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _sendResponse,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Send Response'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionTitle(
          'Complete processing history',
          subtitle: 'Oldest activity appears first.',
        ),
        const SizedBox(height: 10),
        ...data.events.map(
          (event) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ModuleCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _eventTitle(event),
                    style: const TextStyle(
                      color: TourFlowColors.heading,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${event.actorName} · ${_dateTime(event.createdAt)}',
                    style: const TextStyle(
                      color: TourFlowColors.muted,
                      fontSize: 10,
                    ),
                  ),
                  if (event.message?.isNotEmpty == true) ...[
                    const SizedBox(height: 7),
                    Text(
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
          ),
        ),
      ],
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

String _eventTitle(SupportTicketEvent event) => switch (event.eventType) {
  'created' => 'Ticket submitted',
  'status_changed' =>
    'Status changed to ${supportTicketStatusLabel(event.toStatus)}',
  'attachment' => 'Attachment added',
  'routing_changed' => 'Support routing changed',
  _ => '${event.actorName} replied',
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
