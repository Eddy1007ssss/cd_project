import 'package:flutter/material.dart';

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(
                      'Create Account',
                      subtitle:
                      'Join thousands of travellers exploring the world with TourFlow.',
                    ),
                    const SizedBox(height: 22),
                    const StaticField(
                      label: 'Full Name',
                      value: 'John Doe',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 14),
                    const StaticField(
                      label: 'Email Address',
                      value: 'name@example.com',
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 14),
                    const StaticField(
                      label: 'Phone Number',
                      value: '+60 12-345 6789',
                      icon: Icons.phone_outlined,
                    ),
                    const SizedBox(height: 14),
                    const StaticField(
                      label: 'Password',
                      value: '••••••••••',
                      icon: Icons.lock_outline,
                    ),
                    const SizedBox(height: 14),
                    const StaticField(
                      label: 'Preferred Language',
                      value: 'English',
                      icon: Icons.language_rounded,
                      trailing: Icon(Icons.keyboard_arrow_down_rounded),
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
                      title: const Text(
                        'I agree to the Terms of Service and Privacy Policy.',
                        style: TextStyle(
                          color: TourFlowColors.body,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    PrimaryButton(
                      label: 'Create Account',
                      icon: Icons.person_add_alt_1_rounded,
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          SignInPage.routeName,
                              (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, SignInPage.routeName);
                },
                child: const Text('Already have an account? Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
