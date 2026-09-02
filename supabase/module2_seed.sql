-- Apply after the shared Module 1/3 seed and Module 2 migration.
do $$
declare
  tourist_user uuid;
  operator_user uuid;
begin
  select id into tourist_user from auth.users where lower(email) = 'tourist@tourflow.test';
  select id into operator_user from auth.users where lower(email) = 'operator@tourflow.test';
  if tourist_user is null or operator_user is null then
    raise exception 'Create the shared tourist and operator demo users first.';
  end if;

  insert into public.tourist_discovery_preferences (
    tourist_id, interests, max_budget_myr, preferred_location,
    preferred_latitude, preferred_longitude, travel_radius_km,
    preferred_crowd_level, preferred_visit_start, preferred_visit_end,
    required_facilities
  ) values (
    tourist_user, array['history', 'nature', 'culture'], 40,
    'Dataran Merdeka, Kuala Lumpur', 3.1478, 101.6937, 15,
    'moderate', time '09:00', time '17:00', array['Restrooms']
  ) on conflict (tourist_id) do update set
    interests = excluded.interests,
    max_budget_myr = excluded.max_budget_myr,
    preferred_location = excluded.preferred_location,
    preferred_latitude = excluded.preferred_latitude,
    preferred_longitude = excluded.preferred_longitude,
    travel_radius_km = excluded.travel_radius_km,
    preferred_crowd_level = excluded.preferred_crowd_level,
    preferred_visit_start = excluded.preferred_visit_start,
    preferred_visit_end = excluded.preferred_visit_end,
    required_facilities = excluded.required_facilities;

  insert into public.attraction_interest_tags (attraction_id, tag, created_by)
  values
    ('10000000-0000-0000-0000-000000000001', 'architecture', operator_user),
    ('10000000-0000-0000-0000-000000000001', 'culture', operator_user),
    ('10000000-0000-0000-0000-000000000001', 'history', operator_user),
    ('10000000-0000-0000-0000-000000000002', 'art', operator_user),
    ('10000000-0000-0000-0000-000000000002', 'culture', operator_user),
    ('10000000-0000-0000-0000-000000000002', 'family', operator_user),
    ('10000000-0000-0000-0000-000000000003', 'nature', operator_user),
    ('10000000-0000-0000-0000-000000000003', 'photography', operator_user),
    ('10000000-0000-0000-0000-000000000003', 'walking', operator_user)
  on conflict (attraction_id, tag) do update set created_by = excluded.created_by;
end $$;
