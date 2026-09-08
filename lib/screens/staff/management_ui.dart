import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../repositories/management_repository.dart';

String managementError(Object error) {
  if (error is FormatException) return error.message;
  if (error is AuthException) return error.message;
  if (error is PostgrestException) {
    if (error.code == '23505') {
      return 'This record already exists. Refresh before retrying.';
    }
    if (error.code == '42501') {
      return 'You do not have permission to save this record.';
    }
    if (error.code == 'P0001') return error.message;
  }
  return 'The operation could not be confirmed. Refresh to check the saved state before retrying.';
}

void managementMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Widget managementField(
  String label,
  TextEditingController controller, {
  bool required = true,
  int lines = 1,
  String? Function(String?)? validator,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: TextFormField(
    controller: controller,
    maxLines: lines,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    validator:
        validator ??
        (value) => required && (value ?? '').trim().isEmpty ? 'Required' : null,
  ),
);

Future<String?> managementDecision(
  BuildContext context,
  String title, {
  bool requireNote = false,
}) async {
  // Controller belongs to the dialog widget, which disposes after its exit animation.
  return showDialog<String>(
    context: context,
    builder: (_) => _DecisionDialog(title: title, requireNote: requireNote),
  );
}

class _DecisionDialog extends StatefulWidget {
  const _DecisionDialog({required this.title, required this.requireNote});
  final String title;
  final bool requireNote;
  @override
  State<_DecisionDialog> createState() => _DecisionDialogState();
}

class _DecisionDialogState extends State<_DecisionDialog> {
  final _note = TextEditingController();
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: Form(
      key: _form,
      child: managementField(
        'Decision note',
        _note,
        required: widget.requireNote,
        lines: 3,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, _note.text.trim());
          }
        },
        child: const Text('Confirm'),
      ),
    ],
  );
}

Future<String?> pickManagementImage(
  ManagementRepository repository, {
  required String bucket,
  required String folder,
}) async {
  final image = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (image == null) return null;
  final extension = image.name.split('.').last.toLowerCase();
  final mime = switch (extension) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => throw const FormatException('Choose a JPG, PNG or WebP image.'),
  };
  if (await image.length() > 10 * 1024 * 1024) {
    throw const FormatException('Choose an image smaller than 10 MB.');
  }
  return repository.uploadImage(
    bucket: bucket,
    folder: folder,
    bytes: await image.readAsBytes(),
    extension: extension,
    contentType: mime,
  );
}

class ManagementRows extends StatelessWidget {
  const ManagementRows({
    super.key,
    required this.future,
    required this.retry,
    required this.builder,
  });
  final Future<List<ManagementRow>> future;
  final VoidCallback retry;
  final Widget Function(List<ManagementRow>) builder;
  @override
  Widget build(BuildContext context) => FutureBuilder<List<ManagementRow>>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Column(
          children: [
            Text(managementError(snapshot.error!)),
            TextButton(onPressed: retry, child: const Text('Retry')),
          ],
        );
      }
      return builder(snapshot.data ?? []);
    },
  );
}
