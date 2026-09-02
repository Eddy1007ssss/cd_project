-- TourFlow Module 2 only. Apply after Module 1 and Module 3 migrations.

create table public.tourist_discovery_preferences (
  tourist_id uuid primary key references public.profiles (id) on delete cascade,
  interests text[] not null default '{}',
  max_budget_myr numeric(10, 2) check (max_budget_myr is null or max_budget_myr >= 0),
  preferred_location text,
  preferred_latitude double precision check (preferred_latitude is null or preferred_latitude between -90 and 90),
  preferred_longitude double precision check (preferred_longitude is null or preferred_longitude between -180 and 180),
  travel_radius_km numeric(6, 2) not null default 10 check (travel_radius_km > 0 and travel_radius_km <= 200),
  preferred_crowd_level text not null default 'moderate'
    check (preferred_crowd_level in ('low', 'moderate', 'high', 'critical')),
  preferred_visit_start time not null default time '09:00',
  preferred_visit_end time not null default time '17:00',
  required_facilities text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint valid_preferred_visit_period check (preferred_visit_start < preferred_visit_end)
);

create table public.attraction_interest_tags (
  attraction_id uuid not null references public.attractions (id) on delete cascade,
  tag text not null check (char_length(trim(tag)) between 2 and 50 and tag = lower(trim(tag))),
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default now(),
  primary key (attraction_id, tag)
);

create table public.recommendation_impressions (
  id uuid primary key default gen_random_uuid(),
  tourist_id uuid not null references public.profiles (id) on delete cascade,
  attraction_id uuid not null references public.attractions (id) on delete cascade,
  slot_id uuid references public.attraction_slots (id) on delete set null,
  recommendation_score numeric(6, 2) not null check (recommendation_score between 0 and 100),
  reason text not null,
  context jsonb not null default '{}',
  shown_at timestamptz not null default now(),
  selected_at timestamptz
);

create index recommendation_impressions_tourist_idx
  on public.recommendation_impressions (tourist_id, shown_at desc);

create trigger tourist_discovery_preferences_set_updated_at
before update on public.tourist_discovery_preferences
for each row execute function public.set_updated_at();

alter table public.tourist_discovery_preferences enable row level security;
alter table public.attraction_interest_tags enable row level security;
alter table public.recommendation_impressions enable row level security;

revoke all on public.tourist_discovery_preferences, public.attraction_interest_tags,
  public.recommendation_impressions from anon, authenticated;
grant select, insert, update, delete on public.tourist_discovery_preferences to authenticated;
grant select, insert, update, delete on public.attraction_interest_tags to authenticated;
grant select, insert, update on public.recommendation_impressions to authenticated;

create policy discovery_preferences_owner_all
on public.tourist_discovery_preferences for all to authenticated
using (tourist_id = (select auth.uid()) or public.is_administrator())
with check (tourist_id = (select auth.uid()) or public.is_administrator());

create policy attraction_interest_tags_select_visible
on public.attraction_interest_tags for select to authenticated
using (
  exists (
    select 1 from public.attractions attraction
    where attraction.id = attraction_id
      and (
        attraction.listing_status = 'approved'
        or public.is_organization_member(attraction.organization_id)
        or public.is_administrator()
      )
  )
);

create policy attraction_interest_tags_manage_owner
on public.attraction_interest_tags for all to authenticated
using (
  exists (
    select 1 from public.attractions attraction
    where attraction.id = attraction_id
      and (
        public.is_organization_member(attraction.organization_id)
        or public.is_administrator()
      )
  )
)
with check (
  created_by = (select auth.uid())
  and exists (
    select 1 from public.attractions attraction
    where attraction.id = attraction_id
      and (
        public.is_organization_member(attraction.organization_id)
        or public.is_administrator()
      )
  )
);

create policy recommendation_impressions_owner_select
on public.recommendation_impressions for select to authenticated
using (tourist_id = (select auth.uid()) or public.is_administrator());

create policy recommendation_impressions_owner_insert
on public.recommendation_impressions for insert to authenticated
with check (tourist_id = (select auth.uid()));

create policy recommendation_impressions_owner_update
on public.recommendation_impressions for update to authenticated
using (tourist_id = (select auth.uid()))
with check (tourist_id = (select auth.uid()));
