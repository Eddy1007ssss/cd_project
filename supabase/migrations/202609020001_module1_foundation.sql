-- TourFlow Module 1 foundation.
-- Apply through the Supabase SQL editor or an authenticated Supabase CLI.

create extension if not exists pgcrypto;

create type public.app_role as enum (
  'tourist',
  'operator',
  'staff',
  'administrator'
);

create type public.account_status as enum ('active', 'deactivated');
create type public.application_status as enum ('pending', 'approved', 'rejected');
create type public.listing_status as enum (
  'draft',
  'pending',
  'approved',
  'rejected',
  'suspended'
);
create type public.attraction_type as enum ('indoor', 'outdoor');
create type public.slot_status as enum ('open', 'full', 'closed', 'expired');
create type public.closure_type as enum ('maintenance', 'closure', 'private_event');
create type public.organization_member_role as enum ('operator', 'staff');

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null check (char_length(trim(full_name)) between 2 and 120),
  phone text,
  preferred_language text not null default 'en'
    check (preferred_language in ('en', 'ms', 'zh')),
  role public.app_role not null default 'tourist',
  status public.account_status not null default 'active',
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.operator_applications (
  id uuid primary key default gen_random_uuid(),
  applicant_id uuid not null references public.profiles (id) on delete cascade,
  representative_name text not null,
  job_title text not null,
  contact_email text not null,
  contact_phone text not null,
  business_name text not null,
  registration_number text not null,
  business_email text not null,
  business_phone text not null,
  business_address text not null,
  registration_certificate_path text not null,
  identity_document_path text not null,
  operating_licence_path text not null,
  status public.application_status not null default 'pending',
  review_note text,
  reviewed_by uuid references public.profiles (id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index operator_applications_one_pending_per_user
  on public.operator_applications (applicant_id)
  where status = 'pending';

create table public.operator_organizations (
  id uuid primary key default gen_random_uuid(),
  source_application_id uuid unique references public.operator_applications (id),
  name text not null,
  registration_number text not null unique,
  email text not null,
  phone text not null,
  address text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.organization_members (
  organization_id uuid not null
    references public.operator_organizations (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  member_role public.organization_member_role not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  primary key (organization_id, user_id)
);

create table public.attractions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null
    references public.operator_organizations (id) on delete cascade,
  created_by uuid not null references public.profiles (id),
  name text not null check (char_length(trim(name)) between 2 and 160),
  description text not null,
  category text not null,
  location_name text not null,
  address text not null,
  latitude double precision,
  longitude double precision,
  entrance_price_myr numeric(10, 2) not null default 0
    check (entrance_price_myr >= 0),
  facilities text[] not null default '{}',
  visitor_guidelines text,
  attraction_rules text,
  attraction_type public.attraction_type not null,
  maximum_capacity integer not null check (maximum_capacity > 0),
  geofence_radius_metres integer,
  listing_status public.listing_status not null default 'draft',
  review_note text,
  reviewed_by uuid references public.profiles (id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint valid_coordinates check (
    (latitude is null and longitude is null)
    or (latitude between -90 and 90 and longitude between -180 and 180)
  ),
  constraint outdoor_geofence_required check (
    attraction_type = 'indoor'
    or (geofence_radius_metres is not null and geofence_radius_metres > 0)
  )
);

create index attractions_organization_id_idx
  on public.attractions (organization_id);
create index attractions_public_search_idx
  on public.attractions (listing_status, category, location_name);

create table public.attraction_images (
  id uuid primary key default gen_random_uuid(),
  attraction_id uuid not null references public.attractions (id) on delete cascade,
  storage_path text not null,
  caption text,
  display_order integer not null default 0 check (display_order >= 0),
  created_at timestamptz not null default now(),
  unique (attraction_id, storage_path)
);

create table public.operating_hours (
  id uuid primary key default gen_random_uuid(),
  attraction_id uuid not null references public.attractions (id) on delete cascade,
  day_of_week smallint not null check (day_of_week between 0 and 6),
  is_closed boolean not null default false,
  opens_at time,
  closes_at time,
  note text,
  constraint valid_opening_period check (
    (is_closed and opens_at is null and closes_at is null)
    or (not is_closed and opens_at is not null and closes_at is not null
      and opens_at < closes_at)
  ),
  unique (attraction_id, day_of_week)
);

create table public.attraction_slots (
  id uuid primary key default gen_random_uuid(),
  attraction_id uuid not null references public.attractions (id) on delete cascade,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  maximum_capacity integer not null check (maximum_capacity > 0),
  reserved_capacity integer not null default 0 check (reserved_capacity >= 0),
  status public.slot_status not null default 'open',
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint valid_slot_period check (starts_at < ends_at),
  constraint reserved_capacity_within_limit check (
    reserved_capacity <= maximum_capacity
  ),
  unique (attraction_id, starts_at, ends_at)
);

create index attraction_slots_lookup_idx
  on public.attraction_slots (attraction_id, starts_at, status);

create table public.closure_periods (
  id uuid primary key default gen_random_uuid(),
  attraction_id uuid not null references public.attractions (id) on delete cascade,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  closure_type public.closure_type not null,
  reason text not null,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default now(),
  constraint valid_closure_period check (starts_at < ends_at)
);

create index closure_periods_lookup_idx
  on public.closure_periods (attraction_id, starts_at, ends_at);

create function public.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create trigger operator_applications_set_updated_at
before update on public.operator_applications
for each row execute function public.set_updated_at();

create trigger operator_organizations_set_updated_at
before update on public.operator_organizations
for each row execute function public.set_updated_at();

create trigger attractions_set_updated_at
before update on public.attractions
for each row execute function public.set_updated_at();

create trigger attraction_slots_set_updated_at
before update on public.attraction_slots
for each row execute function public.set_updated_at();

create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, phone, preferred_language)
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''), 'TourFlow User'),
    nullif(trim(new.raw_user_meta_data ->> 'phone'), ''),
    case
      when new.raw_user_meta_data ->> 'preferred_language' in ('en', 'ms', 'zh')
        then new.raw_user_meta_data ->> 'preferred_language'
      else 'en'
    end
  );
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create function public.current_user_role()
returns public.app_role
language sql
stable
security definer
set search_path = ''
as $$
  select p.role
  from public.profiles p
  where p.id = (select auth.uid())
    and p.status = 'active';
$$;

create function public.is_administrator()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(public.current_user_role() = 'administrator', false);
$$;

create function public.is_organization_member(target_organization_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.organization_members member
    join public.profiles profile on profile.id = member.user_id
    where member.organization_id = target_organization_id
      and member.user_id = (select auth.uid())
      and member.is_active
      and profile.status = 'active'
  );
$$;

revoke execute on function public.current_user_role() from public, anon;
revoke execute on function public.is_administrator() from public, anon;
revoke execute on function public.is_organization_member(uuid) from public, anon;
grant execute on function public.current_user_role() to authenticated;
grant execute on function public.is_administrator() to authenticated;
grant execute on function public.is_organization_member(uuid) to authenticated;

create function public.review_operator_application(
  application_id uuid,
  decision public.application_status,
  note text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  application public.operator_applications;
  organization_id uuid;
begin
  if not public.is_administrator() then
    raise exception 'Administrator access required';
  end if;
  if decision not in ('approved', 'rejected') then
    raise exception 'Decision must be approved or rejected';
  end if;

  select * into application
  from public.operator_applications
  where id = application_id
  for update;

  if application.id is null then
    raise exception 'Operator application not found';
  end if;
  if application.status <> 'pending' then
    raise exception 'Operator application has already been reviewed';
  end if;

  update public.operator_applications
  set status = decision,
      review_note = note,
      reviewed_by = (select auth.uid()),
      reviewed_at = now()
  where id = application_id;

  if decision = 'approved' then
    insert into public.operator_organizations (
      source_application_id,
      name,
      registration_number,
      email,
      phone,
      address
    ) values (
      application.id,
      application.business_name,
      application.registration_number,
      application.business_email,
      application.business_phone,
      application.business_address
    ) returning id into organization_id;

    insert into public.organization_members (
      organization_id,
      user_id,
      member_role
    ) values (
      organization_id,
      application.applicant_id,
      'operator'
    );

    update public.profiles
    set role = 'operator'
    where id = application.applicant_id;
  end if;

  return organization_id;
end;
$$;

create function public.set_account_status(
  target_user_id uuid,
  new_status public.account_status
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_administrator() then
    raise exception 'Administrator access required';
  end if;
  if target_user_id = (select auth.uid()) then
    raise exception 'Administrators cannot deactivate their own account';
  end if;
  update public.profiles set status = new_status where id = target_user_id;
  if not found then raise exception 'User profile not found'; end if;
end;
$$;

create function public.review_attraction(
  target_attraction_id uuid,
  decision public.listing_status,
  note text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_administrator() then
    raise exception 'Administrator access required';
  end if;
  if decision not in ('approved', 'rejected', 'suspended') then
    raise exception 'Invalid attraction review decision';
  end if;
  update public.attractions
  set listing_status = decision,
      review_note = note,
      reviewed_by = (select auth.uid()),
      reviewed_at = now()
  where id = target_attraction_id;
  if not found then raise exception 'Attraction not found'; end if;
end;
$$;

revoke execute on function public.review_operator_application(uuid, public.application_status, text)
  from public, anon;
revoke execute on function public.set_account_status(uuid, public.account_status)
  from public, anon;
revoke execute on function public.review_attraction(uuid, public.listing_status, text)
  from public, anon;
grant execute on function public.review_operator_application(uuid, public.application_status, text)
  to authenticated;
grant execute on function public.set_account_status(uuid, public.account_status)
  to authenticated;
grant execute on function public.review_attraction(uuid, public.listing_status, text)
  to authenticated;

alter table public.profiles enable row level security;
alter table public.operator_applications enable row level security;
alter table public.operator_organizations enable row level security;
alter table public.organization_members enable row level security;
alter table public.attractions enable row level security;
alter table public.attraction_images enable row level security;
alter table public.operating_hours enable row level security;
alter table public.attraction_slots enable row level security;
alter table public.closure_periods enable row level security;

revoke all on all tables in schema public from anon, authenticated;
grant select on public.profiles to authenticated;
grant update (full_name, phone, preferred_language, avatar_url)
  on public.profiles to authenticated;

grant select on public.operator_applications to authenticated;
grant insert (
  applicant_id, representative_name, job_title, contact_email, contact_phone,
  business_name, registration_number, business_email, business_phone,
  business_address, registration_certificate_path, identity_document_path,
  operating_licence_path
) on public.operator_applications to authenticated;

grant select on public.operator_organizations to authenticated;
grant select on public.organization_members to authenticated;

grant select, insert, update, delete on public.attractions to authenticated;
grant select, insert, update, delete on public.attraction_images to authenticated;
grant select, insert, update, delete on public.operating_hours to authenticated;
grant select, insert, delete on public.attraction_slots to authenticated;
grant update (starts_at, ends_at, maximum_capacity, status)
  on public.attraction_slots to authenticated;
grant select, insert, update, delete on public.closure_periods to authenticated;

create policy profiles_select_self_or_admin
on public.profiles for select to authenticated
using ((select auth.uid()) = id or public.is_administrator());

create policy profiles_update_self
on public.profiles for update to authenticated
using ((select auth.uid()) = id and status = 'active')
with check ((select auth.uid()) = id and status = 'active');

create policy operator_applications_select_owner_or_admin
on public.operator_applications for select to authenticated
using (applicant_id = (select auth.uid()) or public.is_administrator());

create policy operator_applications_insert_owner
on public.operator_applications for insert to authenticated
with check (
  applicant_id = (select auth.uid())
  and status = 'pending'
  and public.current_user_role() = 'tourist'
);

create policy organizations_select_member_or_admin
on public.operator_organizations for select to authenticated
using (public.is_organization_member(id) or public.is_administrator());

create policy organization_members_select_member_or_admin
on public.organization_members for select to authenticated
using (
  user_id = (select auth.uid())
  or public.is_organization_member(organization_id)
  or public.is_administrator()
);

create policy attractions_select_available
on public.attractions for select to authenticated
using (
  listing_status = 'approved'
  or public.is_organization_member(organization_id)
  or public.is_administrator()
);

create policy attractions_insert_member
on public.attractions for insert to authenticated
with check (
  public.is_organization_member(organization_id)
  and created_by = (select auth.uid())
  and listing_status in ('draft', 'pending')
);

create policy attractions_update_member
on public.attractions for update to authenticated
using (
  public.is_organization_member(organization_id)
  and listing_status in ('draft', 'rejected')
)
with check (
  public.is_organization_member(organization_id)
  and listing_status in ('draft', 'pending')
);

create policy attractions_delete_draft_member
on public.attractions for delete to authenticated
using (
  public.is_organization_member(organization_id)
  and listing_status = 'draft'
);

create policy attractions_admin_all
on public.attractions for all to authenticated
using (public.is_administrator())
with check (public.is_administrator());

create policy attraction_images_select_visible
on public.attraction_images for select to authenticated
using (
  exists (
    select 1 from public.attractions attraction
    where attraction.id = attraction_id
      and (
        attraction.listing_status = 'approved'
        or public.is_organization_member(attraction.organization_id)
        or public.is_administrator()
      )
  )
);

create policy attraction_images_manage_member
on public.attraction_images for all to authenticated
using (
  exists (
    select 1 from public.attractions attraction
    where attraction.id = attraction_id
      and public.is_organization_member(attraction.organization_id)
  )
  or public.is_administrator()
)
with check (
  exists (
    select 1 from public.attractions attraction
    where attraction.id = attraction_id
      and public.is_organization_member(attraction.organization_id)
  )
  or public.is_administrator()
);

create policy operating_hours_select_visible
on public.operating_hours for select to authenticated
using (
  exists (
    select 1 from public.attractions attraction
    where attraction.id = attraction_id
      and (
        attraction.listing_status = 'approved'
        or public.is_organization_member(attraction.organization_id)
        or public.is_administrator()
      )
  )
);

create policy operating_hours_manage_member
on public.operating_hours for all to authenticated
using (
  exists (
    select 1 from public.attractions attraction
    where attraction.id = attraction_id
      and public.is_organization_member(attraction.organization_id)
  )
  or public.is_administrator()
)
with check (
  exists (
    select 1 from public.attractions attraction
    where attraction.id = attraction_id
      and public.is_organization_member(attraction.organization_id)
  )
  or public.is_administrator()
);

create policy attraction_slots_select_visible
on public.attraction_slots for select to authenticated
using (
  exists (
    select 1 from public.attractions attraction
    where attraction.id = attraction_id
      and (
        attraction.listing_status = 'approved'
        or public.is_organization_member(attraction.organization_id)
        or public.is_administrator()
      )
  )
);

create policy attraction_slots_insert_member
on public.attraction_slots for insert to authenticated
with check (
  (
    exists (
      select 1 from public.attractions attraction
      where attraction.id = attraction_id
        and public.is_organization_member(attraction.organization_id)
    )
    or public.is_administrator()
  )
  and reserved_capacity = 0
);

create policy attraction_slots_update_member
on public.attraction_slots for update to authenticated
using (
  exists (
    select 1 from public.attractions attraction
    where attraction.id = attraction_id
      and public.is_organization_member(attraction.organization_id)
  )
  or public.is_administrator()
)
with check (
  exists (
    select 1 from public.attractions attraction
    where attraction.id = attraction_id
      and public.is_organization_member(attraction.organization_id)
  )
  or public.is_administrator()
);

create policy attraction_slots_delete_empty_member
on public.attraction_slots for delete to authenticated
using (
  reserved_capacity = 0
  and (
    exists (
      select 1 from public.attractions attraction
      where attraction.id = attraction_id
        and public.is_organization_member(attraction.organization_id)
    )
    or public.is_administrator()
  )
);

create policy closure_periods_select_visible
on public.closure_periods for select to authenticated
using (
  exists (
    select 1 from public.attractions attraction
    where attraction.id = attraction_id
      and (
        attraction.listing_status = 'approved'
        or public.is_organization_member(attraction.organization_id)
        or public.is_administrator()
      )
  )
);

create policy closure_periods_manage_member
on public.closure_periods for all to authenticated
using (
  exists (
    select 1 from public.attractions attraction
    where attraction.id = attraction_id
      and public.is_organization_member(attraction.organization_id)
  )
  or public.is_administrator()
)
with check (
  exists (
    select 1 from public.attractions attraction
    where attraction.id = attraction_id
      and public.is_organization_member(attraction.organization_id)
  )
  or public.is_administrator()
);

insert into storage.buckets (id, name, public)
values
  ('operator-documents', 'operator-documents', false),
  ('attraction-images', 'attraction-images', true),
  ('profile-avatars', 'profile-avatars', true)
on conflict (id) do nothing;

create policy operator_documents_insert_own_folder
on storage.objects for insert to authenticated
with check (
  bucket_id = 'operator-documents'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy operator_documents_select_owner_or_admin
on storage.objects for select to authenticated
using (
  bucket_id = 'operator-documents'
  and (
    owner_id = (select auth.uid()::text)
    or public.is_administrator()
  )
);

create policy attraction_images_upload_members
on storage.objects for insert to authenticated
with check (
  bucket_id = 'attraction-images'
  and public.is_organization_member(((storage.foldername(name))[1])::uuid)
);

create policy attraction_images_manage_members
on storage.objects for update to authenticated
using (
  bucket_id = 'attraction-images'
  and public.is_organization_member(((storage.foldername(name))[1])::uuid)
)
with check (
  bucket_id = 'attraction-images'
  and public.is_organization_member(((storage.foldername(name))[1])::uuid)
);

create policy attraction_images_delete_members
on storage.objects for delete to authenticated
using (
  bucket_id = 'attraction-images'
  and public.is_organization_member(((storage.foldername(name))[1])::uuid)
);

create policy profile_avatars_insert_own_folder
on storage.objects for insert to authenticated
with check (
  bucket_id = 'profile-avatars'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy profile_avatars_manage_own
on storage.objects for update to authenticated
using (bucket_id = 'profile-avatars' and owner_id = (select auth.uid()::text))
with check (bucket_id = 'profile-avatars' and owner_id = (select auth.uid()::text));

create policy profile_avatars_delete_own
on storage.objects for delete to authenticated
using (bucket_id = 'profile-avatars' and owner_id = (select auth.uid()::text));
