import 'package:cd_project/models/engagement_models.dart';
import 'package:cd_project/repositories/engagement_repository.dart';
import 'package:cd_project/screens/staff/staff_qr_scanner_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('manual code shows a valid booking and confirms check-in', (
    tester,
  ) async {
    final gateway = _FakeStaffCheckInGateway(
      verification: _verification(StaffBookingStatus.valid),
      confirmation: _verification(
        StaffBookingStatus.checkedIn,
        currentVisitorCount: 14,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: StaffQrScannerPage(gateway: gateway)),
    );
    await tester.enterText(
      find.byKey(const Key('manual-booking-code')),
      'TF-ABC',
    );
    await tester.ensureVisible(find.byKey(const Key('verify-booking')));
    await tester.tap(find.byKey(const Key('verify-booking')));
    await tester.pumpAndSettle();

    expect(gateway.verifiedValue, 'TF-ABC');
    expect(find.byKey(const Key('verification-valid')), findsOneWidget);
    expect(find.byKey(const Key('confirm-check-in')), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm-check-in')));
    await tester.pumpAndSettle();

    expect(gateway.confirmedBookingId, 'booking-1');
    expect(find.text('Check-In Successful'), findsOneWidget);
    expect(find.text('Current visitor count: 14'), findsOneWidget);
  });

  testWidgets('invalid booking has no confirm action', (tester) async {
    final gateway = _FakeStaffCheckInGateway(
      verification: const StaffBookingVerification(
        status: StaffBookingStatus.invalid,
      ),
      confirmation: _verification(StaffBookingStatus.checkedIn),
    );

    await tester.pumpWidget(
      MaterialApp(home: StaffQrScannerPage(gateway: gateway)),
    );
    await tester.enterText(
      find.byKey(const Key('manual-booking-code')),
      'UNKNOWN',
    );
    await tester.ensureVisible(find.byKey(const Key('verify-booking')));
    await tester.tap(find.byKey(const Key('verify-booking')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('verification-invalid')), findsOneWidget);
    expect(find.byKey(const Key('confirm-check-in')), findsNothing);
  });

  for (final status in const [
    StaffBookingStatus.alreadyUsed,
    StaffBookingStatus.wrongAttraction,
    StaffBookingStatus.wrongSlot,
  ]) {
    testWidgets('${status.name} result cannot be confirmed', (tester) async {
      final gateway = _FakeStaffCheckInGateway(
        verification: _verification(status),
        confirmation: _verification(StaffBookingStatus.checkedIn),
      );

      await tester.pumpWidget(
        MaterialApp(home: StaffQrScannerPage(gateway: gateway)),
      );
      await tester.enterText(
        find.byKey(const Key('manual-booking-code')),
        'TF-ABC',
      );
      await tester.ensureVisible(find.byKey(const Key('verify-booking')));
      await tester.tap(find.byKey(const Key('verify-booking')));
      await tester.pumpAndSettle();

      expect(find.byKey(Key('verification-${status.name}')), findsOneWidget);
      expect(find.byKey(const Key('confirm-check-in')), findsNothing);
    });
  }
}

StaffBookingVerification _verification(
  StaffBookingStatus status, {
  int? currentVisitorCount,
}) => StaffBookingVerification(
  status: status,
  bookingId: 'booking-1',
  bookingCode: 'TF-ABC',
  visitorName: 'Alyssa Loh',
  visitorCount: 2,
  attractionName: 'National Museum',
  startsAt: DateTime(2026, 9, 4, 16),
  endsAt: DateTime(2026, 9, 4, 17),
  currentVisitorCount: currentVisitorCount,
);

class _FakeStaffCheckInGateway implements StaffCheckInGateway {
  _FakeStaffCheckInGateway({
    required this.verification,
    required this.confirmation,
  });

  final StaffBookingVerification verification;
  final StaffBookingVerification confirmation;
  String? verifiedValue;
  String? confirmedBookingId;

  @override
  Future<StaffBookingVerification> verifyStaffBooking(String value) async {
    verifiedValue = value;
    return verification;
  }

  @override
  Future<StaffBookingVerification> confirmStaffCheckIn(String bookingId) async {
    confirmedBookingId = bookingId;
    return confirmation;
  }
}
