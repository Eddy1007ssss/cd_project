import 'package:flutter/material.dart';

import '../../widgets/tourflow_widgets.dart';

class SupportTicketFormPage extends StatefulWidget {
  const SupportTicketFormPage({super.key});

  static const routeName = '/user/support-ticket/new';

  @override
  State<SupportTicketFormPage> createState() => _SupportTicketFormPageState();
}

class _SupportTicketFormPageState extends State<SupportTicketFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _category = 'General Enquiry';
  String _relatedAttraction = 'Not related to an attraction';

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    final viewTicket = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.check_circle_rounded,
          size: 42,
          color: TourFlowColors.success,
        ),
        title: const Text('Support ticket submitted'),
        content: const Text(
          'Your ticket TF-SUP-1048 has been created. You can track its status from My Support Tickets.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: TourFlowColors.primary,
              foregroundColor: TourFlowColors.primaryText,
            ),
            child: const Text('View Tickets'),
          ),
        ],
      ),
    );

    if (viewTicket == true && mounted) {
      Navigator.pushReplacementNamed(context, '/user/support-tickets');
    }
  }

  @override
  Widget build(BuildContext context) {
    return TourFlowPage(
      title: 'Create Support Ticket',
      role: 'TOURFLOW · TOURIST',
      selectedNavigationIndex: 3,
      displayName: 'Alex Tan',
      email: 'alex@example.com',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              'How can we help?',
              subtitle:
                  'Submit an enquiry or complaint when the chatbot cannot resolve your issue.',
            ),
            const SizedBox(height: 16),
            ModuleCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel('Issue category'),
                  const SizedBox(height: 7),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: _inputDecoration(Icons.category_outlined),
                    items: const [
                      'General Enquiry',
                      'Booking Problem',
                      'Attraction Information',
                      'Overcrowding Complaint',
                      'Safety Concern',
                      'Technical Issue',
                    ]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _category = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  const _FieldLabel('Related attraction'),
                  const SizedBox(height: 7),
                  DropdownButtonFormField<String>(
                    initialValue: _relatedAttraction,
                    decoration: _inputDecoration(Icons.attractions_outlined),
                    items: const [
                      'Not related to an attraction',
                      'National Museum',
                      'Old Town Square',
                      'Lake Garden',
                      'Lumina Botanical Gardens',
                    ]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _relatedAttraction = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const _FieldLabel('Subject'),
                  const SizedBox(height: 7),
                  TextFormField(
                    controller: _subjectController,
                    decoration: _inputDecoration(Icons.title_rounded).copyWith(
                      hintText: 'Briefly describe your issue',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length < 5) {
                        return 'Enter a subject with at least 5 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const _FieldLabel('Description'),
                  const SizedBox(height: 7),
                  TextFormField(
                    controller: _descriptionController,
                    minLines: 5,
                    maxLines: 7,
                    decoration: _inputDecoration(null).copyWith(
                      hintText:
                          'Explain what happened and include any important details...',
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length < 20) {
                        return 'Provide at least 20 characters so we can help you.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Static UI: attachment picker will be added later.'),
                      ),
                    ),
                    icon: const Icon(Icons.attach_file_rounded),
                    label: const Text('Add attachment (optional)'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6E8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    color: TourFlowColors.primaryText,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Most enquiries receive a response within 24 hours. Safety concerns are prioritised.',
                      style: TextStyle(
                        color: TourFlowColors.body,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submitTicket,
                style: FilledButton.styleFrom(
                  backgroundColor: TourFlowColors.primary,
                  foregroundColor: TourFlowColors.primaryText,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                icon: const Icon(Icons.send_rounded),
                label: const Text('Submit Support Ticket'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(IconData? icon) {
    return InputDecoration(
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TourFlowColors.border),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: TourFlowColors.body,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
