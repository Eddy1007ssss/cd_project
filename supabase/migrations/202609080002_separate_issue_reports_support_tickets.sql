-- Keep Module 5 issue reports separate from Module 6 support tickets.
-- Rows imported by the previous migration remain available for audit, but are
-- archived from the support workflow through legacy_issue_report_id.

-- Some environments received the support-ticket schema without the reporting
-- migration that originally introduced this shared authorization helper. Keep
-- this migration self-contained so its policies can always be created.
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

comment on column public.support_tickets.legacy_issue_report_id is
  'Non-null marks an archived copy imported from Module 5 issue reports.';

create index if not exists support_tickets_active_recent_idx
  on public.support_tickets (created_at desc)
  where legacy_issue_report_id is null;

drop policy if exists support_tickets_related_select
  on public.support_tickets;

create policy support_tickets_related_select
on public.support_tickets for select to authenticated
using (
  legacy_issue_report_id is null
  and (
    user_id = (select auth.uid())
    or public.can_manage_attraction(attraction_id)
  )
);

drop policy if exists support_ticket_events_related_select
  on public.support_ticket_events;

create policy support_ticket_events_related_select
on public.support_ticket_events for select to authenticated
using (
  exists (
    select 1 from public.support_tickets ticket
    where ticket.id = ticket_id
      and ticket.legacy_issue_report_id is null
      and (
        ticket.user_id = (select auth.uid())
        or public.can_manage_attraction(ticket.attraction_id)
      )
  )
);

drop policy if exists support_ticket_attachments_related_select
  on public.support_ticket_attachments;

create policy support_ticket_attachments_related_select
on public.support_ticket_attachments for select to authenticated
using (
  exists (
    select 1 from public.support_tickets ticket
    where ticket.id = ticket_id
      and ticket.legacy_issue_report_id is null
      and (
        ticket.user_id = (select auth.uid())
        or public.can_manage_attraction(ticket.attraction_id)
      )
  )
);

drop policy if exists support_attachments_select_related
  on storage.objects;

create policy support_attachments_select_related
on storage.objects for select to authenticated
using (
  bucket_id = 'support-ticket-attachments'
  and exists (
    select 1
    from public.support_ticket_attachments attachment
    join public.support_tickets ticket on ticket.id = attachment.ticket_id
    where attachment.storage_bucket = bucket_id
      and attachment.storage_path = name
      and ticket.legacy_issue_report_id is null
      and (
        ticket.user_id = (select auth.uid())
        or public.can_manage_attraction(ticket.attraction_id)
      )
  )
);

create or replace function public.protect_archived_support_ticket()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if old.legacy_issue_report_id is not null then
    raise exception 'Archived issue-report copies cannot be changed';
  end if;
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

drop trigger if exists support_tickets_protect_archived
  on public.support_tickets;

create trigger support_tickets_protect_archived
before update or delete on public.support_tickets
for each row execute function public.protect_archived_support_ticket();

create or replace function public.require_active_support_ticket_parent()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
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
$$;

drop trigger if exists support_ticket_events_require_active
  on public.support_ticket_events;

create trigger support_ticket_events_require_active
before insert or update on public.support_ticket_events
for each row execute function public.require_active_support_ticket_parent();

drop trigger if exists support_ticket_attachments_require_active
  on public.support_ticket_attachments;

create trigger support_ticket_attachments_require_active
before insert or update on public.support_ticket_attachments
for each row execute function public.require_active_support_ticket_parent();

revoke execute on function public.protect_archived_support_ticket(),
  public.require_active_support_ticket_parent() from public, anon, authenticated;
