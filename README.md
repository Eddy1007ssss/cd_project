# TourFlow

TourFlow is a Flutter application for discovering Malaysian attractions,
managing visits, booking time slots, planning itineraries, monitoring crowds,
and communicating with attraction operators.

## Run the application

1. Install a Flutter SDK compatible with the Dart constraint in `pubspec.yaml`.
2. Run `flutter pub get`.
3. Start an emulator or connect a device.
4. Run `flutter run`.

The app uses the Supabase project configured in `lib/config/supabase.dart`. The
publishable client key may be bundled with the Flutter app; privileged service
keys and user passwords must never be committed.

## Supabase setup

The versioned SQL files under `supabase/migrations` are the database source of
truth. Apply them in filename order, then follow `supabase/README.md` to create
the four tutor-demo accounts and load the seed data. Never modify a migration
that has already been applied to the shared project; add a new migration for
subsequent schema changes.

Authenticated users read and write Supabase data according to their role and
row-level-security policies. Module 2 deliberately uses local demonstration
data when no user is signed in. AI chat additionally requires the
`gemini-chat` Edge Function and its `GEMINI_API_KEY` Supabase secret.

Password recovery uses the native redirect `tourflow://auth/recovery`. Add this
exact URI to **Authentication > URL Configuration > Redirect URLs** in the
Supabase dashboard. Configure a custom SMTP provider under Authentication email
settings for reliable Gmail delivery; no Gmail password or SMTP secret belongs
in this repository.

## Current functional areas

- Tourist, operator, and administrator navigation use role-specific persistent
  tab shells; staff lands on QR scanning with a separate profile route.
- Tourist authentication and registration use Supabase Auth.
- Attraction discovery, filters, nearby results, preferences, and
  recommendations use shared attraction services.
- Booking, cancellation, rescheduling, and itinerary operations use database
  functions that enforce atomic capacity changes where required.
- Feedback and Module 5 issue reports use the engagement workflow for
  attraction incidents and operator resolution. Module 6 support tickets use a
  separate helpdesk workflow for tourist questions and staff responses;
  imported report copies are retained only as hidden audit records.
- Module 1 management screens now call Supabase for operator applications,
  account/listing review, attraction editing, hours, slots and maintenance.
  Migration `202609080003_management_integration.sql` supplies the required
  attraction, slot and maintenance RPCs.
- Rescheduling supports another approved attraction. Itinerary travel remains
  a distance-based estimate, not road routing or an optimisation service.

## Development workflow

Create feature branches from the latest `main`; do not develop directly on
`main`. Keep shared route, model, repository, navigation, dependency, and
migration changes coordinated because they affect multiple modules.

Before opening a pull request, run:

```powershell
dart format <changed-dart-files>
flutter analyze
flutter test
flutter build apk --debug
```

Review the final Git diff and ensure it contains no generated noise,
credentials, passwords, or unrelated files.
