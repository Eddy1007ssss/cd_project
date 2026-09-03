# TourFlow Supabase setup

The SQL migrations in `migrations/` are the source of truth for the shared
database schema. Do not create undocumented production tables only through the
dashboard.

## Apply the migrations

Until the Supabase CLI is installed and linked, open the project's SQL Editor,
run these files once and in order:

1. `migrations/202609020001_module1_foundation.sql`
2. `migrations/202609020002_module3_bookings_itineraries.sql`
3. `migrations/202609030001_module2_discovery.sql`
4. `migrations/202609030002_engagement_and_hardening.sql`

In Authentication settings, enable Email/Password and keep email confirmation
disabled for the current tutor-demo environment.

## Bootstrap the first administrator

After applying the migration, create the administrator through
Authentication > Users in the Supabase dashboard. Then run the following in
the SQL Editor, replacing the example email:

```sql
update public.profiles
set role = 'administrator'
where id = (
  select id from auth.users where email = 'admin@example.com'
);
```

Do not let clients choose `administrator`, `operator`, or `staff` during normal
signup. Tourist signup always creates a tourist profile; operator access is
granted by the administrator approval database function.

## Load tutor-demo data

In Authentication > Users, create these confirmed email/password users:

- `tourist@tourflow.test`
- `operator@tourflow.test`
- `staff@tourflow.test`
- `admin@tourflow.test`

Choose a shared temporary demo password in the dashboard. Do not write that
password into Git. Creating users through Authentication is necessary because
SQL-only placeholder users do not have a valid password login.

Then run `seed.sql` in the SQL Editor. It assigns the four roles and inserts an
operator organisation, three approved Malaysian attractions, operating hours,
open/full/closed/expired slots, a maintenance day, and upcoming/past/cancelled
bookings. The seed uses stable IDs and can be run again to refresh relative demo
dates.

## Run Flutter

```powershell
flutter run
```

The public project URL and publishable client key are configured in
`lib/config/supabase.dart`. Never place the database password or service-role
key in the Flutter application.

## Deploy chatbot support

Install and link the Supabase CLI, store `GEMINI_API_KEY` as a Supabase
project secret, and deploy the authenticated function:

```powershell
supabase secrets set GEMINI_API_KEY=your-key
supabase functions deploy gemini-chat
```

The Gemini key belongs only in Supabase Secrets. The function requires a valid
user JWT and deliberately does not return upstream provider response details.
