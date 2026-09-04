import 'package:flutter/material.dart';

import 'config/supabase.dart';
import 'screens/staff/admin_attraction_review_page.dart';
import 'screens/staff/admin_user_management_page.dart';
import 'screens/staff/attraction_configuration_page.dart';
import 'screens/staff/attraction_details_page.dart';
import 'screens/staff/operator_dashboard_page.dart';
import 'screens/staff/operator_registration_page.dart';
import 'screens/staff/resolve_report_page.dart';
import 'screens/staff/slot_manager_page.dart';
import 'screens/staff/staff_support_ticket_details_page.dart';
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
import 'screens/user/report_issue_page.dart';
import 'screens/user/report_status_page.dart';
import 'screens/user/capacity_alert_page.dart';
import 'screens/user/geofence_page.dart';
import 'screens/staff/staff_qr_scanner_page.dart';
import 'screens/staff/live_crowd_page.dart';
import 'screens/staff/operator_report_queue_page.dart';
import 'screens/staff/revenue_promotion_page.dart';
import 'screens/staff/promotion_suggestion_page.dart';
import 'screens/staff/visitor_statistics_page.dart';
import 'widgets/navigation/admin_navigation_shell.dart';
import 'widgets/navigation/navigation_routes.dart';
import 'widgets/navigation/operator_navigation_shell.dart';
import 'widgets/navigation/user_navigation_shell.dart';
import 'widgets/tourflow_widgets.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFD08B)),
        scaffoldBackgroundColor: const Color(0xFFFAF8FF),
      ),
      initialRoute: SignInPage.routeName,
      routes: {
        SignInPage.routeName: (_) => const SignInPage(),
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
        ReportIssuePage.routeName: (_) => const ReportIssuePage(),
        ReportStatusPage.routeName: (_) => const ReportStatusPage(),
        GeofencePage.routeName: (_) => const GeofencePage(),
        OperatorRegistrationPage.routeName: (_) =>
            const OperatorRegistrationPage(),
        AdminUserManagementPage.routeName: (_) => const AdminNavigationShell(),
        TourFlowRoutes.adminSupportTickets: (_) =>
            const AdminNavigationShell(initialIndex: 2),
        OperatorDashboardPage.routeName: (_) => const OperatorNavigationShell(),
        AttractionDetailsPage.routeName: (_) =>
            const OperatorNavigationShell(initialIndex: 1),
        AttractionConfigurationPage.routeName: (_) =>
            const AttractionConfigurationPage(),
        AdminAttractionReviewPage.routeName: (_) =>
            const AdminNavigationShell(initialIndex: 1),
        SlotManagerPage.routeName: (_) =>
            const OperatorNavigationShell(initialIndex: 2),
        BookingDetailsPage.routeName: (_) => const BookingDetailsPage(),
        BookingQrPage.routeName: (_) => const BookingQrPage(),
        ChatSupportPage.routeName: (_) =>
            const UserNavigationShell(initialIndex: 3),
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
        LiveCrowdPage.routeName: (_) => const LiveCrowdPage(),
        OperatorReportQueuePage.routeName: (_) =>
            const OperatorNavigationShell(initialIndex: 3),
        ResolveReportPage.routeName: (_) => const ResolveReportPage(),
        RevenuePromotionPage.routeName: (_) => const RevenuePromotionPage(),
        PromotionSuggestionPage.routeName: (_) =>
            const PromotionSuggestionPage(),
        VisitorStatisticsPage.routeName: (_) =>
            const OperatorNavigationShell(initialIndex: 4),
      },
    );
  }
}
