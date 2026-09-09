# Modules 2–6 completion changes

Base: `eddy_latest` at `8ca4439df03a39165702bbcb60270938e7b30d4d`.
Branch: `feature/complete-modules-2-to-6`.

The branch is committed locally only. GitHub returned HTTP 403 (resource not accessible by integration), so it was not published. The accompanying `TourFlow-modules-2-to-6.patch` contains only changed/new files.

With your work committed or stashed, put that patch in the project root and run:

```powershell
git switch eddy_latest
git switch -c feature/complete-modules-2-to-6
git apply --check TourFlow-modules-2-to-6.patch
git apply TourFlow-modules-2-to-6.patch
```

If `--check` reports conflicts, stop and reconcile against the base commit above; do not force the patch. Run the SQL and verification steps below before committing and pushing the branch from your own GitHub account.

Public reviews have not been added. Module 1's existing management flows remain in place.

## What changed

| Area | Delivered |
| --- | --- |
| All sidebars | Shared signed-in name, email and avatar; responds to profile updates, logout and account switches. A late response for a previous account cannot replace the current profile. |
| Module 2 | Existing attraction rating numbers use an authenticated aggregate RPC. Direct feedback RLS previously meant a tourist could calculate an average from only their own feedback. The RPC returns scores/counts only, with no review text or reviewer identities. Existing discovery/recommendation screens are retained. |
| Module 3 | Load, update and delete saved itineraries; create/update parent and items in one database transaction; validate ownership, current bookings and closures on save; calculate driving routes for confirmed appointment order, including 15-minute buffers. Routing failures retain clearly labelled approximate estimates. Existing cross-attraction rescheduling is retained. |
| Module 4 | Realtime subscriptions invalidate operator crowd queries after check-in/out and slot changes. Five-second polling remains a fallback. Existing visitor RLS remains in force. |
| Module 5 | New/rescheduled bookings capture the attraction's current price. Analytics use that captured price, with an explicit estimate for older records. Totals are labelled estimated booking value, not payments received. Existing sustainability RLS was confirmed enabled on the linked project; no duplicate repair is needed. |
| Module 6 | Repository Edge Function synchronized to the deployed version 17 workflow; missing support schema/RPCs captured in the SQL; complaints without bookings are accepted for approved attractions, with ownership checks for supplied bookings; description limits and enum conversion aligned. Ticket routing controls access to tickets, events and attachment downloads. Archived copies of Module 5 reports remain excluded. Short multilingual ticket labels satisfy database limits. |

## Apply database changes first

The SQL has **not** been applied to the linked database.

Run the complete contents of `supabase/changes/complete_modules_2_to_6.sql` in the Supabase SQL Editor. It depends on the existing repository migrations through `202609080003_management_integration.sql`, which are already present in the linked project. Do not rerun those old migrations. The new script is transactional and designed to be rerunnable.

If using Supabase CLI migration history instead, first run:

```powershell
supabase migration new complete_modules_2_to_6
```

Copy the contents of the changes SQL into the newly generated migration file. Apply it through your team's usual migration process. Choose one approach; record an SQL Editor application in your team's migration history before using `db push` later. The CLI was unavailable in the implementation environment, so no fabricated timestamped migration was created.

Older ticket rows are preserved. Updated text/category checks use `NOT VALID`, enforcing the new rules on new or updated rows without rewriting historic archived content. Older booking prices are not backfilled because the actual historic price is unknown.

## Edge Function

`supabase/functions/gemini-chat/index.ts` now matches the deployed version 17 source read from the linked project. That project does not need this identical source redeployed merely to use the SQL fixes. For a different Supabase project, deploy the file with the team's existing Gemini configuration after applying the database changes. Keep Gemini secrets in Edge Function environment variables.

## Driving routes

The Android app uses the OSRM public demonstration routing endpoint by default. Only attraction coordinates are sent, with no user identity or device GPS. Results do not include live traffic. Confirmed booking order is preserved; this is road-path calculation, not moving confirmed appointments to different slots.

For a production deployment, supply a compatible routing server:

```powershell
flutter run --dart-define=TOURFLOW_ROUTING_URL=https://your-routing-server.example
```

Existing Supabase configuration flags must also be supplied as usual. Missing coordinates, network errors and unavailable routes leave approximate timeline estimates visible. Saved plans are advisory; the booking RPCs remain authoritative for actual reservations.

## Verification

Completed here: diff whitespace checks and TypeScript syntax parsing of the synchronized Edge Function. Flutter, Dart, Deno and PostgreSQL execution tools were unavailable; Flutter tests, Dart analysis, database execution and device checks have **not** been run. The code should not be treated as deployment-verified until the following checks pass.

```powershell
flutter pub get
flutter analyze
flutter test
```

Focused regression coverage was added for sidebar session isolation, recorded/free/historic booking prices, malformed routes, driving-time conversion and buffers, itinerary conflict recalculation/item order, and short multilingual support labels.

| Check | Expected result |
| --- | --- |
| Sign in as Tourist A, edit profile, then log out and sign in as B; open drawers on several pages | Current name/email/avatar appear; A's identity never appears for B. Repeat for operator/admin/staff. |
| Module 2 with two tourists' feedback for an approved attraction | Both see the same aggregate score. Neither gains access to the other's review text or identity. Signed-out demo remains available. |
| Two future bookings on the same day; calculate route and save | Road distances/times replace approximate legs; each leg includes one 15-minute buffer; plan appears in saved list. |
| Reopen, rename, change selection, save; then delete | Existing plan updates without duplication. Deleting the plan leaves bookings intact. |
| Cancel a selected booking or add an overlapping maintenance closure from another session before saving | Save rejects stale/unavailable visits; an existing itinerary remains intact after a failed update. |
| Disable routing connectivity or remove attraction coordinates | No crash or fabricated road result; estimated times remain labelled. |
| Book slot A, then reschedule to another attraction/slot B | B gains capacity, A releases it, QR details follow B, price snapshot changes to B's current price. |
| Check in/out on a staff device with an operator crowd page open | Counts refresh from row changes without reopening the page; polling still works after a websocket interruption. |
| Repeat a QR scan, use a wrong slot, deny camera/GPS, enter/leave geofence | Invalid/duplicate actions do not change counts. Permission denial offers a usable recovery path. Requires device testing. |
| Change attraction price after a completed booking; open operator/admin analytics and PDF | The recorded booking value remains stable. Older null-price bookings are identified as estimates. These figures are not payment revenue. |
| Query sustainability metrics as an unrelated operator or tourist | Other organizations' metrics remain inaccessible. |
| Submit a chatbot complaint without booking, then with an owned booking | Both valid paths succeed. Supplying another user's booking or conversation fails. Complaint appears in Module 5 reports, not Module 6 tickets. |
| Submit an account/technical support ticket with no attraction | Admin can handle it. An operator cannot read it, its events or attachment downloads. |
| Admin transfers an attraction ticket to its operator, then back to admin | Only the intended handler and owner can access it at each stage. Unrelated operator/tourist and deactivated accounts cannot. |
| Chat in English, Malay and Chinese; reopen history and escalate | Language persists; answers agree with actual attraction/slot data; ticket confirmation/status/history work. Requires live Gemini testing. |

Do not mark Modules 2, 4 or 6 as fully verified based on source integration alone. Their remaining live-device, data and role checks are explicit above.
