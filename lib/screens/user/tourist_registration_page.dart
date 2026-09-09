import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../repositories/auth_repository.dart';
import '../../widgets/tourflow_widgets.dart';
import 'sign_in_page.dart';

class TouristRegistrationPage extends StatefulWidget {
  const TouristRegistrationPage({super.key});

  static const routeName = '/tourist-registration';

  @override
  State<TouristRegistrationPage> createState() =>
      _TouristRegistrationPageState();
}

class _TouristRegistrationPageState extends State<TouristRegistrationPage> {
  bool _acceptedTerms = true;
  bool _isSubmitting = false;
  bool _showPassword = false;
  String _preferredLanguage = 'en';
  String _phoneCountryCode = '+60';
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  AuthRepository get _authRepository => AuthRepository();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_acceptedTerms) {
      _showMessage('Accept the Terms of Service to create an account.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await _authRepository.signUpTourist(
        email: _emailController.text,
        password: _passwordController.text,
        fullName: _fullNameController.text,
        phone: '$_phoneCountryCode ${_phoneController.text.trim()}',
        preferredLanguage: _preferredLanguage,
      );
      await _authRepository.signOut();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.check_circle_outline_rounded,
            color: TourFlowColors.success,
          ),
          title: const TourFlowText('Verify your email'),
          content: const TourFlowText(
            'We sent a verification link to your email address. Open it before signing in. Check your spam folder if it does not arrive.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  SignInPage.routeName,
                  (route) => false,
                );
              },
              child: const TourFlowText('Back to Sign In'),
            ),
          ],
        ),
      );
    } on AuthException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to create the account. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: TourFlowText(message)));
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TourFlowColors.background,
      appBar: AppBar(
        backgroundColor: TourFlowColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: const Color(0x140F172A),
        title: const TourFlowText(
          'Sign Up',
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
              ModuleCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(
                        'Create Account',
                        subtitle:
                            'Join thousands of travellers exploring the world with TourFlow.',
                      ),
                      const SizedBox(height: 22),
                      TextFormField(
                        controller: _fullNameController,
                        validator: _required,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: context.tr('Full Name'),
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailController,
                        validator: (value) {
                          final requiredMessage = _required(value);
                          if (requiredMessage != null) return requiredMessage;
                          return value!.contains('@')
                              ? null
                              : 'Enter a valid email address.';
                        },
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: context.tr('Email Address'),
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 132,
                            child: DropdownButtonFormField<String>(
                              initialValue: _phoneCountryCode,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: context.tr('Code'),
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: '+60',
                                  child: TourFlowText('MY +60'),
                                ),
                                DropdownMenuItem(
                                  value: '+65',
                                  child: TourFlowText('SG +65'),
                                ),
                                DropdownMenuItem(
                                  value: '+62',
                                  child: TourFlowText('ID +62'),
                                ),
                                DropdownMenuItem(
                                  value: '+66',
                                  child: TourFlowText('TH +66'),
                                ),
                                DropdownMenuItem(
                                  value: '+86',
                                  child: TourFlowText('CN +86'),
                                ),
                              ],
                              onChanged: (value) => setState(
                                () => _phoneCountryCode = value ?? '+60',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              validator: (value) {
                                final digits = value?.trim() ?? '';
                                if (digits.isEmpty) {
                                  return 'Required.';
                                }
                                if (digits.length < 7 || digits.length > 12) {
                                  return 'Enter a valid number.';
                                }
                                return null;
                              },
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText: context.tr('Phone Number'),
                                hintText: context.tr('123456789'),
                                prefixIcon: Icon(Icons.phone_outlined),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        validator: (value) => (value?.length ?? 0) < 8
                            ? 'Use at least 8 characters.'
                            : null,
                        obscureText: !_showPassword,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: context.tr('Password'),
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _showPassword = !_showPassword),
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _preferredLanguage,
                        decoration: InputDecoration(
                          labelText: context.tr('Preferred Language'),
                          prefixIcon: Icon(Icons.language_rounded),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'en', child: TourFlowText('English')),
                          DropdownMenuItem(
                            value: 'ms',
                            child: TourFlowText('Bahasa Melayu'),
                          ),
                          DropdownMenuItem(value: 'zh', child: TourFlowText('中文')),
                        ],
                        onChanged: (value) =>
                            setState(() => _preferredLanguage = value ?? 'en'),
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _acceptedTerms,
                        activeColor: TourFlowColors.primaryText,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (value) {
                          setState(() => _acceptedTerms = value ?? false);
                        },
                        title: const TourFlowText(
                          'I agree to the Terms of Service and Privacy Policy.',
                          style: TextStyle(
                            color: TourFlowColors.body,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      PrimaryButton(
                        label: _isSubmitting
                            ? 'Creating Account...'
                            : 'Create Account',
                        icon: Icons.person_add_alt_1_rounded,
                        onPressed: _isSubmitting ? () {} : _createAccount,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, SignInPage.routeName);
                },
                child: const TourFlowText('Already have an account? Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
