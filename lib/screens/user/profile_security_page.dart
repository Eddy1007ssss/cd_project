
import 'package:flutter/material.dart';

import '../../widgets/tourflow_widgets.dart';

class ProfileSecurityPage extends StatefulWidget {
  const ProfileSecurityPage({super.key});

  static const routeName = '/profile-security';

  @override
  State<ProfileSecurityPage> createState() => _ProfileSecurityPageState();
}

class _ProfileSecurityPageState extends State<ProfileSecurityPage> {
  bool _twoFactor = true;
  bool _loginAlerts = true;

  @override
  Widget build(BuildContext context) {
    return TourFlowPage(
      title: 'Profile and Security',
      role: 'TOURFLOW',
      selectedNavigationIndex: 4,
      child: Column(
        children: [
          ModuleCard(
            color: TourFlowColors.lavender,
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 34,
                  backgroundColor: TourFlowColors.primary,
                  child: Text(
                    'AT',
                    style: TextStyle(
                      color: TourFlowColors.primaryText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alex Thompson',
                        style: TextStyle(
                          color: TourFlowColors.heading,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'alex.thompson@tourflow.com',
                        style: TextStyle(
                          color: TourFlowColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.camera_alt_outlined),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const ModuleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle('Personal Details'),
                SizedBox(height: 18),
                StaticField(label: 'Full Name', value: 'Alex Thompson'),
                SizedBox(height: 14),
                StaticField(
                  label: 'Phone Number',
                  value: '+60 12-345 6789',
                  icon: Icons.phone_outlined,
                ),
                SizedBox(height: 14),
                StaticField(
                  label: 'Preferred Language',
                  value: 'English (Malaysia)',
                  icon: Icons.language_outlined,
                ),
                SizedBox(height: 14),
                StaticField(
                  label: 'Home Address',
                  value: 'Kuala Lumpur, Malaysia',
                  icon: Icons.home_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          ModuleCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.rate_review_outlined),
              title: const Text('Feedback Centre'),
              subtitle: const Text('Ratings, feedback and issue reports'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/feedback-centre',
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          ModuleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Security & Privacy'),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.key_rounded),
                  title: const Text('Change Password'),
                  subtitle: const Text('Update your account security key'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Reset Password Link'),
                  subtitle: const Text('Send a recovery link to your email'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _twoFactor,
                  title: const Text('Two-Factor Authentication'),
                  subtitle: const Text('Add extra protection to your account'),
                  onChanged: (value) => setState(() => _twoFactor = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _loginAlerts,
                  title: const Text('Login Alerts'),
                  subtitle: const Text('Receive alerts for new sign-ins'),
                  onChanged: (value) => setState(() => _loginAlerts = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Save Profile Changes',
              onPressed: () {
                Navigator.pushReplacementNamed(context, ProfileSecurityPage.routeName);
              }),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlineActionButton(
              label: 'Deactivate Account',
              color: TourFlowColors.danger,
              icon: Icons.block_rounded,
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}
