import 'package:flutter/material.dart';

import '../../repositories/auth_repository.dart';
import '../../widgets/navigation/navigation_routes.dart';
import '../../widgets/tourflow_widgets.dart';

class PasswordRecoveryPage extends StatefulWidget {
  const PasswordRecoveryPage({super.key});

  static const routeName = TourFlowRoutes.passwordRecovery;

  @override
  State<PasswordRecoveryPage> createState() => _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends State<PasswordRecoveryPage> {
  final _repository = AuthRepository();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _saving = false;
  bool _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_password.text != _confirmation.text) {
      _show('The passwords do not match.');
      return;
    }
    setState(() => _saving = true);
    try {
      await _repository.completePasswordRecovery(_password.text);
      await _repository.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        TourFlowRoutes.signIn,
        (route) => false,
      );
      _show('Password updated. Sign in with your new password.');
    } catch (error) {
      if (mounted) _show(_message(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: TourFlowText(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const TourFlowText('Create a new password')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionTitle(
            'Secure your account',
            subtitle: 'Use at least 8 characters for your new password.',
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _password,
            obscureText: _obscure,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'New password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _confirmation,
            obscureText: _obscure,
            onSubmitted: (_) => _save(),
            decoration: const InputDecoration(
              labelText: 'Confirm new password',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const TourFlowText('Update password'),
          ),
        ],
      ),
    ),
  );
}

String _message(Object error) =>
    error.toString().replaceFirst('Exception: ', '').trim();
