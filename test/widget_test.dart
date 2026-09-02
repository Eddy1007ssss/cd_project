import 'package:cd_project/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sign-in presents every supported role', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Tourist'), findsOneWidget);
    expect(find.text('Operator'), findsOneWidget);
    expect(find.text('Staff'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('sign-in requires credentials before role routing', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Admin'));
    await tester.pump();
    await tester.ensureVisible(find.text('Sign In'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your email address and password.'), findsOneWidget);
  });

  testWidgets('tourist registration defaults to Malaysia calling code', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.ensureVisible(find.text('Create Tourist Account'));
    await tester.tap(find.text('Create Tourist Account'));
    await tester.pumpAndSettle();

    expect(find.text('MY +60'), findsOneWidget);
    expect(find.text('Phone Number'), findsOneWidget);
  });
}
