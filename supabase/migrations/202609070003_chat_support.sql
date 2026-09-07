-- TourFlow chat history, guided complaints and support-ticket workflow.

alter table public.profiles
  drop constraint if exists profiles_preferred_language_check;

alter table public.profiles
  add constraint profiles_preferred_language_check
    check (preferred_language in ('en', 'ms', 'zh', 'ja', 'ko'));

create table public.chat_conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  title text not null default 'TourFlow conversation'
    check (char_length(title) between 1 and 120),
  language text not null default 'English'
    check (char_length(language) between 1 and 40),
  last_message_preview text not null default ''
    check (char_length(last_message_preview) <= 300),
  complaint_draft jsonb,
  booking_action_draft jsonb,
  created_at timestamptz not null default now(),
  last_message_at timestamptz not null default now()
);

create index chat_conversations_user_recent_idx
  on public.chat_conversations (user_id, last_message_at desc);

create table public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null
    references public.chat_conversations (id) on delete cascade,
  sender text not null check (sender in ('user', 'assistant')),
  content text not null check (char_length(content) between 1 and 8000),
  sequence_number bigint generated always as identity,
  created_at timestamptz not null default now(),
  unique (conversation_id, sequence_number)
);

create index chat_messages_conversation_order_idx
  on public.chat_messages (conversation_id, sequence_number);

create table public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  ticket_code text not null unique,
  user_id uuid not null references public.profiles (id),
  requester_name text not null,
  attraction_id uuid not null references public.attractions (id),
  attraction_name text not null,
  booking_id uuid references public.bookings (id),
  booking_code text,
  category text not null check (
    category in (
      'overcrowding', 'facility_damage', 'safety', 'staff_service', 'other'
    )
  ),
  subject text not null check (char_length(subject) between 3 and 160),
  description text not null check (char_length(description) between 10 and 4000),
  priority text not null default 'normal'
    check (priority in ('normal', 'urgent')),
  status text not null default 'pending'
    check (status in ('pending', 'in_progress', 'resolved')),
  submission_language text,
  source_conversation_id uuid
    references public.chat_conversations (id) on delete set null,
  assigned_to uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  resolved_at timestamptz
);

create trigger support_tickets_set_updated_at
before update on public.support_tickets
for each row execute function public.set_updated_at();

create index support_tickets_user_recent_idx
  on public.support_tickets (user_id, created_at desc);
create index support_tickets_attraction_status_idx
  on public.support_tickets (attraction_id, status, created_at desc);

create table public.support_ticket_events (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references public.support_tickets (id) on delete cascade,
  sequence_number bigint generated always as identity,
  actor_id uuid not null references public.profiles (id),
  actor_name text not null,
  actor_role text not null,
  event_type text not null
    check (event_type in ('created', 'reply', 'status_changed')),
  message text,
  from_status text,
  to_status text,
  created_at timestamptz not null default now(),
  unique (ticket_id, sequence_number)
);

create index support_ticket_events_ticket_order_idx
  on public.support_ticket_events (ticket_id, sequence_number);

create table public.support_ticket_attachments (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references public.support_tickets (id) on delete cascade,
  storage_path text not null unique,
  file_name text not null check (char_length(file_name) between 1 and 255),
  mime_type text not null
    check (mime_type in ('image/jpeg', 'image/png', 'image/webp')),
  size_bytes bigint not null check (size_bytes between 1 and 5242880),
  created_at timestamptz not null default now()
);

create index support_ticket_attachments_ticket_idx
  on public.support_ticket_attachments (ticket_id, created_at);

alter table public.chat_conversations enable row level security;
alter table public.chat_messages enable row level security;
alter table public.support_tickets enable row level security;
alter table public.support_ticket_events enable row level security;
alter table public.support_ticket_attachments enable row level security;

revoke all on public.chat_conversations, public.chat_messages,
  public.support_tickets, public.support_ticket_events,
  public.support_ticket_attachments from anon, authenticated;

grant select, insert, update, delete on public.chat_conversations to authenticated;
grant select, insert on public.chat_messages to authenticated;
grant select on public.support_tickets, public.support_ticket_events,
  public.support_ticket_attachments to authenticated;

create policy chat_conversations_owner_all
on public.chat_conversations for all to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

create policy chat_messages_owner_select
on public.chat_messages for select to authenticated
using (
  exists (
    select 1 from public.chat_conversations conversation
    where conversation.id = conversation_id
      and conversation.user_id = (select auth.uid())
  )
);

create policy chat_messages_owner_insert
on public.chat_messages for insert to authenticated
with check (
  exists (
    select 1 from public.chat_conversations conversation
    where conversation.id = conversation_id
      and conversation.user_id = (select auth.uid())
  )
);

create policy support_tickets_related_select
on public.support_tickets for select to authenticated
using (
  user_id = (select auth.uid())
  or public.can_manage_attraction(attraction_id)
);

create policy support_ticket_events_related_select
on public.support_ticket_events for select to authenticated
using (
  exists (
    select 1 from public.support_tickets ticket
    where ticket.id = ticket_id
      and (
        ticket.user_id = (select auth.uid())
        or public.can_manage_attraction(ticket.attraction_id)
      )
  )
);

create policy support_ticket_attachments_related_select
on public.support_ticket_attachments for select to authenticated
using (
  exists (
    select 1 from public.support_tickets ticket
    where ticket.id = ticket_id
      and (
        ticket.user_id = (select auth.uid())
        or public.can_manage_attraction(ticket.attraction_id)
      )
  )
);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'support-ticket-attachments',
  'support-ticket-attachments',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy support_attachments_insert_owner
on storage.objects for insert to authenticated
with check (
  bucket_id = 'support-ticket-attachments'
  and split_part(name, '/', 1) = (select auth.uid())::text
);

create policy support_attachments_select_related
on storage.objects for select to authenticated
using (
  bucket_id = 'support-ticket-attachments'
  and (
    split_part(name, '/', 1) = (select auth.uid())::text
    or exists (
      select 1
      from public.support_ticket_attachments attachment
      join public.support_tickets ticket on ticket.id = attachment.ticket_id
      where attachment.storage_path = name
        and public.can_manage_attraction(ticket.attraction_id)
    )
  )
);

create policy support_attachments_delete_owner
on storage.objects for delete to authenticated
using (
  bucket_id = 'support-ticket-attachments'
  and split_part(name, '/', 1) = (select auth.uid())::text
);

create or replace function public.set_my_preferred_language(p_language text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_language not in ('en', 'ms', 'zh', 'ja', 'ko') then
    raise exception 'Unsupported language';
  end if;

  update public.profiles
  set preferred_language = p_language
  where id = (select auth.uid());

  if not found then
    raise exception 'Profile not found';
  end if;
end;
$$;

create or replace function public.create_support_ticket(
  p_attraction_id uuid,
  p_booking_id uuid,
  p_category text,
  p_subject text,
  p_description text,
  p_source_conversation_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_profile public.profiles;
  selected_attraction public.attractions;
  selected_booking public.bookings;
  selected_booking_code text;
  selected_language text;
  generated_code text;
  created_ticket public.support_tickets;
begin
  if (select auth.uid()) is null then raise exception 'Authentication required'; end if;
  if p_category not in (
    'overcrowding', 'facility_damage', 'safety', 'staff_service', 'other'
  ) then raise exception 'Unsupported category'; end if;
  if char_length(trim(p_subject)) not between 3 and 160 then
    raise exception 'Subject must contain 3 to 160 characters';
  end if;
  if char_length(trim(p_description)) not between 10 and 4000 then
    raise exception 'Description must contain 10 to 4000 characters';
  end if;

  select * into current_profile
  from public.profiles where id = (select auth.uid());
  if not found then raise exception 'Profile not found'; end if;

  select * into selected_attraction
  from public.attractions
  where id = p_attraction_id and listing_status = 'approved';
  if not found then raise exception 'Attraction is unavailable'; end if;

  if p_booking_id is not null then
    select booking.* into selected_booking
    from public.bookings booking
    join public.attraction_slots slot on slot.id = booking.slot_id
    where booking.id = p_booking_id
      and booking.tourist_id = (select auth.uid())
      and slot.attraction_id = p_attraction_id;
    if not found then raise exception 'Booking does not match this attraction'; end if;
    selected_booking_code := selected_booking.booking_code;
  end if;

  if p_source_conversation_id is not null and not exists (
    select 1 from public.chat_conversations conversation
    where conversation.id = p_source_conversation_id
      and conversation.user_id = (select auth.uid())
  ) then raise exception 'Conversation not found'; end if;

  selected_language := coalesce(current_profile.preferred_language, 'en');
  loop
    generated_code := 'TF-' || to_char(now(), 'YYYY') || '-'
      || lpad(floor(random() * 1000000)::integer::text, 6, '0');
    exit when not exists (
      select 1 from public.support_tickets where ticket_code = generated_code
    );
  end loop;

  insert into public.support_tickets (
    ticket_code, user_id, requester_name, attraction_id, attraction_name,
    booking_id, booking_code, category, subject, description, priority,
    submission_language, source_conversation_id
  ) values (
    generated_code, (select auth.uid()), current_profile.full_name,
    selected_attraction.id, selected_attraction.name, p_booking_id,
    selected_booking_code, p_category, trim(p_subject), trim(p_description),
    case when p_category in ('overcrowding', 'safety') then 'urgent' else 'normal' end,
    selected_language, p_source_conversation_id
  ) returning * into created_ticket;

  insert into public.support_ticket_events (
    ticket_id, actor_id, actor_name, actor_role, event_type, message, to_status
  ) values (
    created_ticket.id, (select auth.uid()), current_profile.full_name,
    public.current_user_role()::text, 'created', 'Support ticket created.',
    created_ticket.status
  );

  if p_source_conversation_id is not null then
    insert into public.chat_messages (conversation_id, sender, content)
    values (
      p_source_conversation_id,
      'assistant',
      'Complaint submitted.' || chr(10)
        || 'Ticket ID: ' || created_ticket.ticket_code || chr(10)
        || 'Current status: Pending'
    );

    update public.chat_conversations
    set complaint_draft = null,
      last_message_preview = 'Complaint submitted. Ticket ID: '
        || created_ticket.ticket_code,
      last_message_at = now()
    where id = p_source_conversation_id
      and user_id = (select auth.uid());
  end if;

  return jsonb_build_object(
    'id', created_ticket.id,
    'ticket_code', created_ticket.ticket_code,
    'status', created_ticket.status,
    'confirmation_message', 'Your complaint has been submitted successfully.'
  );
end;
$$;

create or replace function public.add_support_ticket_attachment(
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
  if not exists (
    select 1 from public.support_tickets ticket
    where ticket.id = p_ticket_id and ticket.user_id = (select auth.uid())
  ) then raise exception 'Support ticket not found'; end if;
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
    ticket_id, storage_path, file_name, mime_type, size_bytes
  ) values (
    p_ticket_id, p_storage_path, p_file_name, p_mime_type, p_size_bytes
  ) returning * into created_attachment;
  return created_attachment;
end;
$$;

create or replace function public.reply_to_support_ticket(
  p_ticket_id uuid,
  p_message text
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  selected_ticket public.support_tickets;
  current_profile public.profiles;
  next_status text;
begin
  if char_length(trim(p_message)) not between 1 and 4000 then
    raise exception 'Reply must contain 1 to 4000 characters';
  end if;
  select * into selected_ticket from public.support_tickets
  where id = p_ticket_id for update;
  if not found or not public.can_manage_attraction(selected_ticket.attraction_id) then
    raise exception 'Support ticket not found';
  end if;
  select * into current_profile from public.profiles
  where id = (select auth.uid());
  next_status := case when selected_ticket.status = 'pending'
    then 'in_progress' else selected_ticket.status end;

  update public.support_tickets set
    status = next_status,
    assigned_to = coalesce(assigned_to, (select auth.uid()))
  where id = p_ticket_id;

  insert into public.support_ticket_events (
    ticket_id, actor_id, actor_name, actor_role, event_type, message,
    from_status, to_status
  ) values (
    p_ticket_id, (select auth.uid()), current_profile.full_name,
    public.current_user_role()::text, 'reply', trim(p_message),
    selected_ticket.status, next_status
  );
  return next_status;
end;
$$;

create or replace function public.update_support_ticket_status(
  p_ticket_id uuid,
  p_status text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  selected_ticket public.support_tickets;
  current_profile public.profiles;
begin
  if p_status not in ('pending', 'in_progress', 'resolved') then
    raise exception 'Unsupported status';
  end if;
  select * into selected_ticket from public.support_tickets
  where id = p_ticket_id for update;
  if not found or not public.can_manage_attraction(selected_ticket.attraction_id) then
    raise exception 'Support ticket not found';
  end if;
  if selected_ticket.status = p_status then return; end if;
  select * into current_profile from public.profiles
  where id = (select auth.uid());

  update public.support_tickets set
    status = p_status,
    assigned_to = coalesce(assigned_to, (select auth.uid())),
    resolved_at = case when p_status = 'resolved' then now() else null end
  where id = p_ticket_id;

  insert into public.support_ticket_events (
    ticket_id, actor_id, actor_name, actor_role, event_type, message,
    from_status, to_status
  ) values (
    p_ticket_id, (select auth.uid()), current_profile.full_name,
    public.current_user_role()::text, 'status_changed',
    'Status changed from ' || selected_ticket.status || ' to ' || p_status || '.',
    selected_ticket.status, p_status
  );
end;
$$;

revoke execute on function public.set_my_preferred_language(text),
  public.create_support_ticket(uuid, uuid, text, text, text, uuid),
  public.add_support_ticket_attachment(uuid, text, text, text, bigint),
  public.reply_to_support_ticket(uuid, text),
  public.update_support_ticket_status(uuid, text) from public, anon;

grant execute on function public.set_my_preferred_language(text),
  public.create_support_ticket(uuid, uuid, text, text, text, uuid),
  public.add_support_ticket_attachment(uuid, text, text, text, bigint),
  public.reply_to_support_ticket(uuid, text),
  public.update_support_ticket_status(uuid, text) to authenticated;
