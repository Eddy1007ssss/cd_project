-- Complete the Supabase-backed management workflows. This migration is
-- idempotent because it was initially deployed through the SQL editor.
begin;

-- Restore the intended managed-access policy without making analytics public.
alter table public.sustainability_metrics enable row level security;
revoke all on public.sustainability_metrics from anon;
grant select, insert, update, delete on public.sustainability_metrics to authenticated;
drop policy if exists sustainability_metrics_select_managed on public.sustainability_metrics;
drop policy if exists sustainability_metrics_insert_managed on public.sustainability_metrics;
drop policy if exists sustainability_metrics_update_managed on public.sustainability_metrics;
drop policy if exists sustainability_metrics_delete_managed on public.sustainability_metrics;
create policy sustainability_metrics_select_managed on public.sustainability_metrics
  for select to authenticated using (public.can_manage_attraction(attraction_id));
create policy sustainability_metrics_insert_managed on public.sustainability_metrics
  for insert to authenticated
  with check (public.can_manage_attraction(attraction_id));
create policy sustainability_metrics_update_managed on public.sustainability_metrics
  for update to authenticated using (public.can_manage_attraction(attraction_id))
  with check (public.can_manage_attraction(attraction_id));
create policy sustainability_metrics_delete_managed on public.sustainability_metrics
  for delete to authenticated using (public.can_manage_attraction(attraction_id));

-- Approved attraction edits must go back through review. Suspended or pending
-- listings cannot be edited by their operator until the administrator decides.
drop policy if exists attractions_update_member on public.attractions;
create policy attractions_update_member on public.attractions
  for update to authenticated
  using (public.current_user_role() = 'operator'
    and public.is_organization_member(organization_id)
    and listing_status in ('draft', 'rejected', 'approved'))
  with check (public.current_user_role() = 'operator'
    and public.is_organization_member(organization_id)
    and listing_status in ('draft', 'pending'));

-- Invoker rights: every table operation still goes through existing RLS.
-- The parent and its seven operating-hour rows save in one transaction.
create or replace function public.save_managed_attraction(details jsonb, hours jsonb)
returns uuid language plpgsql security invoker set search_path = '' as $$
declare
  target_id uuid := nullif(details->>'id', '')::uuid;
  org_id uuid := (details->>'organization_id')::uuid;
  old_row public.attractions;
  next_status public.listing_status := (details->>'listing_status')::public.listing_status;
  kind public.attraction_type := (details->>'attraction_type')::public.attraction_type;
  radius integer := (details->>'geofence_radius_m')::integer;
begin
  if (select auth.uid()) is null or public.current_user_role() is distinct from 'operator'
    or not public.is_organization_member(org_id) then
    raise exception 'Operator access required';
  end if;
  if not exists (select 1 from public.operator_organizations where id = org_id and is_active) then
    raise exception 'Organization is inactive';
  end if;
  if next_status is null or next_status not in ('draft', 'pending') then
    raise exception 'Save as draft or submit for review';
  end if;
  if radius is null or radius not between 25 and 2000 then raise exception 'Radius must be 25–2000 m'; end if;
  if hours is null or jsonb_typeof(hours) <> 'array' or jsonb_array_length(hours) <> 7 then
    raise exception 'Provide operating hours for all seven days';
  end if;
  if (select count(distinct (h->>'day_of_week')::int) from jsonb_array_elements(hours) h) <> 7 then
    raise exception 'Provide each weekday exactly once';
  end if;
  if target_id is not null then
    select * into old_row from public.attractions where id = target_id for update;
    if old_row.id is null or old_row.organization_id <> org_id then raise exception 'Attraction not accessible'; end if;
    if old_row.listing_status not in ('draft', 'rejected', 'approved') then
      raise exception 'Pending or suspended listings cannot be edited';
    end if;
    if old_row.listing_status = 'approved' then next_status := 'pending'; end if;
    if exists (select 1 from public.attraction_slots s where s.attraction_id = target_id
      and s.ends_at > now() and s.status in ('open', 'full')
      and s.maximum_capacity > (details->>'maximum_capacity')::integer) then
      raise exception 'Reduce future slot capacities before reducing attraction capacity';
    end if;
    update public.attractions set
      name = trim(details->>'name'), description = trim(details->>'description'),
      category = trim(details->>'category'), location_name = trim(details->>'location_name'),
      address = trim(details->>'address'), latitude = (details->>'latitude')::double precision,
      longitude = (details->>'longitude')::double precision,
      entrance_price_myr = (details->>'entrance_price_myr')::numeric,
      facilities = array(select jsonb_array_elements_text(details->'facilities')),
      visitor_guidelines = details->>'visitor_guidelines', attraction_rules = details->>'attraction_rules',
      attraction_type = kind, maximum_capacity = (details->>'maximum_capacity')::integer,
      geofence_radius_m = radius, geofence_radius_metres = radius,
      check_in_method = case when kind = 'outdoor' then 'geofence' else 'staff_scan' end,
      listing_status = next_status
    where id = target_id;
    if not found then raise exception 'Attraction was not saved'; end if;
  else
    insert into public.attractions (organization_id, created_by, name, description,
      category, location_name, address, latitude, longitude, entrance_price_myr,
      facilities, visitor_guidelines, attraction_rules, attraction_type, maximum_capacity,
      geofence_radius_m, geofence_radius_metres, check_in_method, listing_status)
    values (org_id, (select auth.uid()), trim(details->>'name'), trim(details->>'description'),
      trim(details->>'category'), trim(details->>'location_name'), trim(details->>'address'),
      (details->>'latitude')::double precision, (details->>'longitude')::double precision,
      (details->>'entrance_price_myr')::numeric,
      array(select jsonb_array_elements_text(details->'facilities')),
      details->>'visitor_guidelines', details->>'attraction_rules', kind,
      (details->>'maximum_capacity')::integer, radius, radius,
      case when kind = 'outdoor' then 'geofence' else 'staff_scan' end, next_status)
    returning id into target_id;
  end if;
  insert into public.operating_hours(attraction_id, day_of_week, is_closed, opens_at, closes_at)
  select target_id, (h->>'day_of_week')::smallint, (h->>'is_closed')::boolean,
    (h->>'opens_at')::time, (h->>'closes_at')::time from jsonb_array_elements(hours) h
  on conflict (attraction_id, day_of_week) do update set
    is_closed = excluded.is_closed, opens_at = excluded.opens_at, closes_at = excluded.closes_at;
  return target_id;
end;
$$;

-- Never silently move or close a slot with reservations. Locking the slot
-- serializes these edits against the existing booking/cancellation RPCs.
create or replace function public.save_managed_slot(details jsonb)
returns uuid language plpgsql security invoker set search_path = '' as $$
declare
  target_id uuid := nullif(details->>'id', '')::uuid;
  attraction_id_value uuid := (details->>'attraction_id')::uuid;
  old_row public.attraction_slots;
  start_time timestamptz := (details->>'starts_at')::timestamptz;
  end_time timestamptz := (details->>'ends_at')::timestamptz;
  capacity integer := (details->>'maximum_capacity')::integer;
  next_status public.slot_status := (details->>'status')::public.slot_status;
begin
  if not public.can_manage_attraction(attraction_id_value) then raise exception 'Operator access required'; end if;
  if start_time is null or end_time is null or start_time >= end_time or capacity is null or capacity < 1 then
    raise exception 'Invalid slot period or capacity';
  end if;
  if next_status is null or next_status not in ('open', 'closed') then raise exception 'Choose open or closed'; end if;
  if capacity > (select maximum_capacity from public.attractions where id = attraction_id_value) then
    raise exception 'Slot capacity exceeds attraction capacity';
  end if;
  if target_id is not null then
    select * into old_row from public.attraction_slots where id = target_id for update;
    if old_row.id is null or old_row.attraction_id <> attraction_id_value then raise exception 'Slot not accessible'; end if;
    if old_row.reserved_capacity > 0 then raise exception 'This slot has reservations. Resolve bookings before editing or closing it.'; end if;
    update public.attraction_slots set starts_at = start_time, ends_at = end_time,
      maximum_capacity = capacity, status = next_status where id = target_id;
    if not found then raise exception 'Slot was not saved'; end if;
  else
    if start_time <= now() then raise exception 'New slots must start in the future'; end if;
    insert into public.attraction_slots(attraction_id, starts_at, ends_at, maximum_capacity, status, created_by)
    values(attraction_id_value, start_time, end_time, capacity, next_status, (select auth.uid()))
    returning id into target_id;
  end if;
  return target_id;
end;
$$;

create or replace function public.add_managed_closure(details jsonb)
returns uuid language plpgsql security invoker set search_path = '' as $$
declare
  attraction_id_value uuid := (details->>'attraction_id')::uuid;
  start_time timestamptz := (details->>'starts_at')::timestamptz;
  end_time timestamptz := (details->>'ends_at')::timestamptz;
  result_id uuid;
begin
  if not public.can_manage_attraction(attraction_id_value) then raise exception 'Operator access required'; end if;
  if start_time is null or end_time is null or start_time >= end_time or nullif(trim(details->>'reason'), '') is null then
    raise exception 'Provide a valid maintenance period and reason'; end if;
  -- A closure is a booking restriction, not a cancellation. Existing bookings
  -- remain visible and must be handled explicitly by their tourists/operators.
  insert into public.closure_periods(attraction_id, starts_at, ends_at, closure_type, reason, created_by)
  values(attraction_id_value, start_time, end_time, 'maintenance', trim(details->>'reason'), (select auth.uid()))
  returning id into result_id;
  return result_id;
end;
$$;

revoke execute on function public.save_managed_attraction(jsonb, jsonb) from public, anon;
revoke execute on function public.save_managed_slot(jsonb) from public, anon;
revoke execute on function public.add_managed_closure(jsonb) from public, anon;
grant execute on function public.save_managed_attraction(jsonb, jsonb) to authenticated;
grant execute on function public.save_managed_slot(jsonb) to authenticated;
grant execute on function public.add_managed_closure(jsonb) to authenticated;
commit;
