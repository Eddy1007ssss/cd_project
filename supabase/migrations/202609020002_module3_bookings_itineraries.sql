-- TourFlow Module 3: transactional bookings and itineraries.

alter table public.attractions add column if not exists cover_image_url text;

create type public.booking_status as enum ('confirmed', 'cancelled', 'completed');
create type public.itinerary_status as enum ('conflict_free', 'conflict_detected');

create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  tourist_id uuid not null references public.profiles (id) on delete cascade,
  slot_id uuid not null references public.attraction_slots (id),
  visitor_count integer not null check (visitor_count between 1 and 6),
  booking_code text not null unique,
  qr_token uuid not null default gen_random_uuid() unique,
  status public.booking_status not null default 'confirmed',
  cancelled_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index bookings_tourist_status_idx
  on public.bookings (tourist_id, status, created_at desc);
create index bookings_slot_status_idx
  on public.bookings (slot_id, status);

create table public.itineraries (
  id uuid primary key default gen_random_uuid(),
  tourist_id uuid not null references public.profiles (id) on delete cascade,
  title text not null check (char_length(trim(title)) between 2 and 120),
  itinerary_date date not null,
  status public.itinerary_status not null default 'conflict_free',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.itinerary_items (
  id uuid primary key default gen_random_uuid(),
  itinerary_id uuid not null references public.itineraries (id) on delete cascade,
  booking_id uuid not null references public.bookings (id) on delete cascade,
  position integer not null check (position >= 0),
  travel_minutes_from_previous integer check (travel_minutes_from_previous >= 0),
  distance_km_from_previous numeric(8, 2)
    check (distance_km_from_previous >= 0),
  safety_buffer_minutes integer not null default 15
    check (safety_buffer_minutes between 0 and 120),
  created_at timestamptz not null default now(),
  unique (itinerary_id, booking_id),
  unique (itinerary_id, position)
);

create trigger bookings_set_updated_at
before update on public.bookings
for each row execute function public.set_updated_at();

create trigger itineraries_set_updated_at
before update on public.itineraries
for each row execute function public.set_updated_at();

create function public.distance_km(
  first_latitude double precision,
  first_longitude double precision,
  second_latitude double precision,
  second_longitude double precision
)
returns double precision
language sql
immutable
security invoker
set search_path = ''
as $$
  select case
    when first_latitude is null or first_longitude is null
      or second_latitude is null or second_longitude is null then null
    else 6371 * 2 * asin(
      sqrt(
        power(sin(radians(second_latitude - first_latitude) / 2), 2)
        + cos(radians(first_latitude)) * cos(radians(second_latitude))
        * power(sin(radians(second_longitude - first_longitude) / 2), 2)
      )
    )
  end;
$$;

create function public.estimated_travel_minutes(
  first_attraction_id uuid,
  second_attraction_id uuid
)
returns integer
language sql
stable
security invoker
set search_path = ''
as $$
  select coalesce(
    ceil(
      public.distance_km(
        first_attraction.latitude,
        first_attraction.longitude,
        second_attraction.latitude,
        second_attraction.longitude
      )
      / 30.0 * 60.0
    )::integer,
    30
  ) + 15
  from public.attractions first_attraction
  cross join public.attractions second_attraction
  where first_attraction.id = first_attraction_id
    and second_attraction.id = second_attraction_id;
$$;

create function public.create_booking(
  target_slot_id uuid,
  requested_visitors integer
)
returns public.bookings
language plpgsql
security definer
set search_path = ''
as $$
declare
  selected_slot public.attraction_slots;
  selected_attraction public.attractions;
  conflicting_booking public.bookings;
  adjacent_record record;
  next_record record;
  created_booking public.bookings;
  generated_code text;
begin
  if (select auth.uid()) is null then raise exception 'Authentication required'; end if;
  if public.current_user_role() <> 'tourist' then raise exception 'Tourist access required'; end if;
  if requested_visitors not between 1 and 6 then raise exception 'Visitor count must be between 1 and 6'; end if;

  -- Serialize booking decisions for one tourist even when two requests target
  -- different slot rows. The slot lock below separately protects capacity.
  perform pg_advisory_xact_lock(hashtextextended((select auth.uid())::text, 0));

  select * into selected_slot
  from public.attraction_slots where id = target_slot_id for update;
  if selected_slot.id is null then raise exception 'SLOT_NOT_FOUND'; end if;

  select * into selected_attraction
  from public.attractions where id = selected_slot.attraction_id;
  if selected_attraction.listing_status <> 'approved' then raise exception 'ATTRACTION_UNAVAILABLE'; end if;
  if selected_slot.status <> 'open' or selected_slot.starts_at <= now() then raise exception 'SLOT_UNAVAILABLE'; end if;
  if selected_slot.reserved_capacity + requested_visitors > selected_slot.maximum_capacity then raise exception 'INSUFFICIENT_CAPACITY'; end if;

  if exists (
    select 1 from public.closure_periods closure
    where closure.attraction_id = selected_slot.attraction_id
      and tstzrange(closure.starts_at, closure.ends_at, '[)')
        && tstzrange(selected_slot.starts_at, selected_slot.ends_at, '[)')
  ) then raise exception 'ATTRACTION_CLOSED'; end if;

  select booking.* into conflicting_booking
  from public.bookings booking
  join public.attraction_slots booked_slot on booked_slot.id = booking.slot_id
  where booking.tourist_id = (select auth.uid())
    and booking.status = 'confirmed'
    and tstzrange(booked_slot.starts_at, booked_slot.ends_at, '[)')
      && tstzrange(selected_slot.starts_at, selected_slot.ends_at, '[)')
  limit 1;
  if conflicting_booking.id is not null then raise exception 'BOOKING_OVERLAP'; end if;

  select booked_slot.ends_at, attraction.id as attraction_id
  into adjacent_record
  from public.bookings booking
  join public.attraction_slots booked_slot on booked_slot.id = booking.slot_id
  join public.attractions attraction on attraction.id = booked_slot.attraction_id
  where booking.tourist_id = (select auth.uid())
    and booking.status = 'confirmed'
    and booked_slot.ends_at <= selected_slot.starts_at
  order by booked_slot.ends_at desc limit 1;
  if adjacent_record.ends_at is not null
    and extract(epoch from (selected_slot.starts_at - adjacent_record.ends_at)) / 60
      < public.estimated_travel_minutes(adjacent_record.attraction_id, selected_attraction.id)
  then raise exception 'INSUFFICIENT_TRAVEL_TIME'; end if;

  select booked_slot.starts_at, attraction.id as attraction_id
  into next_record
  from public.bookings booking
  join public.attraction_slots booked_slot on booked_slot.id = booking.slot_id
  join public.attractions attraction on attraction.id = booked_slot.attraction_id
  where booking.tourist_id = (select auth.uid())
    and booking.status = 'confirmed'
    and booked_slot.starts_at >= selected_slot.ends_at
  order by booked_slot.starts_at limit 1;
  if next_record.starts_at is not null
    and extract(epoch from (next_record.starts_at - selected_slot.ends_at)) / 60
      < public.estimated_travel_minutes(selected_attraction.id, next_record.attraction_id)
  then raise exception 'INSUFFICIENT_TRAVEL_TIME'; end if;

  loop
    generated_code := 'TF-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10));
    exit when not exists (select 1 from public.bookings where booking_code = generated_code);
  end loop;

  insert into public.bookings (tourist_id, slot_id, visitor_count, booking_code)
  values ((select auth.uid()), target_slot_id, requested_visitors, generated_code)
  returning * into created_booking;

  update public.attraction_slots
  set reserved_capacity = reserved_capacity + requested_visitors,
      status = case
        when reserved_capacity + requested_visitors = maximum_capacity then 'full'
        else status
      end
  where id = target_slot_id;

  return created_booking;
end;
$$;

create function public.cancel_booking(target_booking_id uuid)
returns public.bookings
language plpgsql
security definer
set search_path = ''
as $$
declare
  selected_booking public.bookings;
begin
  select * into selected_booking
  from public.bookings where id = target_booking_id for update;
  if selected_booking.id is null then raise exception 'BOOKING_NOT_FOUND'; end if;
  if selected_booking.tourist_id <> (select auth.uid()) and not public.is_administrator() then
    raise exception 'BOOKING_ACCESS_DENIED';
  end if;
  if selected_booking.status <> 'confirmed' then raise exception 'BOOKING_NOT_ACTIVE'; end if;

  update public.bookings
  set status = 'cancelled', cancelled_at = now()
  where id = target_booking_id returning * into selected_booking;

  update public.attraction_slots
  set reserved_capacity = greatest(0, reserved_capacity - selected_booking.visitor_count),
      status = case
        when starts_at <= now() then 'expired'
        when status = 'full' then 'open'
        else status
      end
  where id = selected_booking.slot_id;
  return selected_booking;
end;
$$;

create function public.reschedule_booking(
  target_booking_id uuid,
  new_slot_id uuid
)
returns public.bookings
language plpgsql
security definer
set search_path = ''
as $$
declare
  selected_booking public.bookings;
  old_slot public.attraction_slots;
  new_slot public.attraction_slots;
  new_attraction public.attractions;
  previous_record record;
  next_record record;
begin
  select * into selected_booking
  from public.bookings where id = target_booking_id for update;
  if selected_booking.id is null or selected_booking.tourist_id <> (select auth.uid()) then
    raise exception 'BOOKING_ACCESS_DENIED';
  end if;
  if selected_booking.status <> 'confirmed' then raise exception 'BOOKING_NOT_ACTIVE'; end if;
  if selected_booking.slot_id = new_slot_id then raise exception 'SAME_SLOT'; end if;

  perform 1 from public.attraction_slots
  where id in (selected_booking.slot_id, new_slot_id) order by id for update;
  select * into old_slot from public.attraction_slots where id = selected_booking.slot_id;
  select * into new_slot from public.attraction_slots where id = new_slot_id;
  if new_slot.id is null then raise exception 'SLOT_NOT_FOUND'; end if;
  select * into new_attraction from public.attractions where id = new_slot.attraction_id;
  if new_attraction.listing_status <> 'approved' or new_slot.status <> 'open'
    or new_slot.starts_at <= now() then raise exception 'SLOT_UNAVAILABLE'; end if;
  if new_slot.reserved_capacity + selected_booking.visitor_count > new_slot.maximum_capacity then
    raise exception 'INSUFFICIENT_CAPACITY';
  end if;
  if exists (
    select 1 from public.closure_periods closure
    where closure.attraction_id = new_slot.attraction_id
      and tstzrange(closure.starts_at, closure.ends_at, '[)')
        && tstzrange(new_slot.starts_at, new_slot.ends_at, '[)')
  ) then raise exception 'ATTRACTION_CLOSED'; end if;
  if exists (
    select 1 from public.bookings booking
    join public.attraction_slots booked_slot on booked_slot.id = booking.slot_id
    where booking.tourist_id = selected_booking.tourist_id
      and booking.id <> selected_booking.id
      and booking.status = 'confirmed'
      and tstzrange(booked_slot.starts_at, booked_slot.ends_at, '[)')
        && tstzrange(new_slot.starts_at, new_slot.ends_at, '[)')
  ) then raise exception 'BOOKING_OVERLAP'; end if;

  select booked_slot.ends_at, booked_slot.attraction_id
  into previous_record
  from public.bookings booking
  join public.attraction_slots booked_slot on booked_slot.id = booking.slot_id
  where booking.tourist_id = selected_booking.tourist_id
    and booking.id <> selected_booking.id
    and booking.status = 'confirmed'
    and booked_slot.ends_at <= new_slot.starts_at
  order by booked_slot.ends_at desc
  limit 1;
  if previous_record.ends_at is not null
    and extract(epoch from (new_slot.starts_at - previous_record.ends_at)) / 60
      < public.estimated_travel_minutes(previous_record.attraction_id, new_attraction.id)
  then raise exception 'INSUFFICIENT_TRAVEL_TIME'; end if;

  select booked_slot.starts_at, booked_slot.attraction_id
  into next_record
  from public.bookings booking
  join public.attraction_slots booked_slot on booked_slot.id = booking.slot_id
  where booking.tourist_id = selected_booking.tourist_id
    and booking.id <> selected_booking.id
    and booking.status = 'confirmed'
    and booked_slot.starts_at >= new_slot.ends_at
  order by booked_slot.starts_at
  limit 1;
  if next_record.starts_at is not null
    and extract(epoch from (next_record.starts_at - new_slot.ends_at)) / 60
      < public.estimated_travel_minutes(new_attraction.id, next_record.attraction_id)
  then raise exception 'INSUFFICIENT_TRAVEL_TIME'; end if;

  update public.attraction_slots
  set reserved_capacity = greatest(0, reserved_capacity - selected_booking.visitor_count),
      status = case when status = 'full' then 'open' else status end
  where id = old_slot.id;
  update public.attraction_slots
  set reserved_capacity = reserved_capacity + selected_booking.visitor_count,
      status = case
        when reserved_capacity + selected_booking.visitor_count = maximum_capacity then 'full'
        else status
      end
  where id = new_slot.id;
  update public.bookings set slot_id = new_slot.id
  where id = selected_booking.id returning * into selected_booking;
  return selected_booking;
end;
$$;

revoke execute on function public.create_booking(uuid, integer) from public, anon;
revoke execute on function public.cancel_booking(uuid) from public, anon;
revoke execute on function public.reschedule_booking(uuid, uuid) from public, anon;
grant execute on function public.create_booking(uuid, integer) to authenticated;
grant execute on function public.cancel_booking(uuid) to authenticated;
grant execute on function public.reschedule_booking(uuid, uuid) to authenticated;

alter table public.bookings enable row level security;
alter table public.itineraries enable row level security;
alter table public.itinerary_items enable row level security;
revoke all on public.bookings, public.itineraries, public.itinerary_items
  from anon, authenticated;
grant select on public.bookings to authenticated;
grant select, insert, update, delete on public.itineraries to authenticated;
grant select, insert, update, delete on public.itinerary_items to authenticated;

create policy bookings_select_related
on public.bookings for select to authenticated
using (
  tourist_id = (select auth.uid())
  or public.is_administrator()
  or exists (
    select 1
    from public.attraction_slots slot
    join public.attractions attraction on attraction.id = slot.attraction_id
    where slot.id = slot_id
      and public.is_organization_member(attraction.organization_id)
  )
);

create policy itineraries_owner_all
on public.itineraries for all to authenticated
using (tourist_id = (select auth.uid()))
with check (tourist_id = (select auth.uid()));

create policy itinerary_items_owner_all
on public.itinerary_items for all to authenticated
using (
  exists (
    select 1 from public.itineraries itinerary
    where itinerary.id = itinerary_id
      and itinerary.tourist_id = (select auth.uid())
  )
)
with check (
  exists (
    select 1 from public.itineraries itinerary
    where itinerary.id = itinerary_id
      and itinerary.tourist_id = (select auth.uid())
  )
  and exists (
    select 1 from public.bookings booking
    where booking.id = booking_id
      and booking.tourist_id = (select auth.uid())
      and booking.status = 'confirmed'
  )
);
