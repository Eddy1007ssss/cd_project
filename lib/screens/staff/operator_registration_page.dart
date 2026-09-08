import 'package:flutter/material.dart';
import '../../repositories/management_repository.dart';
import '../../widgets/navigation/navigation_routes.dart';
import '../user/tourist_registration_page.dart';
import 'management_ui.dart';

class OperatorRegistrationPage extends StatefulWidget {
  const OperatorRegistrationPage({super.key});
  static const routeName = '/operator-registration';
  @override
  State<OperatorRegistrationPage> createState() =>
      _OperatorRegistrationPageState();
}

class _OperatorRegistrationPageState extends State<OperatorRegistrationPage> {
  static const _labels = {
    'representative_name': 'Representative name',
    'job_title': 'Job title',
    'contact_email': 'Contact email',
    'contact_phone': 'Contact phone',
    'business_name': 'Business name',
    'registration_number': 'Registration number',
    'business_email': 'Business email',
    'business_phone': 'Business phone',
    'business_address': 'Business address',
  };
  static const _documents = {
    'registration_certificate_path': 'Registration certificate',
    'identity_document_path': 'Identity document',
    'operating_licence_path': 'Operating licence',
  };
  final _repository = ManagementRepository();
  final _form = GlobalKey<FormState>();
  final _fields = {
    for (final key in _labels.keys) key: TextEditingController(),
  };
  final Map<String, String> _paths = {};
  Future<List<ManagementRow>>? _applications;
  bool _busy = false;
  bool _accepted = false;
  @override
  void initState() {
    super.initState();
    if (_repository.client.auth.currentUser != null) {
      _applications = _repository.applications();
    }
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _upload(String key) async {
    setState(() => _busy = true);
    try {
      final path = await pickManagementImage(
        _repository,
        bucket: 'operator-documents',
        folder: _repository.userId,
      );
      if (path != null && mounted) setState(() => _paths[key] = path);
    } catch (error) {
      if (mounted) managementMessage(context, managementError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (!_accepted || _paths.length != 3) {
      managementMessage(
        context,
        'Upload all three documents and accept the declaration.',
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await _repository.submitApplication({
        for (final e in _fields.entries) e.key: e.value.text.trim(),
        ..._paths,
      });
      if (mounted) {
        setState(() => _applications = _repository.applications());
        managementMessage(
          context,
          'Application saved. Await administrator review.',
        );
      }
    } catch (error) {
      if (mounted) managementMessage(context, managementError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Operator Registration')),
    body: _applications == null
        ? Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  'Create a tourist account and sign in first. Then open Operator Application from your profile. '
                  'Administrator approval upgrades that account to an operator.',
                ),
                FilledButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    TouristRegistrationPage.routeName,
                  ),
                  child: const Text('Create Account'),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    TourFlowRoutes.signIn,
                    (_) => false,
                  ),
                  child: const Text('Sign In'),
                ),
              ],
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ManagementRows(
                future: _applications!,
                retry: () =>
                    setState(() => _applications = _repository.applications()),
                builder: (rows) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final row in rows)
                      Card(
                        child: ListTile(
                          title: Text(
                            '${row['business_name']} · ${row['status']}',
                          ),
                          subtitle: Text(
                            '${row['review_note'] ?? 'Awaiting review. Sign in again after approval.'}',
                          ),
                        ),
                      ),
                    if (!rows.any(
                      (row) =>
                          row['status'] == 'pending' ||
                          row['status'] == 'approved',
                    ))
                      Form(
                        key: _form,
                        child: AbsorbPointer(
                          absorbing: _busy,
                          child: Column(
                            children: [
                              for (final e in _labels.entries)
                                managementField(
                                  e.value,
                                  _fields[e.key]!,
                                  validator: e.key.endsWith('email')
                                      ? (value) =>
                                            RegExp(
                                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                            ).hasMatch((value ?? '').trim())
                                            ? null
                                            : 'Enter a valid email'
                                      : null,
                                ),
                              const Text(
                                'Upload clear JPG, PNG or WebP scans (up to 10 MB each). Documents remain private.',
                              ),
                              for (final e in _documents.entries)
                                ListTile(
                                  title: Text(e.value),
                                  subtitle: Text(
                                    _paths.containsKey(e.key)
                                        ? 'Uploaded'
                                        : 'Required',
                                  ),
                                  trailing: IconButton(
                                    onPressed: () => _upload(e.key),
                                    icon: const Icon(Icons.upload_file),
                                  ),
                                ),
                              CheckboxListTile(
                                value: _accepted,
                                title: const Text(
                                  'I confirm these details are accurate.',
                                ),
                                onChanged: (value) =>
                                    setState(() => _accepted = value ?? false),
                              ),
                              FilledButton(
                                onPressed: _busy ? null : _submit,
                                child: const Text('Submit for Admin Review'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (_busy) const LinearProgressIndicator(),
            ],
          ),
  );
}
