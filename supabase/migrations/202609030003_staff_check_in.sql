-- Staff-only booking verification and atomic QR check-in.

create function public.verify_staff_booking(lookup_value text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare normalized_value text := upper(trim(coalesce(lookup_value, '')));
declare selected_record record;
declare current_visitors integer;
declare result_status text;
begin
  if not exists (
    select 1 from public.profiles profile
    where profile.id = (select auth.uid()) and profile.role = 'staff'
      and profile.status = 'active'
  ) or not exists (
    select 1 from public.organization_members member
    where member.user_id = (select auth.uid()) and member.member_role = 'staff'
      and member.is_active
  ) then raise exception 'STAFF_ACCESS_DENIED' using errcode = '42501'; end if;

  if normalized_value = '' then return jsonb_build_object('status', 'invalid'); end if;

  select booking.id as booking_id, booking.booking_code,
    booking.status as booking_status, booking.visitor_count,
    tourist.full_name as visitor_name, slot.starts_at, slot.ends_at,
    slot.status as slot_status, attraction.id as attraction_id,
    attraction.organization_id, attraction.name as attraction_name,
    attraction.listing_status, attraction.maximum_capacity
  into selected_record
  from public.bookings booking
  join public.profiles tourist on tourist.id = booking.tourist_id
  join public.attraction_slots slot on slot.id = booking.slot_id
  join public.attractions attraction on attraction.id = slot.attraction_id
  where upper(booking.booking_code) = normalized_value
    or booking.qr_token::text = lower(normalized_value)
  limit 1;

  if selected_record.booking_id is null then
    return jsonb_build_object('status', 'invalid');
  end if;
  if not exists (
    select 1 from public.organization_members member
    where member.user_id = (select auth.uid())
      and member.organization_id = selected_record.organization_id
      and member.member_role = 'staff' and member.is_active
  ) then return jsonb_build_object('status', 'wrong_attraction'); end if;

  select coalesce(sum(booking.visitor_count), 0)::integer into current_visitors
  from public.attraction_check_ins check_in
  join public.bookings booking on booking.id = check_in.booking_id
  where check_in.attraction_id = selected_record.attraction_id
    and check_in.checked_out_at is null;

  if exists (
    select 1 from public.attraction_check_ins check_in
    where check_in.booking_id = selected_record.booking_id
  ) then result_status := 'already_used';
  elsif selected_record.booking_status <> 'confirmed'
    or selected_record.listing_status <> 'approved' then result_status := 'invalid';
  elsif selected_record.slot_status not in ('open', 'full')
    or now() < selected_record.starts_at - interval '30 minutes'
    or now() > selected_record.ends_at
    or current_visitors + selected_record.visitor_count
      > selected_record.maximum_capacity
    or exists (
      select 1 from public.closure_periods closure
      where closure.attraction_id = selected_record.attraction_id
        and now() >= closure.starts_at and now() < closure.ends_at
    ) then result_status := 'wrong_slot';
  else result_status := 'valid';
  end if;

  return jsonb_build_object(
    'status', result_status, 'booking_id', selected_record.booking_id,
    'booking_code', selected_record.booking_code,
    'visitor_name', selected_record.visitor_name,
    'visitor_count', selected_record.visitor_count,
    'attraction_name', selected_record.attraction_name,
    'starts_at', selected_record.starts_at, 'ends_at', selected_record.ends_at,
    'current_visitor_count', current_visitors
  );
end;
$$;

create function public.confirm_staff_check_in(target_booking_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare selected_record record;
declare current_visitors integer;
declare result_status text;
begin
  if not exists (
    select 1 from public.profiles profile
    where profile.id = (select auth.uid()) and profile.role = 'staff'
      and profile.status = 'active'
  ) or not exists (
    select 1 from public.organization_members member
    where member.user_id = (select auth.uid()) and member.member_role = 'staff'
      and member.is_active
  ) then raise exception 'STAFF_ACCESS_DENIED' using errcode = '42501'; end if;

  select booking.id as booking_id, booking.booking_code,
    booking.status as booking_status, booking.tourist_id, booking.visitor_count,
    tourist.full_name as visitor_name, slot.starts_at, slot.ends_at,
    slot.status as slot_status, attraction.id as attraction_id,
    attraction.organization_id, attraction.name as attraction_name,
    attraction.listing_status, attraction.maximum_capacity
  into selected_record
  from public.bookings booking
  join public.profiles tourist on tourist.id = booking.tourist_id
  join public.attraction_slots slot on slot.id = booking.slot_id
  join public.attractions attraction on attraction.id = slot.attraction_id
  where booking.id = target_booking_id
  for update of booking;

  if selected_record.booking_id is null then
    return jsonb_build_object('status', 'invalid');
  end if;
  if not exists (
    select 1 from public.organization_members member
    where member.user_id = (select auth.uid())
      and member.organization_id = selected_record.organization_id
      and member.member_role = 'staff' and member.is_active
  ) then return jsonb_build_object('status', 'wrong_attraction'); end if;

  perform pg_advisory_xact_lock(hashtextextended(selected_record.attraction_id::text, 0));
  select coalesce(sum(booking.visitor_count), 0)::integer into current_visitors
  from public.attraction_check_ins check_in
  join public.bookings booking on booking.id = check_in.booking_id
  where check_in.attraction_id = selected_record.attraction_id
    and check_in.checked_out_at is null;

  if exists (
    select 1 from public.attraction_check_ins check_in
    where check_in.booking_id = selected_record.booking_id
  ) then result_status := 'already_used';
  elsif selected_record.booking_status <> 'confirmed'
    or selected_record.listing_status <> 'approved' then result_status := 'invalid';
  elsif selected_record.slot_status not in ('open', 'full')
    or now() < selected_record.starts_at - interval '30 minutes'
    or now() > selected_record.ends_at
    or current_visitors + selected_record.visitor_count
      > selected_record.maximum_capacity
    or exists (
      select 1 from public.closure_periods closure
      where closure.attraction_id = selected_record.attraction_id
        and now() >= closure.starts_at and now() < closure.ends_at
    ) then result_status := 'wrong_slot';
  else
    insert into public.attraction_check_ins
      (booking_id, tourist_id, attraction_id, distance_m, source)
    values (selected_record.booking_id, selected_record.tourist_id,
      selected_record.attraction_id, 0, 'staff_scan');
    current_visitors := current_visitors + selected_record.visitor_count;
    result_status := 'checked_in';
  end if;

  return jsonb_build_object(
    'status', result_status, 'booking_id', selected_record.booking_id,
    'booking_code', selected_record.booking_code,
    'visitor_name', selected_record.visitor_name,
    'visitor_count', selected_record.visitor_count,
    'attraction_name', selected_record.attraction_name,
    'starts_at', selected_record.starts_at, 'ends_at', selected_record.ends_at,
    'current_visitor_count', current_visitors
  );
end;
$$;

revoke execute on function public.verify_staff_booking(text) from public, anon;
revoke execute on function public.confirm_staff_check_in(uuid) from public, anon;
grant execute on function public.verify_staff_booking(text) to authenticated;
grant execute on function public.confirm_staff_check_in(uuid) to authenticated;
