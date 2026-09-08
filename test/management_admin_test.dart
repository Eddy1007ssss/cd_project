import 'package:cd_project/repositories/management_repository.dart';
import 'package:cd_project/screens/staff/management_admin_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeManagement implements ManagementRepository {
  String status = 'pending';
  bool fail = false;
  int reviews = 0;
  @override
  Future<List<ManagementRow>> attractions({
    bool administrator = false,
  }) async => [
    {'id': 'attraction-1', 'name': 'Test Attraction', 'listing_status': status},
  ];
  @override
  Future<List<ManagementRow>> hours(String id) async => [];
  @override
  Future<List<ManagementRow>> images(String id) async => [];
  @override
  Future<void> reviewAttraction(String id, String decision, String note) async {
    reviews++;
    if (fail) throw const FormatException('Review was rejected by the server.');
    status = decision;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('review is persisted only after confirmation and reloaded', (
    tester,
  ) async {
    final repository = _FakeManagement();
    await tester.pumpWidget(
      MaterialApp(
        home: ManagementAdminPage(
          attractionReview: true,
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test Attraction'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Approve'));
    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();
    expect(repository.reviews, 0);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(repository.reviews, 1);
    expect(repository.status, 'approved');
    expect(find.text('Review saved.'), findsNothing);
    expect(find.text('Saved successfully.'), findsOneWidget);
  });

  testWidgets('failed review does not show a false saved state', (
    tester,
  ) async {
    final repository = _FakeManagement()..fail = true;
    await tester.pumpWidget(
      MaterialApp(
        home: ManagementAdminPage(
          attractionReview: true,
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test Attraction'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Approve'));
    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(repository.status, 'pending');
    expect(find.text('Saved successfully.'), findsNothing);
    expect(find.text('Review was rejected by the server.'), findsOneWidget);
  });
}
