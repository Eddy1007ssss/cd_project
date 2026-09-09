import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _saving = false;
  bool _obscure = true;
  bool _loadedArguments = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedArguments) return;
    _loadedArguments = true;
    final email = ModalRoute.of(context)?.settings.arguments;
    if (email is String) _email.text = email;
  }

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    _email.dispose();
    _code.dispose();
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
      await _repository.verifyPasswordResetCode(
        email: _email.text,
        code: _code.text,
      );
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
    appBar: AppBar(title: const TourFlowText('Reset password')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionTitle(
            'Enter your email code',
            subtitle: 'We sent a six-digit code to your email address. Then choose a new password.',
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email address',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Six-digit verification code',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 4),
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
                : const TourFlowText('Verify code and update password'),
          ),
        ],
      ),
    ),
  );
}

String _message(Object error) =>
    error.toString().replaceFirst('Exception: ', '').trim();
