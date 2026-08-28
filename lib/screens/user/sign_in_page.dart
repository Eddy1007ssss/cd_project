import 'package:cd_project/screens/user/user_home_page.dart';
import 'package:flutter/material.dart';

import '../../widgets/tourflow_widgets.dart';
import '../staff/operator_dashboard_page.dart';
import '../staff/operator_registration_page.dart';
import 'profile_security_page.dart';
import 'tourist_registration_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  static const routeName = '/sign-in';

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool _operator = false;
  bool _showPassword = false;

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
                              color: TourFlowColors.body.withOpacity(0.8),
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
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: false,
                          icon: Icon(Icons.person_outline),
                          label: Text('Tourist'),
                        ),
                        ButtonSegment(
                          value: true,
                          icon: Icon(Icons.business_outlined),
                          label: Text('Operator'),
                        ),
                      ],
                      selected: {_operator},
                      onSelectionChanged: (value) {
                        setState(() => _operator = value.first);
                      },
                    ),
                    const SizedBox(height: 18),
                    const StaticField(
                      label: 'Email Address',
                      value: 'alex@example.com',
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 14),
                    StaticField(
                      label: 'Password',
                      value: _showPassword ? 'TourFlow123!' : '••••••••••',
                      icon: Icons.lock_outline_rounded,
                      trailing: IconButton(
                        onPressed: () {
                          setState(() => _showPassword = !_showPassword);
                        },
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 19,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    PrimaryButton(
                      label: 'Sign In',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          _operator
                              ? OperatorDashboardPage.routeName
                              : UserHomePage.routeName,
                        );
                      },
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
              SizedBox(
                width: double.infinity,
                child: OutlineActionButton(
                  label: _operator
                      ? 'Register as Attraction Operator'
                      : 'Create Tourist Account',
                  icon: Icons.person_add_alt_1_rounded,
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      _operator
                          ? OperatorRegistrationPage.routeName
                          : TouristRegistrationPage.routeName,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
