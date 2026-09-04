import 'package:cd_project/screens/user/user_home_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/user_profile.dart';
import '../../repositories/auth_repository.dart';
import '../../widgets/tourflow_widgets.dart';
import '../../widgets/navigation/navigation_routes.dart';
import '../staff/admin_user_management_page.dart';
import '../staff/operator_dashboard_page.dart';
import '../staff/operator_registration_page.dart';
import '../staff/staff_qr_scanner_page.dart';
import 'tourist_registration_page.dart';

enum _DemoRole { tourist, operator, staff, administrator }

String landingRouteForRole(UserRole role) => switch (role) {
  UserRole.tourist => UserHomePage.routeName,
  UserRole.operator => OperatorDashboardPage.routeName,
  UserRole.staff => StaffQrScannerPage.routeName,
  UserRole.administrator => AdminUserManagementPage.routeName,
};

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  static const routeName = TourFlowRoutes.signIn;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  _DemoRole _role = _DemoRole.tourist;
  bool _showPassword = false;
  bool _isSubmitting = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  AuthRepository get _authRepository => AuthRepository();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showMessage('Enter your email address and password.');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final profile = await _authRepository.signIn(
        email: email,
        password: password,
      );
      if (!profile.isActive) {
        await _authRepository.signOut();
        throw const AuthException('This account has been deactivated.');
      }
      if (profile.role.name != _role.name) {
        await _authRepository.signOut();
        throw AuthException(
          'This account is registered as ${profile.role.name}, not ${_role.name}.',
        );
      }
      if (!mounted) return;
      final routeName = landingRouteForRole(profile.role);
      Navigator.pushNamedAndRemoveUntil(context, routeName, (route) => false);
    } on AuthException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('Unable to sign in. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Enter your email address first.');
      return;
    }
    try {
      await _authRepository.sendPasswordReset(email);
      if (mounted) _showMessage('Password reset link sent to $email.');
    } on AuthException catch (error) {
      if (mounted) _showMessage(error.message);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TourFlowColors.background,
      appBar: AppBar(
        backgroundColor: TourFlowColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: const Color(0x140F172A),
        automaticallyImplyLeading: false,
        title: const Text(
          'TourFlow',
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
              const SizedBox(height: 8),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: TourFlowColors.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.travel_explore_rounded,
                  size: 34,
                  color: TourFlowColors.primaryText,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Welcome to TourFlow',
                style: TextStyle(
                  color: TourFlowColors.heading,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Access your personalised dashboard and manage\nyour travel experience efficiently.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: TourFlowColors.muted,
                  height: 1.45,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              ModuleCard(
                color: TourFlowColors.lavender,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: TourFlowColors.primaryText,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Context-Aware Interface',
                            style: TextStyle(
                              color: TourFlowColors.heading,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Available menus and navigation depend on your selected role and clearance level.',
                            style: TextStyle(
                              color: TourFlowColors.body.withValues(alpha: 0.8),
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ModuleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Type',
                      style: TextStyle(
                        color: TourFlowColors.body,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<_DemoRole>(
                        segments: const [
                          ButtonSegment(
                            value: _DemoRole.tourist,
                            icon: Icon(Icons.person_outline),
                            label: Text('Tourist'),
                          ),
                          ButtonSegment(
                            value: _DemoRole.operator,
                            icon: Icon(Icons.business_outlined),
                            label: Text('Operator'),
                          ),
                          ButtonSegment(
                            value: _DemoRole.staff,
                            icon: Icon(Icons.badge_outlined),
                            label: Text('Staff'),
                          ),
                          ButtonSegment(
                            value: _DemoRole.administrator,
                            icon: Icon(Icons.admin_panel_settings_outlined),
                            label: Text('Admin'),
                          ),
                        ],
                        selected: {_role},
                        showSelectedIcon: false,
                        onSelectionChanged: (value) {
                          setState(() => _role = value.first);
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'name@example.com',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) {
                        if (!_isSubmitting) _signIn();
                      },
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 19,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _sendPasswordReset,
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    PrimaryButton(
                      label: _isSubmitting ? 'Signing In...' : 'Sign In',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _isSubmitting ? () {} : _signIn,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'NEW TO TOURFLOW?',
                style: TextStyle(
                  color: TourFlowColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              if (_role == _DemoRole.tourist || _role == _DemoRole.operator)
                SizedBox(
                  width: double.infinity,
                  child: OutlineActionButton(
                    label: _role == _DemoRole.operator
                        ? 'Register as Attraction Operator'
                        : 'Create Tourist Account',
                    icon: Icons.person_add_alt_1_rounded,
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        _role == _DemoRole.operator
                            ? OperatorRegistrationPage.routeName
                            : TouristRegistrationPage.routeName,
                      );
                    },
                  ),
                )
              else
                const ModuleCard(
                  color: TourFlowColors.lavender,
                  child: Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings_outlined,
                        color: TourFlowColors.primaryText,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Staff and administrator accounts are provisioned by an administrator.',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
