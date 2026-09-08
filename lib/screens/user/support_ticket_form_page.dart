import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/support_ticket_models.dart';
import '../../services/support_ticket_service.dart';
import '../../widgets/navigation/navigation_routes.dart';
import '../../widgets/tourflow_widgets.dart';
import 'support_ticket_list_page.dart';

class SupportTicketFormPage extends StatefulWidget {
  const SupportTicketFormPage({super.key});

  static const routeName = TourFlowRoutes.supportTicketForm;

  @override
  State<SupportTicketFormPage> createState() => _SupportTicketFormPageState();
}

class _SupportTicketFormPageState extends State<SupportTicketFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final SupportTicketService _service = SupportTicketService();
  final ImagePicker _imagePicker = ImagePicker();

  static const _categories = {
    'overcrowding': 'Overcrowding',
    'facility_damage': 'Facility Damage',
    'safety': 'Safety Concern',
    'staff_service': 'Staff Service',
    'other': 'Other',
  };

  List<SupportAttractionOption> _attractions = const [];
  List<SupportBookingOption> _bookings = const [];
  String _category = 'overcrowding';
  String? _attractionId;
  String _bookingId = '';
  ComplaintPhoto? _photo;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.fetchApprovedAttractions(),
        _service.fetchMyBookings(),
      ]);
      if (!mounted) return;
      final attractions = results[0] as List<SupportAttractionOption>;
      setState(() {
        _attractions = attractions;
        _bookings = results[1] as List<SupportBookingOption>;
        _attractionId = attractions.isEmpty ? null : attractions.first.id;
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

  Future<void> _pickPhoto() async {
    try {
      final selected = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
        requestFullMetadata: false,
      );
      if (selected == null) return;
      final bytes = await selected.readAsBytes();
      if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
        _snack('Choose an image that is 5 MB or smaller.');
        return;
      }
      final mimeType = selected.mimeType ?? _mimeType(selected.name);
      if (!const {'image/jpeg', 'image/png', 'image/webp'}.contains(mimeType)) {
        _snack('Only JPEG, PNG, and WebP images are supported.');
        return;
      }
      if (!mounted) return;
      setState(() {
        _photo = ComplaintPhoto(
          bytes: Uint8List.fromList(bytes),
          fileName: selected.name,
          mimeType: mimeType,
        );
      });
    } catch (error) {
      if (mounted) _snack(_message(error));
    }
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate() || _attractionId == null) return;
    setState(() => _saving = true);
    try {
      final result = await _service.createTicket(
        attractionId: _attractionId!,
        bookingId: _bookingId.isEmpty ? null : _bookingId,
        category: _category,
        subject: _subjectController.text,
        description: _descriptionController.text,
        photo: _photo,
      );
      if (!mounted) return;
      if (result.attachmentWarning != null) _snack(result.attachmentWarning!);
      final viewTickets = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.check_circle_rounded,
            size: 42,
            color: TourFlowColors.success,
          ),
          title: const TourFlowText('Support ticket submitted'),
          content: TourFlowText(
            'Ticket ID: ${result.code}\nCurrent status: Pending',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const TourFlowText('Close'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const TourFlowText('View Tickets'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (viewTickets == true) {
        Navigator.pushReplacementNamed(
          context,
          SupportTicketListPage.routeName,
        );
      } else {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) _snack(_message(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TourFlowPage(
      title: 'Create Support Ticket',
      role: 'TOURFLOW · TOURIST',
      selectedNavigationIndex: 3,
      child: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator()),
            )
          : _error != null
          ? ModuleCard(
              child: Column(
                children: [
                  TourFlowText(_error!, textAlign: TextAlign.center),
                  TextButton(
                    onPressed: _loadOptions,
                    child: const TourFlowText('Retry'),
                  ),
                ],
              ),
            )
          : _attractions.isEmpty
          ? const ModuleCard(
              child: TourFlowText(
                'No approved attraction is available for a ticket.',
              ),
            )
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(
                    'How can we help?',
                    subtitle:
                        'Your ticket will be saved to your account and visible to authorised TourFlow staff.',
                  ),
                  const SizedBox(height: 16),
                  ModuleCard(
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _category,
                          decoration: _decoration('Complaint category'),
                          items: _categories.entries
                              .map(
                                (entry) => DropdownMenuItem(
                                  value: entry.key,
                                  child: TourFlowText(entry.value),
                                ),
                              )
                              .toList(),
                          onChanged: _saving
                              ? null
                              : (value) => setState(
                                  () => _category = value ?? _category,
                                ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          key: ValueKey('attraction-$_attractionId'),
                          initialValue: _attractionId,
                          decoration: _decoration('Related attraction'),
                          items: _attractions
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item.id,
                                  child: TourFlowText(item.name),
                                ),
                              )
                              .toList(),
                          onChanged: _saving
                              ? null
                              : (value) => setState(() {
                                  _attractionId = value;
                                  final selectedBooking = _bookings
                                      .where((item) => item.id == _bookingId)
                                      .firstOrNull;
                                  if (selectedBooking?.attractionId != value) {
                                    _bookingId = '';
                                  }
                                }),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          key: ValueKey('booking-$_bookingId-$_attractionId'),
                          initialValue: _bookingId,
                          decoration: _decoration('Related booking (optional)'),
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: TourFlowText('No related booking'),
                            ),
                            ..._bookings.map(
                              (item) => DropdownMenuItem(
                                value: item.id,
                                child: TourFlowText(
                                  '${item.code} · ${item.attractionName}',
                                ),
                              ),
                            ),
                          ],
                          onChanged: _saving
                              ? null
                              : (value) => setState(() {
                                  _bookingId = value ?? '';
                                  final booking = _bookings
                                      .where((item) => item.id == _bookingId)
                                      .firstOrNull;
                                  if (booking != null) {
                                    _attractionId = booking.attractionId;
                                  }
                                }),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _subjectController,
                          maxLength: 160,
                          decoration: _decoration('Subject'),
                          validator: (value) =>
                              value == null || value.trim().length < 5
                              ? 'Enter at least 5 characters.'
                              : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionController,
                          minLines: 4,
                          maxLines: 7,
                          maxLength: 4000,
                          decoration: _decoration('Complaint details'),
                          validator: (value) =>
                              value == null || value.trim().length < 10
                              ? 'Enter at least 10 characters.'
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _saving ? null : _pickPhoto,
                                icon: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                ),
                                label: TourFlowText(
                                  _photo == null
                                      ? 'Add Photo (optional)'
                                      : 'Change Photo',
                                ),
                              ),
                            ),
                            if (_photo != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: context.tr('Remove photo'),
                                onPressed: _saving
                                    ? null
                                    : () => setState(() => _photo = null),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ],
                        ),
                        if (_photo != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TourFlowText(
                              _photo!.fileName,
                              style: const TextStyle(
                                color: TourFlowColors.muted,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _submitTicket,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                      label: TourFlowText(
                        _saving ? 'Submitting…' : 'Submit Support Ticket',
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );

  String _mimeType(String fileName) =>
      switch (fileName.toLowerCase().split('.').last) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'application/octet-stream',
      };

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: TourFlowText(message)));
  }
}

String _message(Object error) =>
    error.toString().replaceFirst('Exception: ', '').trim();
