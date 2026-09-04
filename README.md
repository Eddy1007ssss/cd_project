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

## Current functional areas

- Tourist, operator, and administrator navigation use role-specific persistent
  tab shells; staff currently has a dedicated Support Tickets landing page.
- Tourist authentication and registration use Supabase Auth.
- Attraction discovery, filters, nearby results, preferences, and
  recommendations use shared attraction services.
- Booking, cancellation, rescheduling, and itinerary operations use database
  functions that enforce atomic capacity changes where required.
- Feedback, issue reports, geofence check-in, crowd data, and operator report
  resolution use the shared engagement repository.
- Some administration, attraction configuration, QR verification, profile,
  and support-ticket screens remain UI demonstrations for their assigned
  modules to complete.

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
