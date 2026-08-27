import 'package:cd_project/screens/user/user_home_page.dart';
import 'package:flutter/material.dart';

import 'config/supabase.dart';
import 'screens/staff/admin_attraction_review_page.dart';
import 'screens/staff/admin_user_management_page.dart';
import 'screens/staff/attraction_configuration_page.dart';
import 'screens/staff/attraction_details_page.dart';
import 'screens/staff/operator_dashboard_page.dart';
import 'screens/staff/operator_registration_page.dart';
import 'screens/staff/slot_manager_page.dart';
import 'screens/user/profile_security_page.dart';
import 'screens/user/sign_in_page.dart';
import 'screens/user/tourist_registration_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseConfig.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TourFlow',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFD08B),
        ),
        scaffoldBackgroundColor: const Color(0xFFFAF8FF),
      ),
      initialRoute: SignInPage.routeName,
      routes: {
        SignInPage.routeName: (_) => const SignInPage(),
        TouristRegistrationPage.routeName: (_) =>
            const TouristRegistrationPage(),
        ProfileSecurityPage.routeName: (_) => const ProfileSecurityPage(),
        UserHomePage.routeName: (_) => const UserHomePage(),
        OperatorRegistrationPage.routeName: (_) =>
            const OperatorRegistrationPage(),
        AdminUserManagementPage.routeName: (_) =>
            const AdminUserManagementPage(),
        OperatorDashboardPage.routeName: (_) =>
            const OperatorDashboardPage(),
        AttractionDetailsPage.routeName: (_) => const AttractionDetailsPage(),
        AttractionConfigurationPage.routeName: (_) =>
            const AttractionConfigurationPage(),
        AdminAttractionReviewPage.routeName: (_) =>
            const AdminAttractionReviewPage(),
        SlotManagerPage.routeName: (_) => const SlotManagerPage(),
      },
    );
  }
}
