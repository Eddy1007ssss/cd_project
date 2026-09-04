import 'package:cd_project/models/engagement_models.dart';
import 'package:cd_project/models/user_profile.dart';
import 'package:cd_project/repositories/engagement_repository.dart';
import 'package:cd_project/screens/staff/admin_user_management_page.dart';
import 'package:cd_project/screens/staff/operator_dashboard_page.dart';
import 'package:cd_project/screens/staff/staff_qr_scanner_page.dart';
import 'package:cd_project/screens/user/sign_in_page.dart';
import 'package:cd_project/screens/user/user_home_page.dart';
import 'package:cd_project/screens/user/profile_security_page.dart';
import 'package:cd_project/widgets/navigation/admin_bottom_navigation_bar.dart';
import 'package:cd_project/widgets/navigation/admin_navigation_shell.dart';
import 'package:cd_project/widgets/navigation/staff_bottom_navigation_bar.dart';
import 'package:cd_project/widgets/navigation/user_bottom_navigation_bar.dart';
import 'package:cd_project/widgets/navigation/user_navigation_shell.dart';
import 'package:cd_project/widgets/tourflow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every authenticated role has a distinct landing route', () {
    expect(landingRouteForRole(UserRole.tourist), UserHomePage.routeName);
    expect(
      landingRouteForRole(UserRole.operator),
      OperatorDashboardPage.routeName,
    );
    expect(landingRouteForRole(UserRole.staff), StaffQrScannerPage.routeName);
    expect(
      landingRouteForRole(UserRole.administrator),
      AdminUserManagementPage.routeName,
    );
  });

  testWidgets('profile tab has exactly one tourist bottom bar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: UserNavigationShell(initialIndex: 4)),
    );

    expect(find.byType(UserBottomNavigationBar), findsOneWidget);
    expect(find.byType(OperatorBottomNavigationBar), findsNothing);
    expect(find.byType(AdminBottomNavigationBar), findsNothing);
  });

  testWidgets('administrator navigation stays in administrator pages', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AdminNavigationShell()));

    expect(find.byType(AdminBottomNavigationBar), findsOneWidget);
    expect(find.byType(OperatorBottomNavigationBar), findsNothing);

    await tester.tap(find.text('Reviews'));
    await tester.pumpAndSettle();

    expect(find.text('Attraction Review'), findsOneWidget);
    expect(find.byType(AdminBottomNavigationBar), findsOneWidget);
    expect(find.text('Operator Dashboard'), findsNothing);
  });

  testWidgets('staff scanner has no operator or duplicate bottom bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StaffQrScannerPage(gateway: _FakeStaffCheckInGateway()),
      ),
    );

    expect(find.byType(UserBottomNavigationBar), findsNothing);
    expect(find.byType(OperatorBottomNavigationBar), findsNothing);
    expect(find.byType(AdminBottomNavigationBar), findsNothing);

    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();
    expect(find.text('STAFF'), findsOneWidget);
    expect(find.text('Scan QR'), findsWidgets);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Support Tickets'), findsNothing);
    expect(find.text('Operator Dashboard'), findsNothing);
  });

  test('operator navigation excludes staff check-in', () {
    expect(operatorNavigationItems.map((item) => item.label), [
      'Dashboard',
      'Attractions',
      'Slots',
      'Reports',
      'Analytics',
    ]);
  });

  testWidgets('staff profile keeps staff navigation and has no bottom bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileSecurityPage(
          navigationRole: TourFlowNavigationRole.staff,
          pageLevel: TourFlowPageLevel.secondary,
          selectedNavigationIndex: 1,
        ),
      ),
    );

    expect(find.byType(UserBottomNavigationBar), findsNothing);
    expect(find.byType(OperatorBottomNavigationBar), findsNothing);
    expect(find.byType(AdminBottomNavigationBar), findsNothing);
    expect(find.byTooltip('Back'), findsOneWidget);

    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();
    expect(find.text('STAFF'), findsOneWidget);
    expect(find.text('Scan QR'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('back button follows top-level and secondary hierarchy', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TourFlowPage(
          title: 'Top level',
          role: 'TOURIST',
          pageLevel: TourFlowPageLevel.topLevel,
          child: Text('Content'),
        ),
      ),
    );
    expect(find.byTooltip('Back'), findsNothing);

    await tester.pumpWidget(
      const MaterialApp(
        home: TourFlowPage(
          title: 'Secondary',
          role: 'TOURIST',
          child: Text('Content'),
        ),
      ),
    );
    expect(find.byTooltip('Back'), findsOneWidget);
  });
}

class _FakeStaffCheckInGateway implements StaffCheckInGateway {
  @override
  Future<StaffBookingVerification> confirmStaffCheckIn(String bookingId) {
    throw UnimplementedError();
  }

  @override
  Future<StaffBookingVerification> verifyStaffBooking(String value) {
    throw UnimplementedError();
  }
}
