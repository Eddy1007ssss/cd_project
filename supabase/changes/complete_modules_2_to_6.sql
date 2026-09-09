-- Apply after the repository migrations through management_integration.
-- This file is unapplied. Create a CLI migration and copy this SQL into it,
-- or run the whole file once in the SQL Editor for the linked project.
begin;

-- Preserve the price at booking/rescheduling time. Do not invent historical prices.
alter table public.bookings add column if not exists unit_price_myr numeric(12,2)
  check (unit_price_myr >= 0);
create or replace function public.capture_booking_price()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'INSERT' or new.slot_id is distinct from old.slot_id then
    select a.entrance_price_myr into new.unit_price_myr
    from public.attraction_slots s join public.attractions a on a.id = s.attraction_id
    where s.id = new.slot_id;
  else
    new.unit_price_myr := old.unit_price_myr;
  end if;
  return new;
end;
$$;
revoke all on function public.capture_booking_price() from public, anon, authenticated;
drop trigger if exists bookings_capture_price on public.bookings;
create trigger bookings_capture_price before insert or update on public.bookings
for each row execute function public.capture_booking_price();

-- Existing discovery star scores only. No review text or identity is exposed.
create or replace function public.get_attraction_rating_summary()
returns table(attraction_id uuid, average_rating numeric, rating_count bigint)
language sql stable security definer set search_path = '' as $$
  select f.attraction_id, round(avg(f.overall_rating)::numeric, 2), count(*)
  from public.feedback f join public.attractions a on a.id = f.attraction_id
  where a.listing_status = 'approved'
    and exists (select 1 from public.profiles p where p.id = auth.uid() and p.status = 'active')
  group by f.attraction_id;
$$;
revoke all on function public.get_attraction_rating_summary() from public, anon;
grant execute on function public.get_attraction_rating_summary() to authenticated;

alter table public.itineraries add column if not exists uses_road_routes boolean not null default false;
-- Atomic parent + items write, protected by the existing ownership RLS.
-- Saved plans are advisory; create/reschedule booking RPCs remain authoritative.
create or replace function public.save_my_itinerary(
  p_itinerary_id uuid, p_title text, p_booking_ids uuid[],
  p_travel_minutes integer[], p_distances_km numeric[], p_uses_road_routes boolean
) returns uuid language plpgsql security invoker set search_path = '' as $$
declare
  v_id uuid;
  v_count integer := coalesce(cardinality(p_booking_ids), 0);
  v_day date;
  v_record record;
  v_previous_end timestamptz;
  v_previous_start timestamptz;
  v_conflict boolean := false;
  v_minutes integer;
  v_distance numeric;
  v_index integer := 0;
begin
  if auth.uid() is null or not exists (select 1 from public.profiles p
    where p.id = auth.uid() and p.status = 'active' and p.role = 'tourist') then
    raise exception 'Tourist access required';
  end if;
  if char_length(trim(coalesce(p_title, ''))) not between 2 and 120
      or v_count not between 1 and 20
      or (select count(distinct x) from unnest(p_booking_ids) x) <> v_count
      or coalesce(cardinality(p_travel_minutes),0) <> v_count - 1
      or coalesce(cardinality(p_distances_km),0) <> v_count - 1 then
    raise exception 'INVALID_ITINERARY';
  end if;
  if (select count(*) from public.bookings b where b.id = any(p_booking_ids)
      and b.tourist_id = auth.uid() and b.status = 'confirmed') <> v_count then
    raise exception 'ITINERARY_BOOKING_UNAVAILABLE';
  end if;
  select (s.starts_at at time zone 'Asia/Kuala_Lumpur')::date into v_day
  from public.bookings b join public.attraction_slots s on s.id = b.slot_id
  where b.id = p_booking_ids[1];
  if p_itinerary_id is null then
    insert into public.itineraries(tourist_id, title, itinerary_date, uses_road_routes)
    values(auth.uid(), trim(p_title), v_day, coalesce(p_uses_road_routes,false)) returning id into v_id;
  else
    select id into v_id from public.itineraries where id = p_itinerary_id
      and tourist_id = auth.uid() for update;
    if v_id is null then raise exception 'ITINERARY_NOT_FOUND'; end if;
    update public.itineraries set title=trim(p_title), itinerary_date=v_day,
      uses_road_routes=coalesce(p_uses_road_routes,false), updated_at=now() where id=v_id;
    delete from public.itinerary_items where itinerary_id=v_id;
  end if;
  for v_record in
    select b.id, s.starts_at, s.ends_at, s.status as slot_status, s.attraction_id,
      a.listing_status, ci.id as check_in_id
    from unnest(p_booking_ids) with ordinality selected(id, position)
    join public.bookings b on b.id=selected.id
    join public.attraction_slots s on s.id=b.slot_id
    join public.attractions a on a.id=s.attraction_id
    left join public.attraction_check_ins ci on ci.booking_id=b.id
    order by selected.position
  loop
    if v_record.starts_at <= now() or v_record.slot_status not in ('open','full')
      or v_record.listing_status <> 'approved' or v_record.check_in_id is not null
      or (v_record.starts_at at time zone 'Asia/Kuala_Lumpur')::date <> v_day
      or (v_previous_start is not null and v_record.starts_at < v_previous_start)
      or exists(select 1 from public.closure_periods c where c.attraction_id=v_record.attraction_id
        and tstzrange(c.starts_at,c.ends_at,'[)') && tstzrange(v_record.starts_at,v_record.ends_at,'[)')) then
      raise exception 'ITINERARY_BOOKING_UNAVAILABLE';
    end if;
    v_minutes := case when v_index=0 then null else p_travel_minutes[v_index] end;
    v_distance := case when v_index=0 then null else p_distances_km[v_index] end;
    if v_index > 0 and (v_minutes is null or v_minutes not between 15 and 1440
        or v_distance is null or v_distance < 0 or v_distance > 10000) then
      raise exception 'INVALID_ITINERARY_ROUTE';
    end if;
    if v_previous_end is not null and
      v_record.starts_at < v_previous_end + make_interval(mins=>v_minutes) then
      v_conflict := true;
    end if;
    insert into public.itinerary_items(itinerary_id,booking_id,position,
      travel_minutes_from_previous,distance_km_from_previous,safety_buffer_minutes)
    values(v_id,v_record.id,v_index,v_minutes,v_distance,15);
    v_previous_start := v_record.starts_at;
    v_previous_end := v_record.ends_at;
    v_index := v_index+1;
  end loop;
  if v_index <> v_count then raise exception 'ITINERARY_BOOKING_UNAVAILABLE'; end if;
  update public.itineraries set status=case when v_conflict then 'conflict_detected'::public.itinerary_status
    else 'conflict_free'::public.itinerary_status end where id=v_id;
  return v_id;
end;
$$;
revoke all on function public.save_my_itinerary(uuid,text,uuid[],integer[],numeric[],boolean) from public, anon;
grant execute on function public.save_my_itinerary(uuid,text,uuid[],integer[],numeric[],boolean) to authenticated;

-- Subscribe to row changes with the existing RLS; no visitor access is broadened.
do $$
declare t text;
begin
  if exists(select 1 from pg_publication where pubname='supabase_realtime') then
    foreach t in array array['attraction_slots','attraction_check_ins'] loop
      if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime'
        and schemaname='public' and tablename=t) then
        execute format('alter publication supabase_realtime add table public.%I', t);
      end if;
    end loop;
  end if;
end;
$$;

-- Module 6 schema/function synchronization follows below.

alter table public.chat_conversations add column if not exists support_ticket_draft jsonb;
alter table public.issue_reports
  alter column booking_id drop not null,
  add column if not exists submission_language text,
  add column if not exists requester_name text,
  add column if not exists source_conversation_id uuid references public.chat_conversations(id) on delete set null;
alter table public.issue_reports drop constraint if exists issue_reports_description_check;
alter table public.issue_reports add constraint issue_reports_description_check
  check (char_length(trim(description)) between 5 and 4000) not valid;
alter table public.support_tickets
  alter column attraction_id drop not null,
  alter column attraction_name drop not null,
  add column if not exists case_type text not null default 'support',
  add column if not exists handler_type text not null default 'admin',
  add column if not exists issue_type text;
alter table public.support_ticket_events alter column actor_id drop not null;
alter table public.support_tickets drop constraint if exists support_tickets_attraction_name_check;
alter table public.support_tickets add constraint support_tickets_attraction_name_check CHECK (((char_length(attraction_name) >= 1) AND (char_length(attraction_name) <= 160))) not valid;
alter table public.support_tickets drop constraint if exists support_tickets_case_type_check;
alter table public.support_tickets add constraint support_tickets_case_type_check CHECK ((case_type = 'support'::text)) not valid;
alter table public.support_tickets drop constraint if exists support_tickets_category_check;
alter table public.support_tickets add constraint support_tickets_category_check CHECK ((category = ANY (ARRAY['booking'::text, 'account_profile'::text, 'payment_refund'::text, 'qr_check_in'::text, 'technical'::text, 'other'::text]))) not valid;
alter table public.support_tickets drop constraint if exists support_tickets_description_check;
alter table public.support_tickets add constraint support_tickets_description_check CHECK (((char_length(description) >= 10) AND (char_length(description) <= 4000))) not valid;
alter table public.support_tickets drop constraint if exists support_tickets_handler_type_check;
alter table public.support_tickets add constraint support_tickets_handler_type_check CHECK ((handler_type = ANY (ARRAY['admin'::text, 'operator'::text]))) not valid;
alter table public.support_tickets drop constraint if exists support_tickets_priority_check;
alter table public.support_tickets add constraint support_tickets_priority_check CHECK ((priority = ANY (ARRAY['normal'::text, 'high'::text, 'urgent'::text]))) not valid;
alter table public.support_tickets drop constraint if exists support_tickets_requester_name_check;
alter table public.support_tickets add constraint support_tickets_requester_name_check CHECK (((char_length(requester_name) >= 1) AND (char_length(requester_name) <= 160))) not valid;
alter table public.support_tickets drop constraint if exists support_tickets_status_check;
alter table public.support_tickets add constraint support_tickets_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'in_progress'::text, 'resolved'::text, 'closed'::text]))) not valid;
alter table public.support_tickets drop constraint if exists support_tickets_subject_check;
alter table public.support_tickets add constraint support_tickets_subject_check CHECK (((char_length(subject) >= 5) AND (char_length(subject) <= 160))) not valid;
alter table public.support_tickets drop constraint if exists support_tickets_submission_language_check;
alter table public.support_tickets add constraint support_tickets_submission_language_check CHECK (((submission_language IS NULL) OR (submission_language = ANY (ARRAY['en'::text, 'ms'::text, 'zh'::text, 'ja'::text, 'ko'::text])))) not valid;
alter table public.support_ticket_events drop constraint if exists support_ticket_events_event_type_check;
alter table public.support_ticket_events add constraint support_ticket_events_event_type_check CHECK ((event_type = ANY (ARRAY['created'::text, 'reply'::text, 'status_changed'::text, 'attachment'::text, 'routing_changed'::text]))) not valid;

CREATE OR REPLACE FUNCTION public.can_manage_support_ticket(p_ticket_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select exists (
    select 1
    from public.support_tickets as ticket
    join public.profiles as profile on profile.id = auth.uid()
    where ticket.id = p_ticket_id
      and ticket.case_type = 'support'
      and ticket.legacy_issue_report_id is null
      and profile.status = 'active'
      and (
        profile.role = 'administrator'
        or (
          profile.role = 'operator'
          and ticket.handler_type = 'operator'
          and ticket.attraction_id is not null
          and exists (
            select 1
            from public.attractions as attraction
            join public.organization_members as member
              on member.organization_id = attraction.organization_id
            where attraction.id = ticket.attraction_id
              and member.user_id = auth.uid()
              and member.is_active = true
          )
        )
      )
  );
$function$;
revoke all on function public.can_manage_support_ticket(p_ticket_id uuid) from public, anon, authenticated;
grant execute on function public.can_manage_support_ticket(p_ticket_id uuid) to authenticated;

create or replace function public.can_access_support_ticket(p_ticket_id uuid)
returns boolean language sql stable security definer set search_path = '' as $function$
  select exists(select 1 from public.support_tickets t
    join public.profiles p on p.id=auth.uid() and p.status='active'
    where t.id=p_ticket_id and t.case_type='support' and t.legacy_issue_report_id is null
      and (t.user_id=auth.uid() or public.can_manage_support_ticket(t.id)));
$function$;
revoke all on function public.can_access_support_ticket(p_ticket_id uuid) from public, anon, authenticated;
grant execute on function public.can_access_support_ticket(p_ticket_id uuid) to authenticated;

CREATE OR REPLACE FUNCTION public.create_issue_report_from_chat(p_attraction_id uuid, p_booking_id uuid, p_category text, p_description text, p_evidence_path text DEFAULT NULL::text, p_source_conversation_id uuid DEFAULT NULL::uuid)
 RETURNS TABLE(id uuid, report_code text, status text, confirmation_message text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  current_user_id uuid := auth.uid();
  category_value text;
  attraction_name_value text;
  created_report_id uuid;
  created_report_code text;
  created_status text;
  conversation_language text := 'English';
  confirmation text;
begin
  if auth.uid() is null or not exists(select 1 from public.profiles p where p.id=auth.uid() and p.status='active') then raise exception 'Active account required'; end if;
  if current_user_id is null then raise exception 'Authentication required'; end if;
  if not exists (
    select 1 from public.profiles as profile
    where profile.id = current_user_id and profile.status = 'active'
  ) then raise exception 'An active profile is required'; end if;
  category_value := case p_category
    when 'overcrowding' then 'Overcrowding'
    when 'facility_damage' then 'Facility'
    when 'safety' then 'Safety'
    when 'staff_service' then 'Others'
    when 'other' then 'Others'
    else null
  end;
  if category_value is null then raise exception 'Unsupported complaint category'; end if;
  if char_length(trim(coalesce(p_description, ''))) not between 10 and 4000 then
    raise exception 'Description must contain 10 to 4000 characters';
  end if;
  select attraction.name into attraction_name_value
  from public.attractions as attraction
  where attraction.id = p_attraction_id
    and attraction.listing_status = 'approved';
  if attraction_name_value is null then raise exception 'Approved attraction not found'; end if;
  if p_booking_id is not null and not exists (
    select 1 from public.bookings as booking
    join public.attraction_slots as slot on slot.id = booking.slot_id
    where booking.id = p_booking_id and booking.tourist_id = current_user_id
      and slot.attraction_id = p_attraction_id
  ) then raise exception 'The booking does not belong to you and this attraction'; end if;
  if p_evidence_path is not null
      and split_part(p_evidence_path, '/', 1) <> current_user_id::text then
    raise exception 'Invalid evidence path';
  end if;
  if p_source_conversation_id is not null then
    select conversation.language into conversation_language
    from public.chat_conversations as conversation
    where conversation.id = p_source_conversation_id
      and conversation.user_id = current_user_id;
    if conversation_language is null then raise exception 'Conversation not found'; end if;
  end if;
  insert into public.issue_reports (
    tourist_id, attraction_id, booking_id, category, location_note,
    description, priority, evidence_path, submission_language, requester_name,
    source_conversation_id
  ) values (
    current_user_id, p_attraction_id, p_booking_id, category_value,
    left(attraction_name_value, 200), trim(p_description),
    (case when p_category = 'safety' then 'urgent' else 'medium' end)::public.report_priority,
    p_evidence_path, lower(case conversation_language
      when 'Mandarin' then 'zh' when 'Bahasa Malaysia' then 'ms'
      when 'Japanese' then 'ja' when 'Korean' then 'ko' else 'en' end),
    (
      select profile.full_name
      from public.profiles as profile
      where profile.id = current_user_id
    ),
    p_source_conversation_id
  ) returning issue_reports.id, issue_reports.report_code, issue_reports.status
    into created_report_id, created_report_code, created_status;
  confirmation := case conversation_language
    when 'Mandarin' then format('投诉已提交。%s报告编号：%s%s当前状态：待处理', chr(10), created_report_code, chr(10))
    when 'Bahasa Malaysia' then format('Aduan dihantar.%sID Laporan: %s%sStatus: Menunggu', chr(10), created_report_code, chr(10))
    when 'Japanese' then format('苦情を送信しました。%sレポートID：%s%s状態：保留中', chr(10), created_report_code, chr(10))
    when 'Korean' then format('불만이 제출되었습니다.%s신고 ID: %s%s상태: 대기 중', chr(10), created_report_code, chr(10))
    else format('Complaint submitted.%sReport ID: %s%sStatus: Pending', chr(10), created_report_code, chr(10))
  end;
  if p_source_conversation_id is not null then
    update public.chat_conversations as conversation
    set complaint_draft = null
    where conversation.id = p_source_conversation_id
      and conversation.user_id = current_user_id;
    insert into public.chat_messages (conversation_id, sender, content)
    values (p_source_conversation_id, 'assistant', confirmation);
  end if;
  id := created_report_id;
  report_code := created_report_code;
  status := created_status;
  confirmation_message := confirmation;
  return next;
end;
$function$;
revoke all on function public.create_issue_report_from_chat(p_attraction_id uuid, p_booking_id uuid, p_category text, p_description text, p_evidence_path text, p_source_conversation_id uuid) from public, anon, authenticated;
grant execute on function public.create_issue_report_from_chat(p_attraction_id uuid, p_booking_id uuid, p_category text, p_description text, p_evidence_path text, p_source_conversation_id uuid) to authenticated;

create or replace function public.prepare_issue_report()
returns trigger language plpgsql security definer set search_path = '' as $function$
declare v_attraction uuid;
begin
  if auth.uid() is null or not exists(select 1 from public.profiles p
    where p.id=auth.uid() and p.status='active') then raise exception 'Active account required'; end if;
  new.tourist_id := auth.uid();
  if new.booking_id is not null then
    select s.attraction_id into v_attraction from public.bookings b
    join public.attraction_slots s on s.id=b.slot_id
    where b.id=new.booking_id and b.tourist_id=auth.uid();
    if v_attraction is null or (new.attraction_id is not null and new.attraction_id<>v_attraction) then
      raise exception 'BOOKING_ACCESS_DENIED'; end if;
    new.attraction_id := v_attraction;
  elsif not exists(select 1 from public.attractions a
    where a.id=new.attraction_id and a.listing_status='approved') then
    raise exception 'ATTRACTION_UNAVAILABLE';
  end if;
  if new.source_conversation_id is not null and not exists(
    select 1 from public.chat_conversations c where c.id=new.source_conversation_id and c.user_id=auth.uid()
  ) then raise exception 'CONVERSATION_ACCESS_DENIED'; end if;
  if new.evidence_path is not null and split_part(new.evidence_path,'/',1)<>auth.uid()::text then
    raise exception 'INVALID_EVIDENCE_PATH'; end if;
  new.priority := case when new.category='Safety' then 'urgent'::public.report_priority else 'medium'::public.report_priority end;
  return new;
end;
$function$;
revoke all on function public.prepare_issue_report() from public, anon, authenticated;

CREATE OR REPLACE FUNCTION public.tourflow_set_chat_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
  new.updated_at = now();
  return new;
end;
$function$;
revoke all on function public.tourflow_set_chat_updated_at() from public, anon, authenticated;

CREATE OR REPLACE FUNCTION public.save_chat_turn(p_conversation_id uuid, p_user_message text, p_assistant_message text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  current_user_id uuid := auth.uid();
begin
  if auth.uid() is null or not exists(select 1 from public.profiles p where p.id=auth.uid() and p.status='active') then raise exception 'Active account required'; end if;
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  if not exists (
    select 1
    from public.chat_conversations as conversation
    where conversation.id = p_conversation_id
      and conversation.user_id = current_user_id
  ) then
    raise exception 'Conversation not found';
  end if;

  if p_user_message is null
      or char_length(p_user_message) not between 1 and 10000 then
    raise exception 'Invalid user message';
  end if;

  if p_assistant_message is null
      or char_length(p_assistant_message) not between 1 and 10000 then
    raise exception 'Invalid assistant message';
  end if;

  insert into public.chat_messages (conversation_id, sender, content)
  values (p_conversation_id, 'user', p_user_message);

  insert into public.chat_messages (conversation_id, sender, content)
  values (p_conversation_id, 'assistant', p_assistant_message);
end;
$function$;
revoke all on function public.save_chat_turn(p_conversation_id uuid, p_user_message text, p_assistant_message text) from public, anon, authenticated;
grant execute on function public.save_chat_turn(p_conversation_id uuid, p_user_message text, p_assistant_message text) to authenticated;

CREATE OR REPLACE FUNCTION public.tourflow_set_support_ticket_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
  new.updated_at = now();
  return new;
end;
$function$;
revoke all on function public.tourflow_set_support_ticket_updated_at() from public, anon, authenticated;

CREATE OR REPLACE FUNCTION public.support_ticket_id_from_path(p_path text)
 RETURNS uuid
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO ''
AS $function$
declare
  path_parts text[];
begin
  if auth.uid() is null or not exists(select 1 from public.profiles p where p.id=auth.uid() and p.status='active') then raise exception 'Active account required'; end if;
  path_parts := string_to_array(p_path, '/');
  if array_length(path_parts, 1) < 3 then
    return null;
  end if;
  return path_parts[2]::uuid;
exception
  when invalid_text_representation then
    return null;
end;
$function$;
revoke all on function public.support_ticket_id_from_path(p_path text) from public, anon, authenticated;
grant execute on function public.support_ticket_id_from_path(p_path text) to authenticated;

CREATE OR REPLACE FUNCTION public.create_support_ticket(p_category text, p_issue_type text, p_subject text, p_description text, p_booking_id uuid DEFAULT NULL::uuid, p_attraction_id uuid DEFAULT NULL::uuid, p_source_conversation_id uuid DEFAULT NULL::uuid)
 RETURNS TABLE(id uuid, ticket_code text, status text, handler_type text, confirmation_message text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  current_user_id uuid := auth.uid();
  current_user_name text;
  attraction_id_value uuid := p_attraction_id;
  attraction_name_value text;
  booking_code_value text;
  generated_code text;
  created_ticket_id uuid;
  conversation_language text := 'English';
  routed_handler text := 'admin';
  confirmation text;
begin
  if auth.uid() is null or not exists(select 1 from public.profiles p where p.id=auth.uid() and p.status='active') then raise exception 'Active account required'; end if;
  if current_user_id is null then raise exception 'Authentication required'; end if;

  select profile.full_name into current_user_name
  from public.profiles as profile
  where profile.id = current_user_id and profile.status = 'active';
  if current_user_name is null then raise exception 'An active profile is required'; end if;

  if p_category not in (
    'booking', 'account_profile', 'payment_refund',
    'qr_check_in', 'technical', 'other'
  ) then raise exception 'Unsupported support category'; end if;
  if nullif(trim(p_issue_type), '') is null then
    raise exception 'Choose a support issue';
  end if;
  if char_length(trim(coalesce(p_subject, ''))) not between 5 and 160 then
    raise exception 'Subject must contain 5 to 160 characters';
  end if;
  if char_length(trim(coalesce(p_description, ''))) not between 10 and 4000 then
    raise exception 'Description must contain 10 to 4000 characters';
  end if;

  if p_booking_id is not null then
    select booking.booking_code, slot.attraction_id
    into booking_code_value, attraction_id_value
    from public.bookings as booking
    join public.attraction_slots as slot on slot.id = booking.slot_id
    where booking.id = p_booking_id and booking.tourist_id = current_user_id;
    if booking_code_value is null then
      raise exception 'The selected booking does not belong to you';
    end if;
  end if;

  if attraction_id_value is not null then
    select attraction.name into attraction_name_value
    from public.attractions as attraction
    where attraction.id = attraction_id_value
      and attraction.listing_status = 'approved';
    if attraction_name_value is null then raise exception 'Attraction not found'; end if;
  end if;

  if p_issue_type in (
    'attraction_closed', 'slot_cancelled', 'operator_reschedule',
    'entry_qr_rejected', 'attraction_booking_support'
  ) and attraction_id_value is not null then
    routed_handler := 'operator';
  end if;

  if p_source_conversation_id is not null then
    select conversation.language into conversation_language
    from public.chat_conversations as conversation
    where conversation.id = p_source_conversation_id
      and conversation.user_id = current_user_id;
    if conversation_language is null then raise exception 'Conversation not found'; end if;
  end if;

  generated_code := format(
    'TF-SUP-%s-%s', to_char(now(), 'YYYY'),
    lpad(nextval('public.support_ticket_number_seq')::text, 5, '0')
  );

  insert into public.support_tickets (
    ticket_code, user_id, attraction_id, attraction_name, booking_id,
    booking_code, source_conversation_id, requester_name, category,
    issue_type, subject, description, priority, case_type, handler_type
  ) values (
    generated_code, current_user_id, attraction_id_value,
    attraction_name_value, p_booking_id, booking_code_value,
    p_source_conversation_id, current_user_name, p_category,
    trim(p_issue_type), trim(p_subject), trim(p_description),
    case when p_category in ('payment_refund', 'qr_check_in') then 'high' else 'normal' end,
    'support', routed_handler
  ) returning support_tickets.id into created_ticket_id;

  insert into public.support_ticket_events (
    ticket_id, actor_id, actor_name, actor_role, event_type, message, to_status
  ) values (
    created_ticket_id, current_user_id, current_user_name, 'tourist',
    'created', 'Support ticket created through TourFlow Assistant.', 'pending'
  );

  confirmation := case conversation_language
    when 'Mandarin' then format('客服工单已提交。%s工单编号：%s%s当前状态：待处理', chr(10), generated_code, chr(10))
    when 'Bahasa Malaysia' then format('Tiket sokongan dihantar.%sID Tiket: %s%sStatus: Menunggu', chr(10), generated_code, chr(10))
    when 'Japanese' then format('サポートチケットを送信しました。%sチケットID：%s%s状態：保留中', chr(10), generated_code, chr(10))
    when 'Korean' then format('지원 티켓이 제출되었습니다.%s티켓 ID: %s%s상태: 대기 중', chr(10), generated_code, chr(10))
    else format('Support ticket submitted.%sTicket ID: %s%sStatus: Pending', chr(10), generated_code, chr(10))
  end;

  if p_source_conversation_id is not null then
    update public.chat_conversations as conversation
    set support_ticket_draft = null
    where conversation.id = p_source_conversation_id
      and conversation.user_id = current_user_id;
    insert into public.chat_messages (conversation_id, sender, content)
    values (p_source_conversation_id, 'assistant', confirmation);
  end if;

  id := created_ticket_id;
  ticket_code := generated_code;
  status := 'pending';
  handler_type := routed_handler;
  confirmation_message := confirmation;
  return next;
end;
$function$;
revoke all on function public.create_support_ticket(p_category text, p_issue_type text, p_subject text, p_description text, p_booking_id uuid, p_attraction_id uuid, p_source_conversation_id uuid) from public, anon, authenticated;
grant execute on function public.create_support_ticket(p_category text, p_issue_type text, p_subject text, p_description text, p_booking_id uuid, p_attraction_id uuid, p_source_conversation_id uuid) to authenticated;

CREATE OR REPLACE FUNCTION public.update_support_ticket_status(p_ticket_id uuid, p_status text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  actor_name_value text;
  actor_role_value text;
  previous_status text;
begin
  if auth.uid() is null or not exists(select 1 from public.profiles p where p.id=auth.uid() and p.status='active') then raise exception 'Active account required'; end if;
  if not public.can_manage_support_ticket(p_ticket_id) then
    raise exception 'You cannot manage this support ticket';
  end if;
  if p_status not in ('pending', 'in_progress', 'resolved') then
    raise exception 'Unsupported support ticket status';
  end if;

  select profile.full_name, profile.role
  into actor_name_value, actor_role_value
  from public.profiles as profile
  where profile.id = auth.uid();

  select ticket.status
  into previous_status
  from public.support_tickets as ticket
  where ticket.id = p_ticket_id;

  if previous_status = p_status then
    return;
  end if;

  update public.support_tickets
  set
    status = p_status,
    resolved_at = case when p_status = 'resolved' then now() else null end
  where support_tickets.id = p_ticket_id;

  insert into public.support_ticket_events (
    ticket_id,
    actor_id,
    actor_name,
    actor_role,
    event_type,
    message,
    from_status,
    to_status
  ) values (
    p_ticket_id,
    auth.uid(),
    actor_name_value,
    actor_role_value,
    'status_changed',
    'Ticket status updated.',
    previous_status,
    p_status
  );
end;
$function$;
revoke all on function public.update_support_ticket_status(p_ticket_id uuid, p_status text) from public, anon, authenticated;
grant execute on function public.update_support_ticket_status(p_ticket_id uuid, p_status text) to authenticated;

CREATE OR REPLACE FUNCTION public.delete_my_pending_support_ticket(p_ticket_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  selected_ticket public.support_tickets;
  storage_objects jsonb;
begin
  if auth.uid() is null or not exists(select 1 from public.profiles p where p.id=auth.uid() and p.status='active') then raise exception 'Active account required'; end if;
  if (select auth.uid()) is null then
    raise exception 'Authentication required';
  end if;

  select * into selected_ticket
  from public.support_tickets
  where id = p_ticket_id
    and user_id = (select auth.uid())
  for update;

  if selected_ticket.id is null then
    raise exception 'Support ticket not found' using errcode = '42501';
  end if;
  if selected_ticket.status <> 'pending' then
    raise exception 'Only pending support tickets can be deleted';
  end if;

  select coalesce(
    jsonb_agg(jsonb_build_object(
      'bucket', attachment.storage_bucket,
      'path', attachment.storage_path
    )),
    '[]'::jsonb
  ) into storage_objects
  from public.support_ticket_attachments attachment
  where attachment.ticket_id = p_ticket_id;

  delete from public.support_tickets where id = p_ticket_id;

  return jsonb_build_object(
    'deleted', true,
    'storage_objects', storage_objects
  );
end;
$function$;
revoke all on function public.delete_my_pending_support_ticket(p_ticket_id uuid) from public, anon, authenticated;
grant execute on function public.delete_my_pending_support_ticket(p_ticket_id uuid) to authenticated;

CREATE OR REPLACE FUNCTION public.tourflow_capture_ticket_submission_language()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  raw_language text;
begin
  if tg_op = 'UPDATE' then
    new.submission_language := old.submission_language;
    return new;
  end if;

  if new.source_conversation_id is not null then
    select coalesce(
      nullif(conversation.complaint_draft ->> 'submissionLanguage', ''),
      conversation.language
    )
    into raw_language
    from public.chat_conversations as conversation
    where conversation.id = new.source_conversation_id
      and conversation.user_id = new.user_id;
  end if;

  if raw_language is null then
    select profile.preferred_language
    into raw_language
    from public.profiles as profile
    where profile.id = new.user_id;
  end if;

  new.submission_language := case lower(trim(coalesce(raw_language, 'en')))
    when 'ms' then 'ms'
    when 'bm' then 'ms'
    when 'bahasa malaysia' then 'ms'
    when 'bahasa melayu' then 'ms'
    when 'zh' then 'zh'
    when 'zh-cn' then 'zh'
    when 'mandarin' then 'zh'
    when 'chinese' then 'zh'
    when '中文' then 'zh'
    when '简体中文' then 'zh'
    when 'ja' then 'ja'
    when 'jp' then 'ja'
    when 'japanese' then 'ja'
    when '日本語' then 'ja'
    when 'ko' then 'ko'
    when 'kr' then 'ko'
    when 'korean' then 'ko'
    when '한국어' then 'ko'
    else 'en'
  end;

  return new;
end;
$function$;
revoke all on function public.tourflow_capture_ticket_submission_language() from public, anon, authenticated;

CREATE OR REPLACE FUNCTION public.add_support_ticket_attachment(p_ticket_id uuid, p_storage_path text, p_file_name text, p_mime_type text, p_size_bytes bigint)
 RETURNS public.support_ticket_attachments
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  created_attachment public.support_ticket_attachments;
begin
  if auth.uid() is null or not exists(select 1 from public.profiles p where p.id=auth.uid() and p.status='active') then raise exception 'Active account required'; end if;
  if (select auth.uid()) is null then
    raise exception 'Authentication required';
  end if;
  if not exists (
    select 1 from public.support_tickets ticket
    where ticket.id = p_ticket_id
      and ticket.user_id = (select auth.uid())
  ) then
    raise exception 'Support ticket not found';
  end if;
  if split_part(p_storage_path, '/', 1) <> (select auth.uid())::text then
    raise exception 'Invalid attachment path';
  end if;
  if p_mime_type not in ('image/jpeg', 'image/png', 'image/webp') then
    raise exception 'Unsupported attachment type';
  end if;
  if p_size_bytes not between 1 and 5242880 then
    raise exception 'Attachment must be 5 MB or smaller';
  end if;

  insert into public.support_ticket_attachments (
    ticket_id,
    uploaded_by,
    storage_bucket,
    storage_path,
    file_name,
    mime_type,
    size_bytes
  ) values (
    p_ticket_id,
    (select auth.uid()),
    'support-ticket-attachments',
    p_storage_path,
    p_file_name,
    p_mime_type,
    p_size_bytes
  ) returning * into created_attachment;

  return created_attachment;
end;
$function$;
revoke all on function public.add_support_ticket_attachment(p_ticket_id uuid, p_storage_path text, p_file_name text, p_mime_type text, p_size_bytes bigint) from public, anon, authenticated;
grant execute on function public.add_support_ticket_attachment(p_ticket_id uuid, p_storage_path text, p_file_name text, p_mime_type text, p_size_bytes bigint) to authenticated;

CREATE OR REPLACE FUNCTION public.protect_archived_support_ticket()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if old.legacy_issue_report_id is not null then
    raise exception 'Archived issue-report copies cannot be changed';
  end if;
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$function$;
revoke all on function public.protect_archived_support_ticket() from public, anon, authenticated;

CREATE OR REPLACE FUNCTION public.require_active_support_ticket_parent()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if exists (
    select 1 from public.support_tickets ticket
    where ticket.id = new.ticket_id
      and ticket.legacy_issue_report_id is not null
  ) then
    raise exception 'Archived issue-report copies cannot receive activity';
  end if;
  return new;
end;
$function$;
revoke all on function public.require_active_support_ticket_parent() from public, anon, authenticated;

CREATE OR REPLACE FUNCTION public.reply_to_my_support_ticket(p_ticket_id uuid, p_message text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  actor_name_value text;
begin
  if auth.uid() is null or not exists(select 1 from public.profiles p where p.id=auth.uid() and p.status='active') then raise exception 'Active account required'; end if;
  if char_length(trim(p_message)) not between 2 and 4000 then
    raise exception 'Reply must contain 2 to 4000 characters';
  end if;
  if not exists (
    select 1 from public.support_tickets
    where id = p_ticket_id and user_id = auth.uid()
      and case_type = 'support' and status <> 'closed'
  ) then raise exception 'Support ticket is unavailable'; end if;
  select full_name into actor_name_value from public.profiles where id = auth.uid();
  insert into public.support_ticket_events (
    ticket_id, actor_id, actor_name, actor_role, event_type, message
  ) values (
    p_ticket_id, auth.uid(), coalesce(actor_name_value, 'Tourist'),
    'tourist', 'reply', trim(p_message)
  );
  update public.support_tickets set updated_at = now() where id = p_ticket_id;
end;
$function$;
revoke all on function public.reply_to_my_support_ticket(p_ticket_id uuid, p_message text) from public, anon, authenticated;
grant execute on function public.reply_to_my_support_ticket(p_ticket_id uuid, p_message text) to authenticated;

CREATE OR REPLACE FUNCTION public.close_my_support_ticket(p_ticket_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  previous_status text;
  actor_name_value text;
begin
  if auth.uid() is null or not exists(select 1 from public.profiles p where p.id=auth.uid() and p.status='active') then raise exception 'Active account required'; end if;
  select status into previous_status from public.support_tickets
  where id = p_ticket_id and user_id = auth.uid() and case_type = 'support';
  if previous_status is null then raise exception 'Support ticket not found'; end if;
  if previous_status = 'closed' then return; end if;
  select full_name into actor_name_value from public.profiles where id = auth.uid();
  update public.support_tickets set status = 'closed', resolved_at = now()
  where id = p_ticket_id;
  insert into public.support_ticket_events (
    ticket_id, actor_id, actor_name, actor_role, event_type,
    message, from_status, to_status
  ) values (
    p_ticket_id, auth.uid(), coalesce(actor_name_value, 'Tourist'), 'tourist',
    'status_changed', 'Ticket closed by tourist.', previous_status, 'closed'
  );
end;
$function$;
revoke all on function public.close_my_support_ticket(p_ticket_id uuid) from public, anon, authenticated;
grant execute on function public.close_my_support_ticket(p_ticket_id uuid) to authenticated;

CREATE OR REPLACE FUNCTION public.reopen_my_support_ticket(p_ticket_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  actor_name_value text;
begin
  if auth.uid() is null or not exists(select 1 from public.profiles p where p.id=auth.uid() and p.status='active') then raise exception 'Active account required'; end if;
  if not exists (
    select 1 from public.support_tickets
    where id = p_ticket_id and user_id = auth.uid()
      and case_type = 'support' and status = 'closed'
  ) then raise exception 'Only your closed support ticket can be reopened'; end if;
  select full_name into actor_name_value from public.profiles where id = auth.uid();
  update public.support_tickets
  set status = 'in_progress', resolved_at = null
  where id = p_ticket_id;
  insert into public.support_ticket_events (
    ticket_id, actor_id, actor_name, actor_role, event_type,
    message, from_status, to_status
  ) values (
    p_ticket_id, auth.uid(), coalesce(actor_name_value, 'Tourist'), 'tourist',
    'status_changed', 'Ticket reopened by tourist.', 'closed', 'in_progress'
  );
end;
$function$;
revoke all on function public.reopen_my_support_ticket(p_ticket_id uuid) from public, anon, authenticated;
grant execute on function public.reopen_my_support_ticket(p_ticket_id uuid) to authenticated;

CREATE OR REPLACE FUNCTION public.reply_to_support_ticket(p_ticket_id uuid, p_message text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  actor_name_value text;
  actor_role_value text;
  previous_status text;
  resulting_status text;
begin
  if auth.uid() is null or not exists(select 1 from public.profiles p where p.id=auth.uid() and p.status='active') then raise exception 'Active account required'; end if;
  if not public.can_manage_support_ticket(p_ticket_id) then
    raise exception 'You cannot manage this support ticket';
  end if;
  if char_length(trim(p_message)) not between 2 and 4000 then
    raise exception 'Reply must contain 2 to 4000 characters';
  end if;
  select full_name, role into actor_name_value, actor_role_value
  from public.profiles where id = auth.uid();
  select status into previous_status from public.support_tickets where id = p_ticket_id;
  if previous_status = 'closed' then raise exception 'Closed tickets cannot receive replies'; end if;
  resulting_status := case when previous_status = 'pending' then 'in_progress' else previous_status end;
  update public.support_tickets set status = resulting_status where id = p_ticket_id;
  if resulting_status <> previous_status then
    insert into public.support_ticket_events (
      ticket_id, actor_id, actor_name, actor_role, event_type,
      message, from_status, to_status
    ) values (
      p_ticket_id, auth.uid(), actor_name_value, actor_role_value,
      'status_changed', 'Work started after the first response.',
      previous_status, resulting_status
    );
  end if;
  insert into public.support_ticket_events (
    ticket_id, actor_id, actor_name, actor_role, event_type, message
  ) values (
    p_ticket_id, auth.uid(), actor_name_value, actor_role_value,
    'reply', trim(p_message)
  );
  return resulting_status;
end;
$function$;
revoke all on function public.reply_to_support_ticket(p_ticket_id uuid, p_message text) from public, anon, authenticated;
grant execute on function public.reply_to_support_ticket(p_ticket_id uuid, p_message text) to authenticated;

CREATE OR REPLACE FUNCTION public.transfer_support_ticket(p_ticket_id uuid, p_handler_type text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  previous_handler text;
  actor_name_value text;
begin
  if auth.uid() is null or not exists(select 1 from public.profiles p where p.id=auth.uid() and p.status='active') then raise exception 'Active account required'; end if;
  if p_handler_type not in ('admin', 'operator') then
    raise exception 'Unsupported handler';
  end if;
  if not exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'administrator' and status = 'active'
  ) then raise exception 'Administrator access required'; end if;
  select handler_type into previous_handler from public.support_tickets
  where id = p_ticket_id and case_type = 'support';
  if previous_handler is null then raise exception 'Support ticket not found'; end if;
  if p_handler_type = 'operator' and not exists (
    select 1 from public.support_tickets where id = p_ticket_id and attraction_id is not null
  ) then raise exception 'Choose a related attraction before routing to an operator'; end if;
  if previous_handler = p_handler_type then return; end if;
  select full_name into actor_name_value from public.profiles where id = auth.uid();
  update public.support_tickets set handler_type = p_handler_type where id = p_ticket_id;
  insert into public.support_ticket_events (
    ticket_id, actor_id, actor_name, actor_role, event_type, message
  ) values (
    p_ticket_id, auth.uid(), actor_name_value, 'administrator',
    'routing_changed', format('Routing changed from %s to %s.', previous_handler, p_handler_type)
  );
end;
$function$;
revoke all on function public.transfer_support_ticket(p_ticket_id uuid, p_handler_type text) from public, anon, authenticated;
grant execute on function public.transfer_support_ticket(p_ticket_id uuid, p_handler_type text) to authenticated;

drop trigger if exists issue_report_prepare on public.issue_reports;
CREATE TRIGGER issue_report_prepare BEFORE INSERT ON public.issue_reports FOR EACH ROW EXECUTE FUNCTION public.prepare_issue_report();

drop trigger if exists issue_reports_set_updated_at on public.issue_reports;
CREATE TRIGGER issue_reports_set_updated_at BEFORE UPDATE ON public.issue_reports FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

drop trigger if exists set_chat_conversation_updated_at on public.chat_conversations;
CREATE TRIGGER set_chat_conversation_updated_at BEFORE UPDATE ON public.chat_conversations FOR EACH ROW EXECUTE FUNCTION public.tourflow_set_chat_updated_at();

drop trigger if exists capture_support_ticket_submission_language on public.support_tickets;
CREATE TRIGGER capture_support_ticket_submission_language BEFORE INSERT OR UPDATE OF submission_language ON public.support_tickets FOR EACH ROW EXECUTE FUNCTION public.tourflow_capture_ticket_submission_language();

drop trigger if exists set_support_ticket_updated_at on public.support_tickets;
CREATE TRIGGER set_support_ticket_updated_at BEFORE UPDATE ON public.support_tickets FOR EACH ROW EXECUTE FUNCTION public.tourflow_set_support_ticket_updated_at();

drop trigger if exists support_tickets_protect_archived on public.support_tickets;
CREATE TRIGGER support_tickets_protect_archived BEFORE DELETE OR UPDATE ON public.support_tickets FOR EACH ROW EXECUTE FUNCTION public.protect_archived_support_ticket();

drop trigger if exists support_ticket_events_require_active on public.support_ticket_events;
CREATE TRIGGER support_ticket_events_require_active BEFORE INSERT OR UPDATE ON public.support_ticket_events FOR EACH ROW EXECUTE FUNCTION public.require_active_support_ticket_parent();

drop trigger if exists support_ticket_attachments_require_active on public.support_ticket_attachments;
CREATE TRIGGER support_ticket_attachments_require_active BEFORE INSERT OR UPDATE ON public.support_ticket_attachments FOR EACH ROW EXECUTE FUNCTION public.require_active_support_ticket_parent();

drop policy if exists "Allowed users can read support ticket attachments" on public.support_ticket_attachments;

drop policy if exists "support_ticket_attachments_related_select" on public.support_ticket_attachments;

drop policy if exists "Allowed users can read support ticket events" on public.support_ticket_events;

drop policy if exists "support_ticket_events_related_select" on public.support_ticket_events;

drop policy if exists "Allowed users can read support tickets" on public.support_tickets;

drop policy if exists "support_tickets_related_select" on public.support_tickets;
create policy support_tickets_related_select on public.support_tickets for select to authenticated
  using (public.can_access_support_ticket(id));
create policy support_ticket_events_related_select on public.support_ticket_events for select to authenticated
  using (public.can_access_support_ticket(ticket_id));
create policy support_ticket_attachments_related_select on public.support_ticket_attachments for select to authenticated
  using (public.can_access_support_ticket(ticket_id));

-- A restrictive guard also protects against older permissive storage policies.
drop policy if exists support_attachments_access_guard on storage.objects;
create policy support_attachments_access_guard on storage.objects as restrictive for select to authenticated
using (bucket_id <> 'support-ticket-attachments' or exists(
  select 1 from public.support_ticket_attachments a
  where a.storage_bucket=bucket_id and a.storage_path=name
    and public.can_access_support_ticket(a.ticket_id)));
-- Preserve owner access for newly uploaded, not-yet-attached objects through
-- existing insert/delete policies; downloads require a linked accessible ticket.
do $$
begin
  if to_regprocedure('public.create_support_ticket(uuid,uuid,text,text,text,uuid)') is not null then
    revoke execute on function public.create_support_ticket(uuid,uuid,text,text,text,uuid) from public,anon,authenticated;
  end if;
end;
$$;
notify pgrst, 'reload schema';
commit;
