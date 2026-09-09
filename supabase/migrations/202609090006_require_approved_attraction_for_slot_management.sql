-- Operators may only manage slots and maintenance after an administrator has
-- approved the attraction. The checks exist in both RPCs and RLS policies so
-- direct Data API requests cannot bypass the app.

create or replace function public.save_managed_slot(details jsonb)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  target_id uuid := nullif(details->>'id', '')::uuid;
  attraction_id_value uuid := (details->>'attraction_id')::uuid;
  old_row public.attraction_slots;
  start_time timestamptz := (details->>'starts_at')::timestamptz;
  end_time timestamptz := (details->>'ends_at')::timestamptz;
  capacity integer := (details->>'maximum_capacity')::integer;
  next_status public.slot_status := (details->>'status')::public.slot_status;
begin
  if not public.can_manage_attraction(attraction_id_value) then
    raise exception 'Operator access required';
  end if;

  if not exists (
    select 1 from public.attractions
    where id = attraction_id_value and listing_status = 'approved'
  ) then
    raise exception 'Only approved attractions can manage slots';
  end if;

  if start_time is null or end_time is null or start_time >= end_time
      or capacity is null or capacity < 1 then
    raise exception 'Invalid slot period or capacity';
  end if;
  if next_status is null or next_status not in ('open', 'closed') then
    raise exception 'Choose open or closed';
  end if;
  if capacity > (select maximum_capacity from public.attractions where id = attraction_id_value) then
    raise exception 'Slot capacity exceeds attraction capacity';
  end if;

  if target_id is not null then
    select * into old_row from public.attraction_slots where id = target_id for update;
    if old_row.id is null or old_row.attraction_id <> attraction_id_value then
      raise exception 'Slot not accessible';
    end if;
    if old_row.reserved_capacity > 0 then
      raise exception 'This slot has reservations. Resolve bookings before editing or closing it.';
    end if;
    update public.attraction_slots
    set starts_at = start_time, ends_at = end_time,
        maximum_capacity = capacity, status = next_status
    where id = target_id;
    if not found then raise exception 'Slot was not saved'; end if;
  else
    if start_time <= now() then raise exception 'New slots must start in the future'; end if;
    insert into public.attraction_slots(
      attraction_id, starts_at, ends_at, maximum_capacity, status, created_by
    ) values (
      attraction_id_value, start_time, end_time, capacity, next_status, (select auth.uid())
    ) returning id into target_id;
  end if;

  return target_id;
end;
$$;

create or replace function public.add_managed_closure(details jsonb)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  attraction_id_value uuid := (details->>'attraction_id')::uuid;
  start_time timestamptz := (details->>'starts_at')::timestamptz;
  end_time timestamptz := (details->>'ends_at')::timestamptz;
  result_id uuid;
begin
  if not public.can_manage_attraction(attraction_id_value) then
    raise exception 'Operator access required';
  end if;
  if not exists (
    select 1 from public.attractions
    where id = attraction_id_value and listing_status = 'approved'
  ) then
    raise exception 'Only approved attractions can manage maintenance periods';
  end if;
  if start_time is null or end_time is null or start_time >= end_time
      or nullif(trim(details->>'reason'), '') is null then
    raise exception 'Provide a valid maintenance period and reason';
  end if;

  insert into public.closure_periods(
    attraction_id, starts_at, ends_at, closure_type, reason, created_by
  ) values (
    attraction_id_value, start_time, end_time, 'maintenance',
    trim(details->>'reason'), (select auth.uid())
  ) returning id into result_id;
  return result_id;
end;
$$;

create or replace function public.bulk_create_managed_slots(
  target_attraction_id uuid,
  first_day date,
  last_day date,
  opening_time time,
  closing_time time,
  duration_minutes integer,
  capacity integer
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  day_value date;
  start_value timestamptz;
  end_value timestamptz;
  inserted_count integer := 0;
begin
  if public.current_user_role() <> 'operator' then
    raise exception 'Operator access required';
  end if;
  if not exists (
    select 1
    from public.attractions a
    join public.organization_members m on m.organization_id = a.organization_id
    where a.id = target_attraction_id
      and a.listing_status = 'approved'
      and m.user_id = (select auth.uid())
      and m.member_role = 'operator'
      and m.is_active
  ) then
    raise exception 'Only approved attractions can manage slots';
  end if;
  if first_day > last_day or last_day > first_day + 90 then
    raise exception 'INVALID_DATE_RANGE';
  end if;
  if duration_minutes not between 15 and 480
      or capacity < 1 or opening_time >= closing_time then
    raise exception 'INVALID_SLOT_TEMPLATE';
  end if;

  for day_value in select generate_series(first_day, last_day, interval '1 day')::date loop
    start_value := (day_value + opening_time) at time zone current_setting('TimeZone');
    while (start_value::time + make_interval(mins => duration_minutes)) <= closing_time loop
      end_value := start_value + make_interval(mins => duration_minutes);
      insert into public.attraction_slots(
        attraction_id, starts_at, ends_at, maximum_capacity, created_by
      ) values (
        target_attraction_id, start_value, end_value, capacity, (select auth.uid())
      ) on conflict (attraction_id, starts_at, ends_at) do nothing;
      if found then inserted_count := inserted_count + 1; end if;
      start_value := end_value;
    end loop;
  end loop;
  return inserted_count;
end;
$$;

drop policy if exists attraction_slots_insert_member on public.attraction_slots;
create policy attraction_slots_insert_member
on public.attraction_slots for insert to authenticated
with check (
  reserved_capacity = 0
  and (
    public.is_administrator()
    or exists (
      select 1 from public.attractions attraction
      where attraction.id = attraction_id
        and attraction.listing_status = 'approved'
        and public.is_organization_member(attraction.organization_id)
    )
  )
);

drop policy if exists attraction_slots_update_member on public.attraction_slots;
create policy attraction_slots_update_member
on public.attraction_slots for update to authenticated
using (
  public.is_administrator()
  or exists (
    select 1 from public.attractions attraction
    where attraction.id = attraction_id
      and attraction.listing_status = 'approved'
      and public.is_organization_member(attraction.organization_id)
  )
)
with check (
  public.is_administrator()
  or exists (
    select 1 from public.attractions attraction
    where attraction.id = attraction_id
      and attraction.listing_status = 'approved'
      and public.is_organization_member(attraction.organization_id)
  )
);

drop policy if exists attraction_slots_delete_empty_member on public.attraction_slots;
create policy attraction_slots_delete_empty_member
on public.attraction_slots for delete to authenticated
using (
  reserved_capacity = 0
  and (
    public.is_administrator()
    or exists (
      select 1 from public.attractions attraction
      where attraction.id = attraction_id
        and attraction.listing_status = 'approved'
        and public.is_organization_member(attraction.organization_id)
    )
  )
);

drop policy if exists closure_periods_manage_member on public.closure_periods;
create policy closure_periods_manage_member
on public.closure_periods for all to authenticated
using (
  public.is_administrator()
  or exists (
    select 1 from public.attractions attraction
    where attraction.id = attraction_id
      and attraction.listing_status = 'approved'
      and public.is_organization_member(attraction.organization_id)
  )
)
with check (
  public.is_administrator()
  or exists (
    select 1 from public.attractions attraction
    where attraction.id = attraction_id
      and attraction.listing_status = 'approved'
      and public.is_organization_member(attraction.organization_id)
  )
);

revoke execute on function public.save_managed_slot(jsonb) from public, anon;
revoke execute on function public.add_managed_closure(jsonb) from public, anon;
revoke execute on function public.bulk_create_managed_slots(uuid, date, date, time, time, integer, integer) from public, anon;
grant execute on function public.save_managed_slot(jsonb) to authenticated;
grant execute on function public.add_managed_closure(jsonb) to authenticated;
grant execute on function public.bulk_create_managed_slots(uuid, date, date, time, time, integer, integer) to authenticated;
