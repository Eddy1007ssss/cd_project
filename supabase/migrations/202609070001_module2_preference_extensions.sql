-- Module 2 preference fields used by the final discovery experience.

alter table public.tourist_discovery_preferences
  add column if not exists min_budget_myr numeric(10, 2) not null default 0,
  add column if not exists accessibility_needs text[] not null default '{}',
  add column if not exists environment_preference text not null default 'both',
  add column if not exists travelling_type text not null default 'solo';

alter table public.tourist_discovery_preferences
  drop constraint if exists tourist_preferences_min_budget_valid,
  drop constraint if exists tourist_preferences_budget_range_valid,
  drop constraint if exists tourist_preferences_environment_valid,
  drop constraint if exists tourist_preferences_travelling_type_valid;

alter table public.tourist_discovery_preferences
  add constraint tourist_preferences_min_budget_valid
    check (min_budget_myr >= 0),
  add constraint tourist_preferences_budget_range_valid
    check (max_budget_myr is null or min_budget_myr <= max_budget_myr),
  add constraint tourist_preferences_environment_valid
    check (environment_preference in ('indoor', 'outdoor', 'both')),
  add constraint tourist_preferences_travelling_type_valid
    check (travelling_type in ('solo', 'family', 'group'));
