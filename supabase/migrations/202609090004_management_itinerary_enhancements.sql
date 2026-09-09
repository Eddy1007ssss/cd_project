-- TourFlow: Module 1 management enhancements, Module 2 image controls,
-- and Module 3 booking/bulk-slot rules.

alter table public.bookings drop constraint if exists bookings_visitor_count_check;
alter table public.bookings add constraint bookings_visitor_count_check
  check (visitor_count between 1 and 10);

-- Keep the server-side RPC aligned with the table constraint.  Reusing the
-- deployed definition avoids accidentally losing its conflict/capacity logic.
do $$
declare definition text;
begin
  select pg_get_functiondef('public.create_booking(uuid, integer)'::regprocedure)
    into definition;
  definition := replace(definition, 'between 1 and 6', 'between 1 and 10');
  definition := replace(definition, 'between 1 and 6', 'between 1 and 10');
  execute definition;
end;
$$;

create table if not exists public.app_notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check (char_length(trim(title)) between 1 and 160),
  message text not null check (char_length(trim(message)) between 1 and 1000),
  kind text not null default 'general',
  entity_type text,
  entity_id uuid,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists app_notifications_recipient_idx
  on public.app_notifications(recipient_id, created_at desc);

create table if not exists public.admin_audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  summary text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.operator_appeals (
  id uuid primary key default gen_random_uuid(),
  applicant_id uuid not null references public.profiles(id) on delete cascade,
  application_id uuid references public.operator_applications(id) on delete cascade,
  attraction_id uuid references public.attractions(id) on delete cascade,
  explanation text not null check (char_length(trim(explanation)) between 10 and 1500),
  status public.application_status not null default 'pending',
  review_note text,
  reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  constraint appeal_has_one_target check ((application_id is null) <> (attraction_id is null))
);

create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(trim(title)) between 1 and 160),
  message text not null check (char_length(trim(message)) between 1 and 2000),
  audience text not null check (audience in ('all','tourist','operator','staff','administrator')),
  starts_at timestamptz not null default now(),
  expires_at timestamptz,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  constraint announcement_dates check (expires_at is null or expires_at > starts_at)
);

alter table public.app_notifications enable row level security;
alter table public.admin_audit_logs enable row level security;
alter table public.operator_appeals enable row level security;
alter table public.announcements enable row level security;

create policy notifications_owner_select on public.app_notifications for select to authenticated
  using (recipient_id = (select auth.uid()));
create policy notifications_owner_update on public.app_notifications for update to authenticated
  using (recipient_id = (select auth.uid())) with check (recipient_id = (select auth.uid()));
create policy audit_admin_select on public.admin_audit_logs for select to authenticated
  using (public.current_user_role() = 'administrator');
create policy appeals_owner_or_admin_select on public.operator_appeals for select to authenticated
  using (applicant_id = (select auth.uid()) or public.current_user_role() = 'administrator');
create policy appeals_owner_insert on public.operator_appeals for insert to authenticated
  with check (applicant_id = (select auth.uid()));
create policy announcements_read_active on public.announcements for select to authenticated
  using (starts_at <= now() and (expires_at is null or expires_at > now())
    and (audience = 'all' or audience = public.current_user_role()::text));
create policy announcements_admin_write on public.announcements for all to authenticated
  using (public.current_user_role() = 'administrator')
  with check (public.current_user_role() = 'administrator' and created_by = (select auth.uid()));

create or replace function public.log_management_change() returns trigger
language plpgsql security definer set search_path = '' as $$
declare operator_id uuid;
begin
  if tg_table_name = 'operator_applications' and new.status is distinct from old.status then
    insert into public.app_notifications(recipient_id,title,message,kind,entity_type,entity_id)
      values(new.applicant_id, 'Operator application ' || new.status,
        coalesce(nullif(new.review_note,''), 'Your application status has changed.'), 'approval', 'operator_application', new.id);
    insert into public.admin_audit_logs(actor_id,action,entity_type,entity_id,summary)
      values((select auth.uid()), 'application_' || new.status, 'operator_application', new.id, 'Application status changed.');
  elsif tg_table_name = 'attractions' then
    for operator_id in select user_id from public.organization_members where organization_id=new.organization_id and member_role='operator' and is_active loop
      if new.listing_status is distinct from old.listing_status then
        insert into public.app_notifications(recipient_id,title,message,kind,entity_type,entity_id)
          values(operator_id, 'Attraction ' || new.listing_status,
            coalesce(nullif(new.review_note,''), 'The listing status has changed.'), 'listing', 'attraction', new.id);
      end if;
    end loop;
    if to_jsonb(new) is distinct from to_jsonb(old) then
      insert into public.admin_audit_logs(actor_id,action,entity_type,entity_id,summary)
        values((select auth.uid()), 'attraction_changed', 'attraction', new.id,
          case when new.listing_status is distinct from old.listing_status then 'Listing status changed to ' || new.listing_status else 'Attraction details changed.' end);
    end if;
  end if;
  return new;
end; $$;
drop trigger if exists operator_application_management_log on public.operator_applications;
create trigger operator_application_management_log after update on public.operator_applications
  for each row execute function public.log_management_change();
drop trigger if exists attraction_management_log on public.attractions;
create trigger attraction_management_log after update on public.attractions
  for each row execute function public.log_management_change();

create or replace function public.bulk_create_managed_slots(
  target_attraction_id uuid, first_day date, last_day date,
  opening_time time, closing_time time, duration_minutes integer, capacity integer
) returns integer language plpgsql security definer set search_path = '' as $$
declare day_value date; start_value timestamptz; end_value timestamptz; inserted_count integer := 0;
begin
  if public.current_user_role() <> 'operator' then raise exception 'Operator access required'; end if;
  if first_day > last_day or last_day > first_day + 90 then raise exception 'INVALID_DATE_RANGE'; end if;
  if duration_minutes not between 15 and 480 or capacity < 1 or opening_time >= closing_time then raise exception 'INVALID_SLOT_TEMPLATE'; end if;
  if not exists (select 1 from public.attractions a join public.organization_members m on m.organization_id=a.organization_id
    where a.id=target_attraction_id and m.user_id=(select auth.uid()) and m.member_role='operator' and m.is_active) then raise exception 'ATTRACTION_ACCESS_DENIED'; end if;
  for day_value in select generate_series(first_day, last_day, interval '1 day')::date loop
    start_value := (day_value + opening_time) at time zone current_setting('TimeZone');
    while (start_value::time + make_interval(mins => duration_minutes)) <= closing_time loop
      end_value := start_value + make_interval(mins => duration_minutes);
      insert into public.attraction_slots(attraction_id, starts_at, ends_at, maximum_capacity, created_by)
        values(target_attraction_id, start_value, end_value, capacity, (select auth.uid()))
        on conflict (attraction_id, starts_at, ends_at) do nothing;
      if found then inserted_count := inserted_count + 1; end if;
      start_value := end_value;
    end loop;
  end loop;
  return inserted_count;
end; $$;

create or replace function public.set_organization_staff(target_organization_id uuid, target_user_id uuid, active boolean)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if public.current_user_role() <> 'operator' or not exists (select 1 from public.organization_members
    where organization_id=target_organization_id and user_id=(select auth.uid()) and member_role='operator' and is_active) then raise exception 'ORGANIZATION_ACCESS_DENIED'; end if;
  if not exists (select 1 from public.profiles where id=target_user_id and role='staff' and status='active') then raise exception 'ACTIVE_STAFF_ACCOUNT_REQUIRED'; end if;
  insert into public.organization_members(organization_id,user_id,member_role,is_active)
    values(target_organization_id,target_user_id,'staff',active)
    on conflict (organization_id,user_id) do update set member_role='staff',is_active=excluded.is_active;
end; $$;

create or replace function public.create_operator_appeal(target_application_id uuid, target_attraction_id uuid, explanation_value text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare appeal_id uuid;
begin
  if (select auth.uid()) is null then raise exception 'Authentication required'; end if;
  if (target_application_id is null) = (target_attraction_id is null) then raise exception 'APPEAL_TARGET_REQUIRED'; end if;
  if target_application_id is not null and not exists (select 1 from public.operator_applications where id=target_application_id and applicant_id=(select auth.uid()) and status='rejected') then raise exception 'APPEAL_NOT_ALLOWED'; end if;
  if target_attraction_id is not null and not exists (select 1 from public.attractions a join public.organization_members m on m.organization_id=a.organization_id where a.id=target_attraction_id and m.user_id=(select auth.uid()) and m.member_role='operator' and a.listing_status in ('rejected','suspended')) then raise exception 'APPEAL_NOT_ALLOWED'; end if;
  insert into public.operator_appeals(applicant_id,application_id,attraction_id,explanation)
    values((select auth.uid()),target_application_id,target_attraction_id,explanation_value) returning id into appeal_id;
  return appeal_id;
end; $$;

revoke all on function public.bulk_create_managed_slots(uuid,date,date,time,time,integer,integer) from public;
revoke all on function public.set_organization_staff(uuid,uuid,boolean) from public;
revoke all on function public.create_operator_appeal(uuid,uuid,text) from public;
grant execute on function public.bulk_create_managed_slots(uuid,date,date,time,time,integer,integer) to authenticated;
grant execute on function public.set_organization_staff(uuid,uuid,boolean) to authenticated;
grant execute on function public.create_operator_appeal(uuid,uuid,text) to authenticated;
