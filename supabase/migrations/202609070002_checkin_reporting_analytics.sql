-- Final check-in, reporting, crowd and sustainability contracts.

alter table public.attractions
  add column if not exists check_in_method text;

update public.attractions
set check_in_method = case
  when attraction_type = 'outdoor' then 'geofence'
  else 'staff_scan'
end
where check_in_method is null;

alter table public.attractions
  alter column check_in_method set default 'staff_scan',
  alter column check_in_method set not null;

alter table public.attractions
  drop constraint if exists attractions_check_in_method_valid;

alter table public.attractions
  add constraint attractions_check_in_method_valid
    check (check_in_method in ('geofence', 'staff_scan'));

update public.attractions
set geofence_radius_m = geofence_radius_metres
where geofence_radius_metres is not null
  and geofence_radius_metres between 25 and 2000;

alter table public.issue_reports
  add column if not exists evidence_path text;

create table public.sustainability_metrics (
  id uuid primary key default gen_random_uuid(),
  attraction_id uuid not null references public.attractions (id) on delete cascade,
  record_date date not null,
  carbon_offset_kg numeric(12, 2) not null default 0 check (carbon_offset_kg >= 0),
  water_saved_l numeric(12, 2) not null default 0 check (water_saved_l >= 0),
  energy_saved_kwh numeric(12, 2) not null default 0 check (energy_saved_kwh >= 0),
  recycling_rate numeric(5, 2) not null default 0 check (recycling_rate between 0 and 100),
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (attraction_id, record_date)
);

create trigger sustainability_metrics_set_updated_at
before update on public.sustainability_metrics
for each row execute function public.set_updated_at();

create index sustainability_metrics_attraction_date_idx
  on public.sustainability_metrics (attraction_id, record_date desc);

create or replace function public.can_manage_attraction(target_attraction_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    public.is_administrator()
    or (
      public.current_user_role() = 'operator'
      and exists (
        select 1
        from public.attractions attraction
        where attraction.id = target_attraction_id
          and public.is_organization_member(attraction.organization_id)
      )
    ),
    false
  );
$$;

revoke execute on function public.can_manage_attraction(uuid) from public, anon;
grant execute on function public.can_manage_attraction(uuid) to authenticated;

alter table public.sustainability_metrics enable row level security;
revoke all on public.sustainability_metrics from anon, authenticated;
grant select, insert, update, delete on public.sustainability_metrics to authenticated;

create policy sustainability_metrics_select_managed
on public.sustainability_metrics for select to authenticated
using (public.can_manage_attraction(attraction_id));

create policy sustainability_metrics_insert_managed
on public.sustainability_metrics for insert to authenticated
with check (
  public.can_manage_attraction(attraction_id)
  and created_by = (select auth.uid())
);

create policy sustainability_metrics_update_managed
on public.sustainability_metrics for update to authenticated
using (public.can_manage_attraction(attraction_id))
with check (public.can_manage_attraction(attraction_id));

create policy sustainability_metrics_delete_managed
on public.sustainability_metrics for delete to authenticated
using (public.can_manage_attraction(attraction_id));

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'issue-evidence',
  'issue-evidence',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy issue_evidence_insert_owner
on storage.objects for insert to authenticated
with check (
  bucket_id = 'issue-evidence'
  and split_part(name, '/', 1) = (select auth.uid())::text
);

create policy issue_evidence_select_related
on storage.objects for select to authenticated
using (
  bucket_id = 'issue-evidence'
  and (
    split_part(name, '/', 1) = (select auth.uid())::text
    or public.is_administrator()
    or exists (
      select 1
      from public.issue_reports report
      where report.evidence_path = name
        and public.can_manage_attraction(report.attraction_id)
    )
  )
);

create policy issue_evidence_delete_owner
on storage.objects for delete to authenticated
using (
  bucket_id = 'issue-evidence'
  and split_part(name, '/', 1) = (select auth.uid())::text
);

create or replace function public.get_booking_capacity(target_booking_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare selected_record record;
declare current_visitors integer;
begin
  select booking.tourist_id, attraction.id as attraction_id,
    attraction.name as attraction_name, attraction.location_name,
    attraction.cover_image_url, attraction.maximum_capacity
  into selected_record
  from public.bookings booking
  join public.attraction_slots slot on slot.id = booking.slot_id
  join public.attractions attraction on attraction.id = slot.attraction_id
  where booking.id = target_booking_id;

  if selected_record.attraction_id is null then
    raise exception 'BOOKING_NOT_FOUND';
  end if;
  if selected_record.tourist_id <> (select auth.uid())
    and not public.can_manage_attraction(selected_record.attraction_id) then
    raise exception 'BOOKING_ACCESS_DENIED' using errcode = '42501';
  end if;

  select coalesce(sum(booking.visitor_count), 0)::integer
  into current_visitors
  from public.attraction_check_ins check_in
  join public.bookings booking on booking.id = check_in.booking_id
  where check_in.attraction_id = selected_record.attraction_id
    and check_in.checked_out_at is null;

  return jsonb_build_object(
    'attraction_name', selected_record.attraction_name,
    'location_name', selected_record.location_name,
    'cover_image_url', selected_record.cover_image_url,
    'maximum_capacity', selected_record.maximum_capacity,
    'current_visitors', current_visitors,
    'updated_at', now()
  );
end;
$$;

create or replace function public.get_booking_geofence(target_booking_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare selected_record record;
declare check_in_record public.attraction_check_ins;
begin
  select booking.tourist_id, booking.status, attraction.id as attraction_id,
    attraction.latitude, attraction.longitude, attraction.geofence_radius_m,
    attraction.check_in_method, attraction.listing_status
  into selected_record
  from public.bookings booking
  join public.attraction_slots slot on slot.id = booking.slot_id
  join public.attractions attraction on attraction.id = slot.attraction_id
  where booking.id = target_booking_id;

  if selected_record.tourist_id is null
    or selected_record.tourist_id <> (select auth.uid()) then
    raise exception 'BOOKING_ACCESS_DENIED' using errcode = '42501';
  end if;
  if selected_record.latitude is null or selected_record.longitude is null then
    raise exception 'ATTRACTION_LOCATION_MISSING';
  end if;
  if selected_record.listing_status <> 'approved' then
    raise exception 'ATTRACTION_UNAVAILABLE';
  end if;

  select * into check_in_record
  from public.attraction_check_ins
  where booking_id = target_booking_id;

  return jsonb_build_object(
    'booking_id', target_booking_id,
    'latitude', selected_record.latitude,
    'longitude', selected_record.longitude,
    'entry_radius_m', selected_record.geofence_radius_m,
    'exit_radius_m', selected_record.geofence_radius_m + 50,
    'entry_dwell_seconds', 30,
    'exit_dwell_seconds', 45,
    'visit_status', case
      when check_in_record.checked_out_at is not null then 'checked_out'
      when check_in_record.id is not null then 'checked_in'
      else 'not_checked_in'
    end
  );
end;
$$;

create or replace function public.confirm_geofence_check_in(
  target_booking_id uuid,
  current_latitude double precision,
  current_longitude double precision,
  accuracy_m double precision,
  position_recorded_at timestamptz
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare selected_record record;
declare existing_check_in public.attraction_check_ins;
declare measured_distance double precision;
declare current_visitors integer;
begin
  select booking.tourist_id, booking.status as booking_status, booking.visitor_count,
    slot.starts_at, slot.ends_at, slot.status as slot_status,
    attraction.id as attraction_id, attraction.latitude, attraction.longitude,
    attraction.geofence_radius_m, attraction.maximum_capacity,
    attraction.check_in_method, attraction.listing_status
  into selected_record
  from public.bookings booking
  join public.attraction_slots slot on slot.id = booking.slot_id
  join public.attractions attraction on attraction.id = slot.attraction_id
  where booking.id = target_booking_id
  for update of booking;

  if selected_record.tourist_id is null
    or selected_record.tourist_id <> (select auth.uid()) then
    raise exception 'BOOKING_ACCESS_DENIED' using errcode = '42501';
  end if;
  if selected_record.booking_status <> 'confirmed' then raise exception 'BOOKING_NOT_ACTIVE'; end if;
  if selected_record.check_in_method <> 'geofence' then raise exception 'GEOFENCE_NOT_ENABLED'; end if;
  if selected_record.listing_status <> 'approved' then raise exception 'ATTRACTION_UNAVAILABLE'; end if;
  if selected_record.slot_status not in ('open', 'full')
    or now() not between selected_record.starts_at - interval '2 hours' and selected_record.ends_at then
    raise exception 'CHECK_IN_TIME_INVALID';
  end if;
  if accuracy_m < 0 or accuracy_m > 100 then raise exception 'LOCATION_ACCURACY_INVALID'; end if;
  if abs(extract(epoch from (now() - position_recorded_at))) > 120 then
    raise exception 'LOCATION_EXPIRED';
  end if;
  if selected_record.latitude is null or selected_record.longitude is null then
    raise exception 'ATTRACTION_LOCATION_MISSING';
  end if;
  if exists (
    select 1 from public.closure_periods closure
    where closure.attraction_id = selected_record.attraction_id
      and now() >= closure.starts_at and now() < closure.ends_at
  ) then raise exception 'ATTRACTION_CLOSED'; end if;

  select * into existing_check_in
  from public.attraction_check_ins where booking_id = target_booking_id;
  if existing_check_in.id is not null then
    return jsonb_build_object(
      'status', case when existing_check_in.checked_out_at is null then 'checked_in' else 'checked_out' end,
      'booking_id', target_booking_id,
      'checked_in_at', existing_check_in.checked_in_at,
      'checked_out_at', existing_check_in.checked_out_at
    );
  end if;

  measured_distance := 6371000 * 2 * asin(sqrt(
    power(sin(radians(current_latitude - selected_record.latitude) / 2), 2)
    + cos(radians(selected_record.latitude)) * cos(radians(current_latitude))
    * power(sin(radians(current_longitude - selected_record.longitude) / 2), 2)
  ));
  if measured_distance + accuracy_m > selected_record.geofence_radius_m then
    raise exception 'OUTSIDE_GEOFENCE';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(selected_record.attraction_id::text, 0));
  select coalesce(sum(booking.visitor_count), 0)::integer into current_visitors
  from public.attraction_check_ins check_in
  join public.bookings booking on booking.id = check_in.booking_id
  where check_in.attraction_id = selected_record.attraction_id
    and check_in.checked_out_at is null;
  if current_visitors + selected_record.visitor_count > selected_record.maximum_capacity then
    raise exception 'ATTRACTION_AT_CAPACITY';
  end if;

  insert into public.attraction_check_ins
    (booking_id, tourist_id, attraction_id, distance_m, source)
  values (
    target_booking_id, selected_record.tourist_id,
    selected_record.attraction_id, measured_distance, 'geofence'
  )
  returning * into existing_check_in;

  return jsonb_build_object(
    'status', 'checked_in',
    'booking_id', target_booking_id,
    'checked_in_at', existing_check_in.checked_in_at,
    'distance_m', measured_distance
  );
end;
$$;

create or replace function public.confirm_geofence_check_out(
  target_booking_id uuid,
  current_latitude double precision,
  current_longitude double precision,
  accuracy_m double precision,
  position_recorded_at timestamptz
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare selected_record record;
declare measured_distance double precision;
declare completed_at_value timestamptz;
begin
  select booking.tourist_id, attraction.id as attraction_id,
    attraction.latitude, attraction.longitude, attraction.geofence_radius_m,
    check_in.id as check_in_id, check_in.checked_in_at, check_in.checked_out_at
  into selected_record
  from public.bookings booking
  join public.attraction_slots slot on slot.id = booking.slot_id
  join public.attractions attraction on attraction.id = slot.attraction_id
  left join public.attraction_check_ins check_in on check_in.booking_id = booking.id
  where booking.id = target_booking_id
  for update of booking;

  if selected_record.tourist_id is null
    or selected_record.tourist_id <> (select auth.uid()) then
    raise exception 'BOOKING_ACCESS_DENIED' using errcode = '42501';
  end if;
  if selected_record.check_in_id is null then raise exception 'BOOKING_NOT_CHECKED_IN'; end if;
  if selected_record.checked_out_at is not null then
    return jsonb_build_object(
      'status', 'checked_out', 'booking_id', target_booking_id,
      'checked_in_at', selected_record.checked_in_at,
      'checked_out_at', selected_record.checked_out_at
    );
  end if;
  if accuracy_m < 0 or accuracy_m > 100 then raise exception 'LOCATION_ACCURACY_INVALID'; end if;
  if abs(extract(epoch from (now() - position_recorded_at))) > 120 then
    raise exception 'LOCATION_EXPIRED';
  end if;

  measured_distance := 6371000 * 2 * asin(sqrt(
    power(sin(radians(current_latitude - selected_record.latitude) / 2), 2)
    + cos(radians(selected_record.latitude)) * cos(radians(current_latitude))
    * power(sin(radians(current_longitude - selected_record.longitude) / 2), 2)
  ));
  if measured_distance - accuracy_m <= selected_record.geofence_radius_m + 50 then
    raise exception 'INSIDE_GEOFENCE';
  end if;

  completed_at_value := now();
  update public.attraction_check_ins
  set checked_out_at = completed_at_value
  where id = selected_record.check_in_id;
  update public.bookings
  set status = 'completed', completed_at = completed_at_value
  where id = target_booking_id;

  return jsonb_build_object(
    'status', 'checked_out', 'booking_id', target_booking_id,
    'checked_in_at', selected_record.checked_in_at,
    'checked_out_at', completed_at_value,
    'distance_m', measured_distance
  );
end;
$$;

create or replace function public.verify_staff_booking(lookup_value text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare normalized_value text := upper(trim(coalesce(lookup_value, '')));
declare selected_record record;
declare current_visitors integer;
declare result_status text;
begin
  if public.current_user_role() <> 'staff' then
    raise exception 'STAFF_ACCESS_DENIED' using errcode = '42501';
  end if;
  if normalized_value = '' then return jsonb_build_object('status', 'invalid'); end if;

  select booking.id as booking_id, booking.booking_code,
    booking.status as booking_status, booking.visitor_count,
    tourist.full_name as visitor_name, slot.starts_at, slot.ends_at,
    slot.status as slot_status, attraction.id as attraction_id,
    attraction.organization_id, attraction.name as attraction_name,
    attraction.listing_status, attraction.maximum_capacity,
    check_in.checked_in_at, check_in.checked_out_at
  into selected_record
  from public.bookings booking
  join public.profiles tourist on tourist.id = booking.tourist_id
  join public.attraction_slots slot on slot.id = booking.slot_id
  join public.attractions attraction on attraction.id = slot.attraction_id
  left join public.attraction_check_ins check_in on check_in.booking_id = booking.id
  where upper(booking.booking_code) = normalized_value
    or booking.qr_token::text = lower(normalized_value)
  limit 1;

  if selected_record.booking_id is null then return jsonb_build_object('status', 'invalid'); end if;
  if not exists (
    select 1 from public.organization_members member
    where member.user_id = (select auth.uid())
      and member.organization_id = selected_record.organization_id
      and member.member_role = 'staff' and member.is_active
  ) then return jsonb_build_object('status', 'wrong_attraction'); end if;

  select coalesce(sum(booking.visitor_count), 0)::integer into current_visitors
  from public.attraction_check_ins active_check_in
  join public.bookings booking on booking.id = active_check_in.booking_id
  where active_check_in.attraction_id = selected_record.attraction_id
    and active_check_in.checked_out_at is null;

  if selected_record.checked_out_at is not null then result_status := 'checked_out';
  elsif selected_record.checked_in_at is not null then result_status := 'checked_in';
  elsif selected_record.booking_status <> 'confirmed'
    or selected_record.listing_status <> 'approved' then result_status := 'invalid';
  elsif selected_record.slot_status not in ('open', 'full')
    or now() < selected_record.starts_at - interval '30 minutes'
    or now() > selected_record.ends_at
    or current_visitors + selected_record.visitor_count > selected_record.maximum_capacity
    or exists (
      select 1 from public.closure_periods closure
      where closure.attraction_id = selected_record.attraction_id
        and now() >= closure.starts_at and now() < closure.ends_at
    ) then result_status := 'wrong_slot';
  else result_status := 'valid';
  end if;

  return jsonb_build_object(
    'status', result_status,
    'booking_id', selected_record.booking_id,
    'booking_code', selected_record.booking_code,
    'visitor_name', selected_record.visitor_name,
    'visitor_count', selected_record.visitor_count,
    'attraction_name', selected_record.attraction_name,
    'starts_at', selected_record.starts_at,
    'ends_at', selected_record.ends_at,
    'checked_in_at', selected_record.checked_in_at,
    'checked_out_at', selected_record.checked_out_at,
    'current_visitor_count', current_visitors
  );
end;
$$;

create or replace function public.confirm_staff_check_in(target_booking_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare selected_record record;
declare current_visitors integer;
declare result_status text;
declare checked_in_at_value timestamptz;
declare checked_out_at_value timestamptz;
begin
  if public.current_user_role() <> 'staff' then
    raise exception 'STAFF_ACCESS_DENIED' using errcode = '42501';
  end if;

  select booking.id as booking_id, booking.booking_code,
    booking.status as booking_status, booking.tourist_id, booking.visitor_count,
    tourist.full_name as visitor_name, slot.starts_at, slot.ends_at,
    slot.status as slot_status, attraction.id as attraction_id,
    attraction.organization_id, attraction.name as attraction_name,
    attraction.listing_status, attraction.maximum_capacity,
    check_in.checked_in_at, check_in.checked_out_at
  into selected_record
  from public.bookings booking
  join public.profiles tourist on tourist.id = booking.tourist_id
  join public.attraction_slots slot on slot.id = booking.slot_id
  join public.attractions attraction on attraction.id = slot.attraction_id
  left join public.attraction_check_ins check_in on check_in.booking_id = booking.id
  where booking.id = target_booking_id
  for update of booking;

  if selected_record.booking_id is null then return jsonb_build_object('status', 'invalid'); end if;
  if not exists (
    select 1 from public.organization_members member
    where member.user_id = (select auth.uid())
      and member.organization_id = selected_record.organization_id
      and member.member_role = 'staff' and member.is_active
  ) then return jsonb_build_object('status', 'wrong_attraction'); end if;

  perform pg_advisory_xact_lock(hashtextextended(selected_record.attraction_id::text, 0));
  select coalesce(sum(booking.visitor_count), 0)::integer into current_visitors
  from public.attraction_check_ins active_check_in
  join public.bookings booking on booking.id = active_check_in.booking_id
  where active_check_in.attraction_id = selected_record.attraction_id
    and active_check_in.checked_out_at is null;

  checked_in_at_value := selected_record.checked_in_at;
  checked_out_at_value := selected_record.checked_out_at;
  if checked_out_at_value is not null then result_status := 'checked_out';
  elsif checked_in_at_value is not null then result_status := 'checked_in';
  elsif selected_record.booking_status <> 'confirmed'
    or selected_record.listing_status <> 'approved' then result_status := 'invalid';
  elsif selected_record.slot_status not in ('open', 'full')
    or now() < selected_record.starts_at - interval '30 minutes'
    or now() > selected_record.ends_at
    or current_visitors + selected_record.visitor_count > selected_record.maximum_capacity
    or exists (
      select 1 from public.closure_periods closure
      where closure.attraction_id = selected_record.attraction_id
        and now() >= closure.starts_at and now() < closure.ends_at
    ) then result_status := 'wrong_slot';
  else
    insert into public.attraction_check_ins
      (booking_id, tourist_id, attraction_id, distance_m, source)
    values (
      selected_record.booking_id, selected_record.tourist_id,
      selected_record.attraction_id, 0, 'staff_scan'
    )
    returning checked_in_at into checked_in_at_value;
    current_visitors := current_visitors + selected_record.visitor_count;
    result_status := 'checked_in';
  end if;

  return jsonb_build_object(
    'status', result_status,
    'booking_id', selected_record.booking_id,
    'booking_code', selected_record.booking_code,
    'visitor_name', selected_record.visitor_name,
    'visitor_count', selected_record.visitor_count,
    'attraction_name', selected_record.attraction_name,
    'starts_at', selected_record.starts_at,
    'ends_at', selected_record.ends_at,
    'checked_in_at', checked_in_at_value,
    'checked_out_at', checked_out_at_value,
    'current_visitor_count', current_visitors
  );
end;
$$;

create or replace function public.confirm_staff_check_out(target_booking_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare selected_record record;
declare current_visitors integer;
declare completed_at_value timestamptz;
begin
  if public.current_user_role() <> 'staff' then
    raise exception 'STAFF_ACCESS_DENIED' using errcode = '42501';
  end if;

  select booking.id as booking_id, booking.booking_code, booking.tourist_id,
    booking.visitor_count, tourist.full_name as visitor_name,
    slot.starts_at, slot.ends_at, attraction.id as attraction_id,
    attraction.organization_id, attraction.name as attraction_name,
    check_in.id as check_in_id, check_in.checked_in_at, check_in.checked_out_at
  into selected_record
  from public.bookings booking
  join public.profiles tourist on tourist.id = booking.tourist_id
  join public.attraction_slots slot on slot.id = booking.slot_id
  join public.attractions attraction on attraction.id = slot.attraction_id
  left join public.attraction_check_ins check_in on check_in.booking_id = booking.id
  where booking.id = target_booking_id
  for update of booking;

  if selected_record.booking_id is null then return jsonb_build_object('status', 'invalid'); end if;
  if not exists (
    select 1 from public.organization_members member
    where member.user_id = (select auth.uid())
      and member.organization_id = selected_record.organization_id
      and member.member_role = 'staff' and member.is_active
  ) then return jsonb_build_object('status', 'wrong_attraction'); end if;
  if selected_record.check_in_id is null then return jsonb_build_object('status', 'invalid'); end if;

  completed_at_value := coalesce(selected_record.checked_out_at, now());
  if selected_record.checked_out_at is null then
    update public.attraction_check_ins
    set checked_out_at = completed_at_value
    where id = selected_record.check_in_id;
    update public.bookings
    set status = 'completed', completed_at = completed_at_value
    where id = selected_record.booking_id;
  end if;

  select coalesce(sum(booking.visitor_count), 0)::integer into current_visitors
  from public.attraction_check_ins active_check_in
  join public.bookings booking on booking.id = active_check_in.booking_id
  where active_check_in.attraction_id = selected_record.attraction_id
    and active_check_in.checked_out_at is null;

  return jsonb_build_object(
    'status', 'checked_out',
    'booking_id', selected_record.booking_id,
    'booking_code', selected_record.booking_code,
    'visitor_name', selected_record.visitor_name,
    'visitor_count', selected_record.visitor_count,
    'attraction_name', selected_record.attraction_name,
    'starts_at', selected_record.starts_at,
    'ends_at', selected_record.ends_at,
    'checked_in_at', selected_record.checked_in_at,
    'checked_out_at', completed_at_value,
    'current_visitor_count', current_visitors
  );
end;
$$;

create or replace function public.get_operator_live_crowd_list()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if public.current_user_role() not in ('operator', 'administrator') then
    raise exception 'OPERATOR_ACCESS_DENIED' using errcode = '42501';
  end if;

  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'attraction_id', attraction.id,
      'attraction_name', attraction.name,
      'maximum_capacity', attraction.maximum_capacity,
      'current_visitors', stats.current_visitors,
      'occupancy_percent', case when attraction.maximum_capacity = 0 then 0
        else least(100, round(stats.current_visitors * 100.0 / attraction.maximum_capacity)::integer) end,
      'visitors_last_15_min', stats.visitors_last_15_min,
      'avg_visit_minutes', stats.avg_visit_minutes,
      'crowd_level', case
        when stats.current_visitors >= attraction.maximum_capacity then 'FULL'
        when stats.current_visitors * 1.0 / attraction.maximum_capacity >= 0.8 then 'HIGH'
        when stats.current_visitors * 1.0 / attraction.maximum_capacity >= 0.5 then 'MODERATE'
        else 'LOW'
      end
    ) order by attraction.name)
    from public.attractions attraction
    cross join lateral (
      select
        coalesce(sum(booking.visitor_count) filter (where check_in.checked_out_at is null), 0)::integer
          as current_visitors,
        coalesce(sum(booking.visitor_count) filter (
          where check_in.checked_in_at >= now() - interval '15 minutes'
        ), 0)::integer as visitors_last_15_min,
        round(avg(extract(epoch from (check_in.checked_out_at - check_in.checked_in_at)) / 60)
          filter (where check_in.checked_out_at is not null))::integer as avg_visit_minutes
      from public.attraction_check_ins check_in
      join public.bookings booking on booking.id = check_in.booking_id
      where check_in.attraction_id = attraction.id
    ) stats
    where attraction.listing_status = 'approved'
      and public.can_manage_attraction(attraction.id)
  ), '[]'::jsonb);
end;
$$;

create or replace function public.get_operator_live_crowd_details(target_attraction_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare attraction_record public.attractions;
declare current_visitors integer;
declare visitors_last_hour integer;
declare expected_visitors integer;
declare avg_visit_minutes integer;
declare intervals jsonb;
begin
  if not public.can_manage_attraction(target_attraction_id) then
    raise exception 'ATTRACTION_ACCESS_DENIED' using errcode = '42501';
  end if;
  select * into attraction_record from public.attractions where id = target_attraction_id;
  if attraction_record.id is null then raise exception 'ATTRACTION_NOT_FOUND'; end if;

  select
    coalesce(sum(booking.visitor_count) filter (where check_in.checked_out_at is null), 0)::integer,
    coalesce(sum(booking.visitor_count) filter (
      where check_in.checked_in_at >= now() - interval '1 hour'
    ), 0)::integer,
    coalesce(round(avg(extract(epoch from (check_in.checked_out_at - check_in.checked_in_at)) / 60)
      filter (where check_in.checked_out_at is not null)), 0)::integer
  into current_visitors, visitors_last_hour, avg_visit_minutes
  from public.attraction_check_ins check_in
  join public.bookings booking on booking.id = check_in.booking_id
  where check_in.attraction_id = target_attraction_id;

  select coalesce(sum(slot.reserved_capacity), 0)::integer into expected_visitors
  from public.attraction_slots slot
  where slot.attraction_id = target_attraction_id
    and slot.starts_at >= now()
    and slot.starts_at < now() + interval '1 hour'
    and slot.status in ('open', 'full');

  select coalesce(jsonb_agg(jsonb_build_object(
    'label', to_char(bucket.hour_start, 'HH24:00'),
    'visitors', coalesce(arrivals.visitors, 0)
  ) order by bucket.hour_start), '[]'::jsonb)
  into intervals
  from generate_series(
    date_trunc('hour', now()) - interval '5 hours',
    date_trunc('hour', now()),
    interval '1 hour'
  ) bucket(hour_start)
  left join lateral (
    select coalesce(sum(booking.visitor_count), 0)::integer as visitors
    from public.attraction_check_ins check_in
    join public.bookings booking on booking.id = check_in.booking_id
    where check_in.attraction_id = target_attraction_id
      and check_in.checked_in_at >= bucket.hour_start
      and check_in.checked_in_at < bucket.hour_start + interval '1 hour'
  ) arrivals on true;

  return jsonb_build_object(
    'attraction_id', attraction_record.id,
    'attraction_name', attraction_record.name,
    'maximum_capacity', attraction_record.maximum_capacity,
    'current_visitors', current_visitors,
    'occupancy_percent', least(100,
      round(current_visitors * 100.0 / attraction_record.maximum_capacity)::integer),
    'visitors_last_1_hour', visitors_last_hour,
    'expected_visitors', expected_visitors,
    'avg_visit_minutes', avg_visit_minutes,
    'crowd_level', case
      when current_visitors >= attraction_record.maximum_capacity then 'FULL'
      when current_visitors * 1.0 / attraction_record.maximum_capacity >= 0.8 then 'HIGH'
      when current_visitors * 1.0 / attraction_record.maximum_capacity >= 0.5 then 'MODERATE'
      else 'LOW'
    end,
    'hourly_intervals', intervals
  );
end;
$$;

revoke execute on function public.get_booking_capacity(uuid) from public, anon;
revoke execute on function public.get_booking_geofence(uuid) from public, anon;
revoke execute on function public.confirm_geofence_check_in(uuid, double precision, double precision, double precision, timestamptz) from public, anon;
revoke execute on function public.confirm_geofence_check_out(uuid, double precision, double precision, double precision, timestamptz) from public, anon;
revoke execute on function public.confirm_staff_check_out(uuid) from public, anon;
revoke execute on function public.get_operator_live_crowd_list() from public, anon;
revoke execute on function public.get_operator_live_crowd_details(uuid) from public, anon;

grant execute on function public.get_booking_capacity(uuid) to authenticated;
grant execute on function public.get_booking_geofence(uuid) to authenticated;
grant execute on function public.confirm_geofence_check_in(uuid, double precision, double precision, double precision, timestamptz) to authenticated;
grant execute on function public.confirm_geofence_check_out(uuid, double precision, double precision, double precision, timestamptz) to authenticated;
grant execute on function public.confirm_staff_check_out(uuid) to authenticated;
grant execute on function public.get_operator_live_crowd_list() to authenticated;
grant execute on function public.get_operator_live_crowd_details(uuid) to authenticated;
