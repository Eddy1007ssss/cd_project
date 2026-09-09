# Multi-day itinerary update

Apply the patch, then run `supabase/changes/multiday_itineraries.sql` in Supabase SQL Editor before launching this version. Commit that SQL file with the Dart changes. It preserves demo records, extends saved plans with an end date, adds dates to public stops, and replaces the save function with an atomic multi-day implementation. No Edge Function deployment or new dependency is required.

## Scope

- One itinerary holds up to 20 confirmed upcoming bookings across multiple dates.
- Filter available visits by day without losing selections on other days.
- Select visible visits, remove a visit without cancelling it, and clear selections.
- Summary includes date range, planned days, visits, visit duration, travel duration and distance.
- Each day has its own map and chronological timeline. Booking times are fixed; this does not reorder appointments or reserve new bookings.
- Travel calculations retain a 15-minute buffer within each day. Overnight transfers, hotels and meals are not planned. Overlaps across midnight are still rejected.
- Conflict messages show the missing minutes; a visit menu opens booking details or the existing reschedule flow.
- Shared itineraries retain each stop's date. Booking identifiers and QR tokens remain private.
- Save/share/delete failures now show errors. Refresh removes cancelled or no-longer-upcoming visits from the draft.

## Manual checks

1. Select confirmed bookings on two dates; save, leave, reopen, and confirm both dates and all visits remain.
2. Calculate routes; verify each day's travel separately and no overnight journey is added.
3. Share the saved trip; open Community Itineraries with another tourist account and verify dates.
4. Remove a visit from the draft; check that its booking still exists in Trips.
5. Reschedule a selected visit, return, and confirm its changed date/time is refreshed.
6. Try tight same-day timing; verify the missing minutes and disabled Save action.
7. Disable internet while calculating; approximate estimates should remain usable with a warning.

The new `test/multiday_itinerary_test.dart` covers chronology, overnight boundaries, same-day conflicts and public date parsing. Flutter/device tests and SQL execution are left to the project owner. Existing saved plans containing past visits still use the original upcoming-only editor; they are not a historical trip journal. Shared copies remain snapshots: save changes, then choose Update shared copy.
