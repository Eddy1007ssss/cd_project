-- Follow-up for the Module 2/3 balance migration: cache auth.uid() in RLS
-- expressions and cover the published-itinerary owner foreign key.

begin;

create index published_itineraries_owner_idx
  on public.published_itineraries(owner_id);

drop policy published_itineraries_active_read on public.published_itineraries;
create policy published_itineraries_active_read
on public.published_itineraries for select to authenticated
using (exists (
  select 1 from public.profiles profile
  where profile.id = (select auth.uid()) and profile.status = 'active'
));

drop policy published_itineraries_owner_insert on public.published_itineraries;
create policy published_itineraries_owner_insert
on public.published_itineraries for insert to authenticated
with check (
  owner_id = (select auth.uid())
  and exists (select 1 from public.profiles profile
    where profile.id = (select auth.uid())
      and profile.status = 'active' and profile.role = 'tourist')
);

drop policy published_itineraries_owner_update on public.published_itineraries;
create policy published_itineraries_owner_update
on public.published_itineraries for update to authenticated
using (owner_id = (select auth.uid()))
with check (owner_id = (select auth.uid()));

drop policy published_itineraries_owner_delete on public.published_itineraries;
create policy published_itineraries_owner_delete
on public.published_itineraries for delete to authenticated
using (owner_id = (select auth.uid()));

drop policy published_itinerary_stops_active_read
  on public.published_itinerary_stops;
create policy published_itinerary_stops_active_read
on public.published_itinerary_stops for select to authenticated
using (exists (
  select 1 from public.published_itineraries published
  join public.profiles profile on profile.id = (select auth.uid())
  where published.id = published_itinerary_id and profile.status = 'active'
));

drop policy published_itinerary_stops_owner_insert
  on public.published_itinerary_stops;
create policy published_itinerary_stops_owner_insert
on public.published_itinerary_stops for insert to authenticated
with check (exists (
  select 1 from public.published_itineraries published
  where published.id = published_itinerary_id
    and published.owner_id = (select auth.uid())
));

drop policy published_itinerary_stops_owner_update
  on public.published_itinerary_stops;
create policy published_itinerary_stops_owner_update
on public.published_itinerary_stops for update to authenticated
using (exists (
  select 1 from public.published_itineraries published
  where published.id = published_itinerary_id
    and published.owner_id = (select auth.uid())
)) with check (exists (
  select 1 from public.published_itineraries published
  where published.id = published_itinerary_id
    and published.owner_id = (select auth.uid())
));

drop policy published_itinerary_stops_owner_delete
  on public.published_itinerary_stops;
create policy published_itinerary_stops_owner_delete
on public.published_itinerary_stops for delete to authenticated
using (exists (
  select 1 from public.published_itineraries published
  where published.id = published_itinerary_id
    and published.owner_id = (select auth.uid())
));

commit;
