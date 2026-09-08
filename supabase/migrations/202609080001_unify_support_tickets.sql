-- Unify the legacy issue-report workflow with the canonical support-ticket flow.
-- Legacy tables remain available for rollback/audit, but the app reads support_tickets.

alter table public.support_tickets
  add column if not exists legacy_issue_report_id uuid
    references public.issue_reports (id) on delete set null;

create unique index if not exists support_tickets_legacy_report_unique_idx
  on public.support_tickets (legacy_issue_report_id)
  where legacy_issue_report_id is not null;

alter table public.support_ticket_attachments
  add column if not exists storage_bucket text not null
    default 'support-ticket-attachments';

alter table public.support_ticket_attachments
  add column if not exists uploaded_by uuid
    references public.profiles (id) on delete restrict;

update public.support_ticket_attachments attachment
set uploaded_by = ticket.user_id
from public.support_tickets ticket
where ticket.id = attachment.ticket_id
  and attachment.uploaded_by is null;

alter table public.support_ticket_attachments
  alter column uploaded_by set not null;

alter table public.support_ticket_attachments
  drop constraint if exists support_ticket_attachments_storage_path_key;

create unique index if not exists support_ticket_attachments_bucket_path_idx
  on public.support_ticket_attachments (storage_bucket, storage_path);

update public.support_tickets ticket
set submission_language = profile.preferred_language
from public.profiles profile
where profile.id = ticket.user_id
  and nullif(trim(ticket.submission_language), '') is null;

insert into public.support_tickets (
  ticket_code,
  user_id,
  requester_name,
  attraction_id,
  attraction_name,
  booking_id,
  booking_code,
  category,
  subject,
  description,
  priority,
  status,
  submission_language,
  assigned_to,
  created_at,
  updated_at,
  resolved_at,
  legacy_issue_report_id
)
select
  report.report_code,
  report.tourist_id,
  coalesce(nullif(trim(profile.full_name), ''), 'Tourist'),
  report.attraction_id,
  attraction.name,
  report.booking_id,
  booking.booking_code,
  case report.category
    when 'Overcrowding' then 'overcrowding'
    when 'Safety' then 'safety'
    when 'Facility' then 'facility_damage'
    else 'other'
  end,
  left(report.category || ' - ' || report.location_note, 160),
  case
    when char_length(trim(report.description)) >= 10 then trim(report.description)
    else rpad(trim(report.description), 10, '.')
  end,
  case when report.priority::text = 'urgent' then 'urgent' else 'normal' end,
  case report.status::text
    when 'new' then 'pending'
    when 'in_progress' then 'in_progress'
    else 'resolved'
  end,
  profile.preferred_language,
  report.assigned_to,
  report.created_at,
  report.updated_at,
  report.resolved_at,
  report.id
from public.issue_reports report
join public.profiles profile on profile.id = report.tourist_id
join public.attractions attraction on attraction.id = report.attraction_id
join public.bookings booking on booking.id = report.booking_id
on conflict (ticket_code) do nothing;

insert into public.support_ticket_events (
  ticket_id,
  actor_id,
  actor_name,
  actor_role,
  event_type,
  message,
  to_status,
  created_at
)
select
  ticket.id,
  ticket.user_id,
  ticket.requester_name,
  'tourist',
  'created',
  'Support ticket created from the previous report system.',
  'pending',
  ticket.created_at
from public.support_tickets ticket
where ticket.legacy_issue_report_id is not null
  and not exists (
    select 1 from public.support_ticket_events event
    where event.ticket_id = ticket.id and event.event_type = 'created'
  );

insert into public.support_ticket_events (
  ticket_id,
  actor_id,
  actor_name,
  actor_role,
  event_type,
  message,
  to_status,
  created_at
)
select
  ticket.id,
  event.actor_id,
  coalesce(nullif(trim(actor.full_name), ''), 'TourFlow staff'),
  actor.role::text,
  case when event.event_type = 'created' then 'reply' else 'status_changed' end,
  event.note,
  case event.event_type
    when 'started' then 'in_progress'
    when 'resolved' then 'resolved'
    else null
  end,
  event.created_at
from public.report_events event
join public.support_tickets ticket
  on ticket.legacy_issue_report_id = event.report_id
join public.profiles actor on actor.id = event.actor_id
where event.event_type <> 'created'
  and not exists (
    select 1 from public.support_ticket_events existing
    where existing.ticket_id = ticket.id
      and existing.actor_id = event.actor_id
      and existing.created_at = event.created_at
  );

insert into public.support_ticket_attachments (
  ticket_id,
  uploaded_by,
  storage_bucket,
  storage_path,
  file_name,
  mime_type,
  size_bytes,
  created_at
)
select
  ticket.id,
  report.tourist_id,
  'issue-evidence',
  report.evidence_path,
  left(coalesce(nullif(split_part(report.evidence_path, '/', 3), ''), 'evidence.jpg'), 255),
  case lower(right(report.evidence_path, 5))
    when '.webp' then 'image/webp'
    when '.jpeg' then 'image/jpeg'
    else case lower(right(report.evidence_path, 4))
      when '.png' then 'image/png'
      else 'image/jpeg'
    end
  end,
  1,
  report.created_at
from public.issue_reports report
join public.support_tickets ticket
  on ticket.legacy_issue_report_id = report.id
where nullif(trim(report.evidence_path), '') is not null
on conflict (storage_bucket, storage_path) do nothing;

drop function if exists public.add_support_ticket_attachment(
  uuid, text, text, text, bigint
);

create function public.add_support_ticket_attachment(
  p_ticket_id uuid,
  p_storage_path text,
  p_file_name text,
  p_mime_type text,
  p_size_bytes bigint
)
returns public.support_ticket_attachments
language plpgsql
security definer
set search_path = ''
as $$
declare
  created_attachment public.support_ticket_attachments;
begin
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
$$;

revoke execute on function public.add_support_ticket_attachment(
  uuid, text, text, text, bigint
) from public, anon;

grant execute on function public.add_support_ticket_attachment(
  uuid, text, text, text, bigint
) to authenticated;

create or replace function public.delete_my_pending_support_ticket(
  p_ticket_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  selected_ticket public.support_tickets;
  storage_objects jsonb;
begin
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
$$;

revoke execute on function public.delete_my_pending_support_ticket(uuid)
  from public, anon;
grant execute on function public.delete_my_pending_support_ticket(uuid)
  to authenticated;
