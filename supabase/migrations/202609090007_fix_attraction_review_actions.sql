-- Fix the management audit trigger used by both operator applications and
-- attractions. Trigger records have different fields: applications use
-- `status`, while attractions use `listing_status`.

create or replace function public.log_management_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  operator_id uuid;
begin
  if tg_table_name = 'operator_applications' then
    if (to_jsonb(new)->>'status') is distinct from (to_jsonb(old)->>'status') then
      insert into public.app_notifications(
        recipient_id, title, message, kind, entity_type, entity_id
      ) values (
        new.applicant_id,
        'Operator application ' || (to_jsonb(new)->>'status'),
        coalesce(
          nullif(to_jsonb(new)->>'review_note', ''),
          'Your application status has changed.'
        ),
        'approval',
        'operator_application',
        new.id
      );

      insert into public.admin_audit_logs(
        actor_id, action, entity_type, entity_id, summary
      ) values (
        (select auth.uid()),
        'application_' || (to_jsonb(new)->>'status'),
        'operator_application',
        new.id,
        'Application status changed.'
      );
    end if;

  elsif tg_table_name = 'attractions' then
    if (to_jsonb(new)->>'listing_status') is distinct from
        (to_jsonb(old)->>'listing_status') then
      for operator_id in
        select user_id
        from public.organization_members
        where organization_id = new.organization_id
          and member_role = 'operator'
          and is_active
      loop
        insert into public.app_notifications(
          recipient_id, title, message, kind, entity_type, entity_id
        ) values (
          operator_id,
          'Attraction ' || (to_jsonb(new)->>'listing_status'),
          coalesce(
            nullif(to_jsonb(new)->>'review_note', ''),
            'The listing status has changed.'
          ),
          'listing',
          'attraction',
          new.id
        );
      end loop;
    end if;

    if to_jsonb(new) is distinct from to_jsonb(old) then
      insert into public.admin_audit_logs(
        actor_id, action, entity_type, entity_id, summary
      ) values (
        (select auth.uid()),
        'attraction_changed',
        'attraction',
        new.id,
        case
          when (to_jsonb(new)->>'listing_status') is distinct from
               (to_jsonb(old)->>'listing_status')
            then 'Listing status changed to ' || (to_jsonb(new)->>'listing_status')
          else 'Attraction details changed.'
        end
      );
    end if;
  end if;

  return new;
end;
$$;

-- Restrict the review workflow to its intended transitions:
-- pending -> approved/rejected, approved -> suspended,
-- suspended -> approved (restore).
create or replace function public.review_attraction(
  target_attraction_id uuid,
  decision public.listing_status,
  note text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_status public.listing_status;
begin
  if not public.is_administrator() then
    raise exception 'Administrator access required';
  end if;

  select listing_status into current_status
  from public.attractions
  where id = target_attraction_id
  for update;

  if not found then
    raise exception 'Attraction not found';
  end if;

  if current_status = 'pending' and decision not in ('approved', 'rejected') then
    raise exception 'A pending attraction can only be approved or rejected';
  elsif current_status = 'approved' and decision <> 'suspended' then
    raise exception 'An approved attraction can only be suspended';
  elsif current_status = 'suspended' and decision <> 'approved' then
    raise exception 'A suspended attraction can only be restored';
  elsif current_status not in ('pending', 'approved', 'suspended') then
    raise exception 'This attraction is not available for review';
  end if;

  update public.attractions
  set listing_status = decision,
      review_note = nullif(trim(note), ''),
      reviewed_by = (select auth.uid()),
      reviewed_at = now()
  where id = target_attraction_id;
end;
$$;

revoke execute on function public.review_attraction(uuid, public.listing_status, text)
  from public, anon;
grant execute on function public.review_attraction(uuid, public.listing_status, text)
  to authenticated;
