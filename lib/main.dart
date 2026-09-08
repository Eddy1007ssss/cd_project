import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase.dart';
import 'repositories/auth_repository.dart';
import 'l10n/tourflow_localization.dart';
import 'screens/staff/attraction_configuration_page.dart';
import 'screens/staff/attraction_details_page.dart';
import 'screens/staff/operator_dashboard_page.dart';
import 'screens/staff/operator_registration_page.dart';
import 'screens/staff/slot_manager_page.dart';
import 'screens/staff/staff_support_ticket_details_page.dart';
import 'screens/staff/support_ticket_management_page.dart';
import 'screens/staff/operator_feedback_page.dart';

import 'screens/user/attraction_details_page.dart' as user;
import 'screens/user/attraction_discovery_page.dart';
import 'screens/user/attraction_comparison_page.dart';
import 'screens/user/booking_confirmation_page.dart';
import 'screens/user/booking_history_page.dart';
import 'screens/user/booking_review_page.dart';
import 'screens/user/chat_history_page.dart';
import 'screens/user/chat_support_page.dart';
import 'screens/user/itinerary_planner_page.dart';
import 'screens/user/language_settings_page.dart';
import 'screens/user/my_feedback_page.dart';
import 'screens/user/nearby_attractions_page.dart';
import 'screens/user/discovery_preferences_page.dart';
import 'screens/user/profile_security_page.dart';
import 'screens/user/password_recovery_page.dart';
import 'screens/user/reschedule_booking_page.dart';
import 'screens/user/sign_in_page.dart';
import 'screens/user/smart_recommendations_page.dart';
import 'screens/user/support_ticket_details_page.dart';
import 'screens/user/support_ticket_form_page.dart';
import 'screens/user/support_ticket_list_page.dart';
import 'screens/user/time_slot_selection_page.dart';
import 'screens/user/tourist_registration_page.dart';
import 'screens/user/user_home_page.dart';
import 'screens/user/booking_qr_page.dart';
import 'screens/user/booking_details_page.dart';
import 'screens/user/feedback_centre_page.dart';
import 'screens/user/submit_feedback_page.dart';
import 'screens/user/capacity_alert_page.dart';
import 'screens/user/geofence_page.dart';
import 'screens/staff/staff_qr_scanner_page.dart';
import 'screens/staff/operator_live_crowd_page.dart';
import 'screens/staff/operator_live_crowd_details_page.dart';
import 'screens/staff/revenue_promotion_page.dart';
import 'screens/staff/promotion_suggestion_page.dart';
import 'screens/staff/visitor_statistics_page.dart';
import 'widgets/navigation/admin_navigation_shell.dart';
import 'widgets/navigation/navigation_routes.dart';
import 'widgets/navigation/operator_navigation_shell.dart';
import 'widgets/navigation/user_navigation_shell.dart';
import 'widgets/tourflow_widgets.dart';
import 'screens/staff/admin_generate_report_page.dart';
import 'screens/staff/admin_performance_report_page.dart';
import 'screens/staff/admin_sustainability_report_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  await TourFlowLocaleController.instance.loadForCurrentUser();
  runApp(const MyApp(listenForPasswordRecovery: true));
}

class MyApp extends StatelessWidget {
  const MyApp({this.listenForPasswordRecovery = false, super.key});

  final bool listenForPasswordRecovery;

  @override
  Widget build(BuildContext context) {
    return TourFlowLanguageScope(
      controller: TourFlowLocaleController.instance,
      child: _TourFlowMaterialApp(
        listenForPasswordRecovery: listenForPasswordRecovery,
      ),
    );
  }
}

class _TourFlowMaterialApp extends StatefulWidget {
  const _TourFlowMaterialApp({required this.listenForPasswordRecovery});

  final bool listenForPasswordRecovery;

  @override
  State<_TourFlowMaterialApp> createState() => _TourFlowMaterialAppState();
}

class _TourFlowMaterialAppState extends State<_TourFlowMaterialApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    if (!widget.listenForPasswordRecovery) return;
    _authSubscription = AuthRepository().authStateChanges.listen((state) {
      if (state.event != AuthChangeEvent.passwordRecovery) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
          PasswordRecoveryPage.routeName,
          (route) => false,
        );
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localeController = TourFlowLanguageScope.of(context);
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'TourFlow',
      locale: localeController.locale,
      supportedLocales: TourFlowLocaleController.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFD08B)),
        scaffoldBackgroundColor: const Color(0xFFFAF8FF),
      ),
      initialRoute: SignInPage.routeName,
      routes: {
        SignInPage.routeName: (_) => const SignInPage(),
        PasswordRecoveryPage.routeName: (_) => const PasswordRecoveryPage(),
        TouristRegistrationPage.routeName: (_) =>
            const TouristRegistrationPage(),
        UserHomePage.routeName: (_) => const UserNavigationShell(),
        AttractionDiscoveryPage.routeName: (_) =>
            const UserNavigationShell(initialIndex: 1),
        AttractionComparisonPage.routeName: (_) =>
            const AttractionComparisonPage(),
        user.AttractionDetailsPage.routeName: (_) =>
            const user.AttractionDetailsPage(),
        SmartRecommendationsPage.routeName: (_) =>
            const SmartRecommendationsPage(),
        NearbyAttractionsPage.routeName: (_) => const NearbyAttractionsPage(),
        DiscoveryPreferencesPage.routeName: (_) =>
            const DiscoveryPreferencesPage(),
        TimeSlotSelectionPage.routeName: (_) => const TimeSlotSelectionPage(),
        BookingReviewPage.routeName: (_) => const BookingReviewPage(),
        BookingConfirmationPage.routeName: (_) =>
            const BookingConfirmationPage(),
        BookingHistoryPage.routeName: (_) =>
            const UserNavigationShell(initialIndex: 2),
        CapacityAlertPage.routeName: (_) => const CapacityAlertPage(),
        RescheduleBookingPage.routeName: (_) => const RescheduleBookingPage(),
        ItineraryPlannerPage.routeName: (_) => const ItineraryPlannerPage(),
        ProfileSecurityPage.routeName: (_) =>
            const UserNavigationShell(initialIndex: 4),
        TourFlowRoutes.staffProfile: (_) => const ProfileSecurityPage(
          navigationRole: TourFlowNavigationRole.staff,
          pageLevel: TourFlowPageLevel.secondary,
          selectedNavigationIndex: 1,
        ),
        FeedbackCentrePage.routeName: (_) => const FeedbackCentrePage(),
        SubmitFeedbackPage.routeName: (_) => const SubmitFeedbackPage(),
        MyFeedbackPage.routeName: (_) => const MyFeedbackPage(),
        '/report-issue': (_) => const SupportTicketFormPage(),
        '/report-status': (_) => const SupportTicketListPage(),
        GeofencePage.routeName: (_) => const GeofencePage(),
        OperatorRegistrationPage.routeName: (_) =>
            const OperatorRegistrationPage(),
        TourFlowRoutes.adminDashboard: (context) =>
            const AdminNavigationShell(initialIndex: 1),
        TourFlowRoutes.adminSupportTickets: (context) =>
            const AdminNavigationShell(initialIndex: 3),
        TourFlowRoutes.staffSupportTickets: (_) =>
            const SupportTicketManagementPage(
              navigationRole: TourFlowNavigationRole.operator,
            ),
        TourFlowRoutes.operatorSupportTickets: (_) =>
            const OperatorNavigationShell(initialIndex: 3),
        OperatorDashboardPage.routeName: (_) => const OperatorNavigationShell(),
        AttractionDetailsPage.routeName: (_) =>
            const OperatorNavigationShell(initialIndex: 1),
        AttractionConfigurationPage.routeName: (_) =>
            const AttractionConfigurationPage(),
        TourFlowRoutes.adminAttractionReview: (context) =>
            const AdminNavigationShell(initialIndex: 2),
        SlotManagerPage.routeName: (_) =>
            const OperatorNavigationShell(initialIndex: 2),
        BookingDetailsPage.routeName: (_) => const BookingDetailsPage(),
        BookingQrPage.routeName: (_) => const BookingQrPage(),
        ChatSupportPage.routeName: (context) {
          final argument = ModalRoute.of(context)?.settings.arguments;
          return UserNavigationShell(
            initialIndex: 3,
            chatConversationId: argument is String ? argument : null,
          );
        },
        ChatHistoryPage.routeName: (_) => const ChatHistoryPage(),
        LanguageSettingsPage.routeName: (_) => const LanguageSettingsPage(),
        SupportTicketFormPage.routeName: (_) => const SupportTicketFormPage(),
        SupportTicketListPage.routeName: (_) => const SupportTicketListPage(),
        SupportTicketDetailsPage.routeName: (_) =>
            const SupportTicketDetailsPage(),
        StaffSupportTicketDetailsPage.routeName: (_) =>
            const StaffSupportTicketDetailsPage(),
        OperatorFeedbackPage.routeName: (_) => const OperatorFeedbackPage(),
        StaffQrScannerPage.routeName: (_) => const StaffQrScannerPage(),
        OperatorLiveCrowdPage.routeName: (_) => const OperatorLiveCrowdPage(),
        OperatorLiveCrowdDetailsPage.routeName: (_) =>
            const OperatorLiveCrowdDetailsPage(),
        TourFlowRoutes.operatorReports: (_) =>
            const OperatorNavigationShell(initialIndex: 3),
        RevenuePromotionPage.routeName: (_) => const RevenuePromotionPage(),
        PromotionSuggestionPage.routeName: (_) =>
            const PromotionSuggestionPage(),
        VisitorStatisticsPage.routeName: (_) =>
            const OperatorNavigationShell(initialIndex: 4),
        TourFlowRoutes.adminAnalyticsDashboard: (context) =>
            const AdminNavigationShell(initialIndex: 0),
        AdminGenerateReportPage.routeName: (context) =>
            const AdminGenerateReportPage(),
        AdminPerformanceReportPage.routeName: (context) =>
            const AdminPerformanceReportPage(),
        AdminSustainabilityReportPage.routeName: (context) =>
            const AdminSustainabilityReportPage(),
      },
    );
  }
}
