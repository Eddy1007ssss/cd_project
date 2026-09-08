# Management integration handoff

Branch: `feature/complete-management-integration`

Base: `58e8d2a3485d29a74e45f52ccc8e64f2a5b31700` on main.

This implementation has passed Flutter analysis and the automated test suite,
but it is not yet a verified production release. The management SQL was first
applied through the Supabase SQL Editor and is now tracked as an idempotent
migration. Complete the manual role-based checks below before release.

## Files to copy

Copy these files to the same paths in your checkout. Preserve any teammate
changes made after the base commit; compare before overwriting.

New:

- `lib/repositories/management_repository.dart`
- `lib/screens/staff/management_ui.dart`
- `lib/screens/staff/management_admin_page.dart`
- `supabase/migrations/202609080003_management_integration.sql`
- `test/management_admin_test.dart`
- `docs/MANAGEMENT_HANDOFF.md`

Changed:

- `lib/screens/staff/admin_user_management_page.dart`
- `lib/screens/staff/admin_attraction_review_page.dart`
- `lib/screens/staff/operator_registration_page.dart`
- `lib/screens/staff/attraction_details_page.dart`
- `lib/screens/staff/attraction_configuration_page.dart`
- `lib/screens/staff/slot_manager_page.dart`
- `lib/screens/user/profile_security_page.dart`
- `lib/screens/user/reschedule_booking_page.dart`
- `lib/repositories/module3_repository.dart`
- `README.md`

No dependencies, app keys, existing migration files or Module 5/6 workflows were
changed. Affected demo forms have been replaced with functional forms while
keeping their route names and navigation roles. Operator dashboard analytics
were preserved.

## Database setup — do this before testing the new save buttons

The management SQL is tracked as migration
`202609080003_management_integration.sql`. It was initially deployed through the
Supabase SQL Editor, so it is intentionally idempotent and can run again when
the project migration history is reconciled. Do not replay unrelated historical
migrations on a live database.

The SQL:

- Restores RLS and managed-access policies on `sustainability_metrics`.
- Allows an operator to submit edits of an approved listing for re-review.
- Adds invoker-rights functions to save attraction + seven hours rows atomically,
  save slots while respecting reservations, and add maintenance periods.
- Restricts the new RPCs to authenticated callers and checks operator access.

It assumes the previous project schema and helper functions already exist.
It does not delete table data, cancel bookings or apply any live changes itself.

Read-only post-deployment checks:

```sql
select tablename, rowsecurity from pg_tables
where schemaname = 'public' and tablename = 'sustainability_metrics';

select policyname, cmd, qual, with_check from pg_policies
where schemaname = 'public' and tablename = 'sustainability_metrics';

select proname, prosecdef from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and proname in
('save_managed_attraction', 'save_managed_slot', 'add_managed_closure');
```

Expect RLS true, managed-access policies, and `prosecdef = false` for the three
new functions. Review any additional pre-existing permissive policies before
considering the table secured.

## Local verification

```powershell
flutter pub get
dart format lib/repositories/management_repository.dart lib/repositories/module3_repository.dart lib/screens/staff/management_ui.dart lib/screens/staff/management_admin_page.dart lib/screens/staff/admin_user_management_page.dart lib/screens/staff/admin_attraction_review_page.dart lib/screens/staff/operator_registration_page.dart lib/screens/staff/attraction_details_page.dart lib/screens/staff/attraction_configuration_page.dart lib/screens/staff/slot_manager_page.dart lib/screens/user/profile_security_page.dart lib/screens/user/reschedule_booking_page.dart test/management_admin_test.dart
flutter analyze
flutter test
flutter build apk --debug
```

The new widget tests cover confirmation, successful review persistence and
failure without false success. They do not replace database permission tests.

## Manual acceptance checks

Use separate tourist, operator, unrelated operator, staff and administrator
test accounts. Do not use real identity documents in testing.

1. Tourist: Profile → Operator Application. Upload three image scans, submit,
   reopen and confirm pending state survives a restart. Verify duplicate pending
   submission is rejected. Test upload/save failures without success messages.
2. Administrator: review those documents, reject with a note, then let the
   tourist resubmit. Approve the new request and sign in again as operator.
3. Administrator: deactivate/reactivate another test account; verify own-account
   deactivation is unavailable. Check deactivated account access separately;
   account status is not a substitute for revoking all existing auth tokens.
4. Operator: create a draft attraction with coordinates, guidelines and hours.
   Reopen it, add images, then submit. Administrator approves/rejects/suspends.
   Confirm approved edits return to pending, and another operator cannot edit it.
5. Operator: create an empty future slot, edit it and close it. With a tourist
   reservation present, editing or closing must fail without changing capacity.
6. Add a maintenance period, then attempt a new overlapping tourist booking;
   the booking backend must reject it. Existing bookings are not automatically
   cancelled by a maintenance restriction.
7. Tourist: reschedule to another approved attraction. Verify the attraction
   name, ticket/check-in method and time update; old capacity decreases and new
   capacity increases exactly once. Try full, conflicting and maintenance slots;
   rejected moves must leave the original booking/capacity intact.
8. Sustainability: verify admin and owning operator access, while tourist,
   staff, unrelated operator and unauthenticated access are denied.

## Explicit limitations

- Operator documents currently accept JPG/PNG/WebP image scans, not PDF uploads.
  Existing PDFs do not preview in the new image-only document viewer.
- Unsubmitted/replaced uploads may remain in Storage; no cleanup job was added.
- Gallery supports adding images to drafts/rejected listings; no delete/reorder UI.
- Slot closing is non-destructive and refuses reserved slots. Mass cancellation
  and visitor notifications are not implemented.
- Maintenance blocks new bookings; it does not automatically resolve existing
  bookings or provide a maintenance-edit/delete workflow.
- Approved edits temporarily remove a listing from discovery until re-approved.
- Rescheduling shows up to 1,000 upcoming open slots for the chosen attraction;
  the existing RPC is still the authority for capacity/closure/conflict checks.
- Itinerary road routes, true route optimisation, payment-backed revenue and
  changes to chatbot/report ownership were not part of this patch.
- Live policy drift beyond the reviewed sustainability policies needs its own
  audit. This is not a claim that the entire database is secure.

Complete the role-based database checks before treating this as a production
release.
