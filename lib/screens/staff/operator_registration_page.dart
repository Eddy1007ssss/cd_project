import 'package:flutter/material.dart';

import '../../widgets/tourflow_widgets.dart';

class OperatorRegistrationPage extends StatefulWidget {
  const OperatorRegistrationPage({super.key});

  static const routeName = '/operator-registration';

  @override
  State<OperatorRegistrationPage> createState() =>
      _OperatorRegistrationPageState();
}

class _OperatorRegistrationPageState extends State<OperatorRegistrationPage> {
  bool _accepted = true;
  bool _licenceUploaded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TourFlowColors.background,
      appBar: AppBar(
        backgroundColor: TourFlowColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: const Color(0x140F172A),
        title: const Text(
          'Operator Registration',
          style: TextStyle(
            color: TourFlowColors.heading,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          child: Column(
            children: [
              const ModuleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle(
                      'Representative Details',
                      subtitle: 'Tell us who will manage the operator account.',
                    ),
                    SizedBox(height: 18),
                    StaticField(
                      label: 'Full Legal Name',
                      value: 'Johnathan Doe',
                    ),
                    SizedBox(height: 14),
                    StaticField(
                      label: 'Job Title / Role',
                      value: 'Operations Manager',
                    ),
                    SizedBox(height: 14),
                    StaticField(
                      label: 'Direct Contact Email',
                      value: 'j.doe@business.com',
                      icon: Icons.email_outlined,
                    ),
                    SizedBox(height: 14),
                    StaticField(
                      label: 'Primary Phone Number',
                      value: '+60 12-345 6789',
                      icon: Icons.phone_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ModuleCard(
                color: TourFlowColors.lavender,
                child: const Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: TourFlowColors.primary,
                      child: Text('AT'),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alex Thompson',
                            style: TextStyle(
                              color: TourFlowColors.heading,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Lead Operator Account',
                            style: TextStyle(
                              color: TourFlowColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusChip(
                      label: 'VERIFIED IDENTITY REQUIRED',
                      color: TourFlowColors.warning,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const ModuleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle('Business Information'),
                    SizedBox(height: 18),
                    StaticField(
                      label: 'Registered Business Name',
                      value: 'Heritage Experiences Sdn. Bhd.',
                      icon: Icons.business_outlined,
                    ),
                    SizedBox(height: 14),
                    StaticField(
                      label: 'Business Registration Number',
                      value: '202401023456',
                    ),
                    SizedBox(height: 14),
                    StaticField(
                      label: 'Business Email',
                      value: 'hello@heritageexperiences.my',
                      icon: Icons.email_outlined,
                    ),
                    SizedBox(height: 14),
                    StaticField(
                      label: 'Business Phone',
                      value: '+603-2181 8899',
                      icon: Icons.phone_outlined,
                    ),
                    SizedBox(height: 14),
                    StaticField(
                      label: 'Business Address',
                      value:
                          'Level 12, Menara Sentral, Jalan Tun Sambanthan, Kuala Lumpur',
                      icon: Icons.location_on_outlined,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ModuleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(
                      'Verification Documents',
                      subtitle:
                          'Documents are reviewed by an administrator before access is granted.',
                    ),
                    const SizedBox(height: 16),
                    _DocumentRow(
                      title: 'Business Registration Certificate',
                      fileName: 'ssm_certificate.pdf',
                      complete: true,
                      onTap: () {},
                    ),
                    const SizedBox(height: 10),
                    _DocumentRow(
                      title: 'Representative Identity Document',
                      fileName: 'identity_document.pdf',
                      complete: true,
                      onTap: () {},
                    ),
                    const SizedBox(height: 10),
                    _DocumentRow(
                      title: 'Business Operating Licence',
                      fileName: _licenceUploaded
                          ? 'operating_licence.pdf'
                          : 'Tap to upload document',
                      complete: _licenceUploaded,
                      onTap: () =>
                          setState(() => _licenceUploaded = !_licenceUploaded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _accepted,
                contentPadding: EdgeInsets.zero,
                activeColor: TourFlowColors.primaryText,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'I confirm that the information provided is accurate and complete.',
                  style: TextStyle(fontSize: 11),
                ),
                onChanged: (value) =>
                    setState(() => _accepted = value ?? false),
              ),
              PrimaryButton(
                label: 'Submit for Admin Review',
                icon: Icons.send_rounded,
                onPressed: () {
                  if (!_accepted || !_licenceUploaded) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Upload all documents and confirm the declaration first.',
                        ),
                      ),
                    );
                    return;
                  }
                  showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      icon: const Icon(
                        Icons.hourglass_top_rounded,
                        color: TourFlowColors.warning,
                      ),
                      title: const Text('Application Submitted'),
                      content: const Text(
                        'Application OP-2026-0142 is pending administrator review. You will be notified when its status changes.',
                      ),
                      actions: [
                        FilledButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Applications normally take 1–3 working days to review.',
                textAlign: TextAlign.center,
                style: TextStyle(color: TourFlowColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.title,
    required this.fileName,
    required this.complete,
    required this.onTap,
  });

  final String title;
  final String fileName;
  final bool complete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TourFlowColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: TourFlowColors.border.withOpacity(0.6)),
        ),
        child: Row(
          children: [
            Icon(
              complete ? Icons.description_rounded : Icons.upload_file_rounded,
              color: complete
                  ? TourFlowColors.success
                  : TourFlowColors.primaryText,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: TourFlowColors.heading,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fileName,
                    style: const TextStyle(
                      color: TourFlowColors.muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              complete ? Icons.check_circle_rounded : Icons.add_circle_outline,
              color: complete
                  ? TourFlowColors.success
                  : TourFlowColors.primaryText,
            ),
          ],
        ),
      ),
    );
  }
}
