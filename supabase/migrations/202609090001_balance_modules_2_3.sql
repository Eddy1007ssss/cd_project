-- Module 2: public rating/live-crowd aggregates.
-- Module 3: privacy-safe, opt-in itinerary publishing.

begin;

create or replace function public.get_public_attraction_insights()
returns table (
  attraction_id uuid,
  average_rating numeric,
  rating_count bigint,
  current_visitors bigint,
  maximum_capacity integer,
  crowd_level text
)
language sql stable security definer set search_path = '' as $$
  select
    attraction.id,
    coalesce(rating.average_rating, 0),
    coalesce(rating.rating_count, 0),
    coalesce(crowd.current_visitors, 0),
    attraction.maximum_capacity,
    case
      when coalesce(crowd.current_visitors, 0) >= attraction.maximum_capacity then 'Critical'
      when coalesce(crowd.current_visitors, 0) * 1.0 / attraction.maximum_capacity >= 0.8 then 'High'
      when coalesce(crowd.current_visitors, 0) * 1.0 / attraction.maximum_capacity >= 0.5 then 'Moderate'
      else 'Low'
    end
  from public.attractions attraction
  left join lateral (
    select round(avg(feedback.overall_rating)::numeric, 2) average_rating,
      count(*) rating_count
    from public.feedback feedback
    where feedback.attraction_id = attraction.id
  ) rating on true
  left join lateral (
    select coalesce(sum(booking.visitor_count), 0)::bigint current_visitors
    from public.attraction_check_ins check_in
    join public.bookings booking on booking.id = check_in.booking_id
    where check_in.attraction_id = attraction.id
      and check_in.checked_out_at is null
  ) crowd on true
  where attraction.listing_status = 'approved'
    and exists (
      select 1 from public.profiles profile
      where profile.id = auth.uid() and profile.status = 'active'
    );
$$;

revoke all on function public.get_public_attraction_insights() from public, anon;
grant execute on function public.get_public_attraction_insights() to authenticated;

create table public.published_itineraries (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  source_itinerary_id uuid not null unique references public.itineraries(id) on delete cascade,
  title text not null check (char_length(trim(title)) between 2 and 120),
  description text not null default '' check (char_length(description) <= 500),
  author_name text,
  itinerary_date date not null,
  published_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.published_itinerary_stops (
  id uuid primary key default gen_random_uuid(),
  published_itinerary_id uuid not null references public.published_itineraries(id) on delete cascade,
  attraction_id uuid not null references public.attractions(id),
  position integer not null check (position >= 0),
  starts_at time not null,
  ends_at time not null,
  travel_minutes_from_previous integer check (travel_minutes_from_previous >= 0),
  distance_km_from_previous numeric(8, 2) check (distance_km_from_previous >= 0),
  unique (published_itinerary_id, position)
);

create index published_itineraries_recent_idx
  on public.published_itineraries(published_at desc);
create index published_itinerary_stops_attraction_idx
  on public.published_itinerary_stops(attraction_id);

alter table public.published_itineraries enable row level security;
alter table public.published_itinerary_stops enable row level security;

revoke all on public.published_itineraries, public.published_itinerary_stops
  from public, anon;
grant select, insert, update, delete on public.published_itineraries,
  public.published_itinerary_stops to authenticated;

create policy published_itineraries_active_read
on public.published_itineraries for select to authenticated
using (exists (
  select 1 from public.profiles profile
  where profile.id = auth.uid() and profile.status = 'active'
));

create policy published_itineraries_owner_insert
on public.published_itineraries for insert to authenticated
with check (
  owner_id = auth.uid()
  and exists (select 1 from public.profiles profile
    where profile.id = auth.uid() and profile.status = 'active' and profile.role = 'tourist')
);

create policy published_itineraries_owner_update
on public.published_itineraries for update to authenticated
using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create policy published_itineraries_owner_delete
on public.published_itineraries for delete to authenticated
using (owner_id = auth.uid());

create policy published_itinerary_stops_active_read
on public.published_itinerary_stops for select to authenticated
using (exists (
  select 1 from public.published_itineraries published
  join public.profiles profile on profile.id = auth.uid()
  where published.id = published_itinerary_id and profile.status = 'active'
));

create policy published_itinerary_stops_owner_insert
on public.published_itinerary_stops for insert to authenticated
with check (exists (
  select 1 from public.published_itineraries published
  where published.id = published_itinerary_id and published.owner_id = auth.uid()
));

create policy published_itinerary_stops_owner_update
on public.published_itinerary_stops for update to authenticated
using (exists (
  select 1 from public.published_itineraries published
  where published.id = published_itinerary_id and published.owner_id = auth.uid()
)) with check (exists (
  select 1 from public.published_itineraries published
  where published.id = published_itinerary_id and published.owner_id = auth.uid()
));

create policy published_itinerary_stops_owner_delete
on public.published_itinerary_stops for delete to authenticated
using (exists (
  select 1 from public.published_itineraries published
  where published.id = published_itinerary_id and published.owner_id = auth.uid()
));

create or replace function public.publish_my_itinerary(
  p_itinerary_id uuid,
  p_description text default '',
  p_show_author boolean default true
)
returns uuid
language plpgsql security invoker set search_path = '' as $$
declare
  selected public.itineraries;
  published_id uuid;
  selected_author text;
begin
  select * into selected from public.itineraries itinerary
  where itinerary.id = p_itinerary_id and itinerary.tourist_id = auth.uid();

  if selected.id is null then raise exception 'ITINERARY_NOT_FOUND'; end if;
  if char_length(coalesce(p_description, '')) > 500 then
    raise exception 'DESCRIPTION_TOO_LONG';
  end if;
  if not exists (select 1 from public.itinerary_items item
    where item.itinerary_id = selected.id) then
    raise exception 'ITINERARY_EMPTY';
  end if;

  if coalesce(p_show_author, true) then
    select profile.full_name into selected_author
    from public.profiles profile where profile.id = auth.uid();
  end if;

  insert into public.published_itineraries(
    owner_id, source_itinerary_id, title, description, author_name, itinerary_date
  ) values (
    auth.uid(), selected.id, selected.title, trim(coalesce(p_description, '')),
    selected_author, selected.itinerary_date
  )
  on conflict (source_itinerary_id) do update set
    title = excluded.title,
    description = excluded.description,
    author_name = excluded.author_name,
    itinerary_date = excluded.itinerary_date,
    updated_at = now()
  returning id into published_id;

  delete from public.published_itinerary_stops stop
  where stop.published_itinerary_id = published_id;

  insert into public.published_itinerary_stops(
    published_itinerary_id, attraction_id, position, starts_at, ends_at,
    travel_minutes_from_previous, distance_km_from_previous
  )
  select published_id, slot.attraction_id, item.position,
    (slot.starts_at at time zone 'Asia/Kuala_Lumpur')::time,
    (slot.ends_at at time zone 'Asia/Kuala_Lumpur')::time,
    item.travel_minutes_from_previous, item.distance_km_from_previous
  from public.itinerary_items item
  join public.bookings booking on booking.id = item.booking_id
  join public.attraction_slots slot on slot.id = booking.slot_id
  join public.attractions attraction on attraction.id = slot.attraction_id
  where item.itinerary_id = selected.id
    and booking.tourist_id = auth.uid()
    and attraction.listing_status = 'approved'
  order by item.position;

  if not exists (select 1 from public.published_itinerary_stops stop
    where stop.published_itinerary_id = published_id) then
    raise exception 'ITINERARY_EMPTY';
  end if;
  return published_id;
end;
$$;

create or replace function public.unpublish_my_itinerary(p_itinerary_id uuid)
returns void language sql security invoker set search_path = '' as $$
  delete from public.published_itineraries published
  where published.source_itinerary_id = p_itinerary_id
    and published.owner_id = auth.uid();
$$;

revoke all on function public.publish_my_itinerary(uuid, text, boolean) from public, anon;
revoke all on function public.unpublish_my_itinerary(uuid) from public, anon;
grant execute on function public.publish_my_itinerary(uuid, text, boolean) to authenticated;
grant execute on function public.unpublish_my_itinerary(uuid) to authenticated;

commit;
