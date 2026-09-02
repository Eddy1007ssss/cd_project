# Module 2 Supabase setup

This branch depends on the shared Module 1 and Module 3 schema and demo seed.
It intentionally does not duplicate attractions, slots, closures, bookings, or
itineraries.

In the Supabase SQL Editor:

1. Apply the shared Module 1 and Module 3 migrations and `seed.sql` from the
   `module1&3` branch if they are not already present.
2. Apply `migrations/202609030001_module2_discovery.sql` once.
3. Apply `module2_seed.sql` to add demo preferences and interest tags.

The Flutter application uses the public URL and publishable client key in
`lib/config/supabase.dart`, so it starts with `flutter run`. Never put a
service-role key or database password in the application.
