-- Multi-day itineraries keep each day's visits in chronological order.
-- Travel-time validation applies only within a calendar day.
create or replace function public.save_my_itinerary(
  p_itinerary_id uuid, p_title text, p_booking_ids uuid[],
  p_travel_minutes integer[], p_distances_km numeric[], p_uses_road_routes boolean
) returns uuid language plpgsql security invoker set search_path = '' as $$
declare
  v_id uuid; v_count integer := coalesce(cardinality(p_booking_ids), 0); v_day date;
  v_record record; v_previous_end timestamptz; v_previous_start timestamptz;
  v_previous_day date; v_current_day date; v_conflict boolean := false;
  v_minutes integer; v_distance numeric; v_index integer := 0;
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
    insert into public.itineraries(tourist_id,title,itinerary_date,uses_road_routes)
      values(auth.uid(),trim(p_title),v_day,coalesce(p_uses_road_routes,false)) returning id into v_id;
  else
    select id into v_id from public.itineraries where id=p_itinerary_id and tourist_id=auth.uid() for update;
    if v_id is null then raise exception 'ITINERARY_NOT_FOUND'; end if;
    update public.itineraries set title=trim(p_title),itinerary_date=v_day,
      uses_road_routes=coalesce(p_uses_road_routes,false),updated_at=now() where id=v_id;
    delete from public.itinerary_items where itinerary_id=v_id;
  end if;
  for v_record in
    select b.id,s.starts_at,s.ends_at,s.status as slot_status,s.attraction_id,a.listing_status,ci.id as check_in_id
    from unnest(p_booking_ids) with ordinality selected(id,position)
      join public.bookings b on b.id=selected.id
      join public.attraction_slots s on s.id=b.slot_id
      join public.attractions a on a.id=s.attraction_id
      left join public.attraction_check_ins ci on ci.booking_id=b.id
    order by selected.position
  loop
    v_current_day := (v_record.starts_at at time zone 'Asia/Kuala_Lumpur')::date;
    if v_record.starts_at <= now() or v_record.slot_status not in ('open','full')
       or v_record.listing_status <> 'approved' or v_record.check_in_id is not null
       or (v_previous_start is not null and v_record.starts_at < v_previous_start)
       or exists(select 1 from public.closure_periods c where c.attraction_id=v_record.attraction_id
         and tstzrange(c.starts_at,c.ends_at,'[)') && tstzrange(v_record.starts_at,v_record.ends_at,'[)')) then
      raise exception 'ITINERARY_BOOKING_UNAVAILABLE';
    end if;
    v_minutes := case when v_index=0 then null else p_travel_minutes[v_index] end;
    v_distance := case when v_index=0 then null else p_distances_km[v_index] end;
    if v_index > 0 and (v_minutes is null or v_distance is null or v_distance < 0 or v_distance > 10000
      or (v_current_day = v_previous_day and v_minutes not between 15 and 1440)
      or (v_current_day <> v_previous_day and (v_minutes <> 0 or v_distance <> 0))) then
      raise exception 'INVALID_ITINERARY_ROUTE';
    end if;
    if v_previous_end is not null and v_current_day = v_previous_day
       and v_record.starts_at < v_previous_end + make_interval(mins=>v_minutes) then
      v_conflict := true;
    end if;
    insert into public.itinerary_items(itinerary_id,booking_id,position,travel_minutes_from_previous,distance_km_from_previous,safety_buffer_minutes)
      values(v_id,v_record.id,v_index,v_minutes,v_distance,case when v_current_day=v_previous_day then 15 else 0 end);
    v_previous_start := v_record.starts_at; v_previous_end := v_record.ends_at;
    v_previous_day := v_current_day; v_index := v_index+1;
  end loop;
  if v_index <> v_count then raise exception 'ITINERARY_BOOKING_UNAVAILABLE'; end if;
  update public.itineraries set status=case when v_conflict then 'conflict_detected'::public.itinerary_status else 'conflict_free'::public.itinerary_status end where id=v_id;
  return v_id;
end;
$$;
revoke all on function public.save_my_itinerary(uuid,text,uuid[],integer[],numeric[],boolean) from public, anon;
grant execute on function public.save_my_itinerary(uuid,text,uuid[],integer[],numeric[],boolean) to authenticated;
