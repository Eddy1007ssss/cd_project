-- TourFlow tutor-demo data for Modules 1 and 3.
-- Run after migrations 001 and 002 and after creating the four dashboard users
-- listed in supabase/README.md. Passwords are deliberately not stored here.

do $$
declare
  tourist_user uuid;
  operator_user uuid;
  staff_user uuid;
  admin_user uuid;
  demo_org constant uuid := '20000000-0000-0000-0000-000000000001';
begin
  select id into tourist_user from auth.users where lower(email) = 'tourist@tourflow.test';
  select id into operator_user from auth.users where lower(email) = 'operator@tourflow.test';
  select id into staff_user from auth.users where lower(email) = 'staff@tourflow.test';
  select id into admin_user from auth.users where lower(email) = 'admin@tourflow.test';

  if tourist_user is null or operator_user is null or staff_user is null or admin_user is null then
    raise exception 'Create tourist@tourflow.test, operator@tourflow.test, staff@tourflow.test and admin@tourflow.test in Authentication > Users first.';
  end if;

  update public.profiles set full_name = 'Alyssa Demo Tourist', phone = '+60123456789', role = 'tourist', status = 'active' where id = tourist_user;
  update public.profiles set full_name = 'KL Heritage Operator', phone = '+60111222333', role = 'operator', status = 'active' where id = operator_user;
  update public.profiles set full_name = 'TourFlow Check-In Staff', phone = '+60112223344', role = 'staff', status = 'active' where id = staff_user;
  update public.profiles set full_name = 'TourFlow Administrator', phone = '+60113334455', role = 'administrator', status = 'active' where id = admin_user;

  insert into public.operator_organizations (id, name, registration_number, email, phone, address)
  values (demo_org, 'Kuala Lumpur Heritage Experiences', 'KLHE-2026-001', 'operator@tourflow.test', '+60321810001', 'Dataran Merdeka, 50050 Kuala Lumpur')
  on conflict (id) do update set name = excluded.name, email = excluded.email, phone = excluded.phone, is_active = true;

  insert into public.organization_members (organization_id, user_id, member_role, is_active)
  values
    (demo_org, operator_user, 'operator', true),
    (demo_org, staff_user, 'staff', true)
  on conflict (organization_id, user_id) do update set member_role = excluded.member_role, is_active = true;

  insert into public.attractions (
    id, organization_id, created_by, name, description, category,
    location_name, address, latitude, longitude, entrance_price_myr,
    facilities, visitor_guidelines, attraction_rules, attraction_type,
    maximum_capacity, geofence_radius_metres, listing_status, cover_image_url
  ) values
  (
    '10000000-0000-0000-0000-000000000001', demo_org, operator_user,
    'Merdeka Heritage Walk', 'A guided visit around Dataran Merdeka and Kuala Lumpur''s colonial-era landmarks.',
    'Historical Landmark', 'Kuala Lumpur', 'Dataran Merdeka, Jalan Raja, 50050 Kuala Lumpur',
    3.1478, 101.6937, 25.00, array['Guided tour', 'Restrooms', 'Wheelchair access'],
    'Arrive 10 minutes before the selected slot.', 'Stay with the guide and respect restricted areas.',
    'outdoor', 120, 180, 'approved',
    'https://images.unsplash.com/photo-1596422846543-75c6fc197f07?auto=format&fit=crop&w=1200&q=80'
  ),
  (
    '10000000-0000-0000-0000-000000000002', demo_org, operator_user,
    'Islamic Arts Museum Malaysia', 'A curated indoor collection of Islamic decorative arts near Perdana Botanical Gardens.',
    'Museum', 'Kuala Lumpur', 'Jalan Lembah Perdana, 50480 Kuala Lumpur',
    3.1415, 101.6890, 20.00, array['Air conditioning', 'Cafe', 'Prayer room', 'Wheelchair access'],
    'Large bags should be stored at the visitor counter.', 'No flash photography in marked galleries.',
    'indoor', 180, null, 'approved',
    'https://images.unsplash.com/photo-1564399579883-451a5d44ec08?auto=format&fit=crop&w=1200&q=80'
  ),
  (
    '10000000-0000-0000-0000-000000000003', demo_org, operator_user,
    'KL Forest Eco Park', 'A city-centre rainforest experience with canopy walks and native flora.',
    'Nature', 'Kuala Lumpur', 'Jalan Puncak, 50250 Kuala Lumpur',
    3.1526, 101.7048, 10.00, array['Canopy walk', 'Restrooms', 'Information centre'],
    'Wear suitable walking shoes and bring drinking water.', 'Outdoor paths may close during severe weather.',
    'outdoor', 150, 250, 'approved',
    'https://images.unsplash.com/photo-1511497584788-876760111969?auto=format&fit=crop&w=1200&q=80'
  )
  on conflict (id) do update set
    name = excluded.name, description = excluded.description, category = excluded.category,
    location_name = excluded.location_name, address = excluded.address,
    latitude = excluded.latitude, longitude = excluded.longitude,
    entrance_price_myr = excluded.entrance_price_myr, facilities = excluded.facilities,
    listing_status = 'approved', cover_image_url = excluded.cover_image_url;

  insert into public.operating_hours (attraction_id, day_of_week, is_closed, opens_at, closes_at)
  select attraction_id, day_number, false, time '09:00', time '18:00'
  from (values
    ('10000000-0000-0000-0000-000000000001'::uuid),
    ('10000000-0000-0000-0000-000000000002'::uuid),
    ('10000000-0000-0000-0000-000000000003'::uuid)
  ) attractions(attraction_id)
  cross join generate_series(0, 6) day_number
  on conflict (attraction_id, day_of_week) do update set is_closed = false, opens_at = excluded.opens_at, closes_at = excluded.closes_at;

  insert into public.attraction_slots (id, attraction_id, starts_at, ends_at, maximum_capacity, status, created_by)
  values
    ('30000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', ((current_date + 1)::text || ' 09:00 Asia/Kuala_Lumpur')::timestamptz, ((current_date + 1)::text || ' 10:30 Asia/Kuala_Lumpur')::timestamptz, 40, 'open', operator_user),
    ('30000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', ((current_date + 1)::text || ' 11:00 Asia/Kuala_Lumpur')::timestamptz, ((current_date + 1)::text || ' 12:30 Asia/Kuala_Lumpur')::timestamptz, 30, 'open', operator_user),
    ('30000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001', ((current_date + 1)::text || ' 14:00 Asia/Kuala_Lumpur')::timestamptz, ((current_date + 1)::text || ' 15:30 Asia/Kuala_Lumpur')::timestamptz, 20, 'full', operator_user),
    ('30000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000001', ((current_date + 2)::text || ' 09:00 Asia/Kuala_Lumpur')::timestamptz, ((current_date + 2)::text || ' 10:30 Asia/Kuala_Lumpur')::timestamptz, 40, 'open', operator_user),
    ('30000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000001', ((current_date + 3)::text || ' 09:00 Asia/Kuala_Lumpur')::timestamptz, ((current_date + 3)::text || ' 10:30 Asia/Kuala_Lumpur')::timestamptz, 40, 'closed', operator_user),
    ('30000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000002', ((current_date + 2)::text || ' 12:00 Asia/Kuala_Lumpur')::timestamptz, ((current_date + 2)::text || ' 13:30 Asia/Kuala_Lumpur')::timestamptz, 60, 'open', operator_user),
    ('30000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000002', ((current_date + 1)::text || ' 10:00 Asia/Kuala_Lumpur')::timestamptz, ((current_date + 1)::text || ' 11:30 Asia/Kuala_Lumpur')::timestamptz, 60, 'open', operator_user),
    ('30000000-0000-0000-0000-000000000008', '10000000-0000-0000-0000-000000000003', ((current_date + 1)::text || ' 16:00 Asia/Kuala_Lumpur')::timestamptz, ((current_date + 1)::text || ' 17:30 Asia/Kuala_Lumpur')::timestamptz, 50, 'open', operator_user),
    ('30000000-0000-0000-0000-000000000009', '10000000-0000-0000-0000-000000000001', ((current_date - 7)::text || ' 09:00 Asia/Kuala_Lumpur')::timestamptz, ((current_date - 7)::text || ' 10:30 Asia/Kuala_Lumpur')::timestamptz, 40, 'expired', operator_user)
  on conflict (id) do update set
    starts_at = excluded.starts_at, ends_at = excluded.ends_at,
    maximum_capacity = excluded.maximum_capacity, status = excluded.status,
    created_by = excluded.created_by;

  insert into public.closure_periods (id, attraction_id, starts_at, ends_at, closure_type, reason, created_by)
  values ('40000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', ((current_date + 3)::text || ' 00:00 Asia/Kuala_Lumpur')::timestamptz, ((current_date + 4)::text || ' 00:00 Asia/Kuala_Lumpur')::timestamptz, 'maintenance', 'Scheduled conservation maintenance', operator_user)
  on conflict (id) do update set starts_at = excluded.starts_at, ends_at = excluded.ends_at, reason = excluded.reason;

  insert into public.bookings (id, tourist_id, slot_id, visitor_count, booking_code, qr_token, status, completed_at)
  values
    ('50000000-0000-0000-0000-000000000001', tourist_user, '30000000-0000-0000-0000-000000000004', 2, 'TF-DEMO-UP1', '60000000-0000-0000-0000-000000000001', 'confirmed', null),
    ('50000000-0000-0000-0000-000000000002', tourist_user, '30000000-0000-0000-0000-000000000006', 2, 'TF-DEMO-UP2', '60000000-0000-0000-0000-000000000002', 'confirmed', null),
    ('50000000-0000-0000-0000-000000000003', tourist_user, '30000000-0000-0000-0000-000000000009', 1, 'TF-DEMO-PAST', '60000000-0000-0000-0000-000000000003', 'completed', ((current_date - 7)::text || ' 11:00 Asia/Kuala_Lumpur')::timestamptz),
    ('50000000-0000-0000-0000-000000000004', tourist_user, '30000000-0000-0000-0000-000000000007', 1, 'TF-DEMO-CAN', '60000000-0000-0000-0000-000000000004', 'cancelled', null)
  on conflict (id) do update set tourist_id = excluded.tourist_id, slot_id = excluded.slot_id, visitor_count = excluded.visitor_count, status = excluded.status, completed_at = excluded.completed_at;

  update public.attraction_slots slot
  set reserved_capacity = case
        when slot.id = '30000000-0000-0000-0000-000000000003' then slot.maximum_capacity
        else coalesce((select sum(booking.visitor_count) from public.bookings booking where booking.slot_id = slot.id and booking.status = 'confirmed'), 0)
      end,
      status = case
        when slot.id = '30000000-0000-0000-0000-000000000003' then 'full'::public.slot_status
        when slot.id = '30000000-0000-0000-0000-000000000005' then 'closed'::public.slot_status
        when slot.id = '30000000-0000-0000-0000-000000000009' then 'expired'::public.slot_status
        else 'open'::public.slot_status
      end
  where slot.id::text like '30000000-0000-0000-0000-00000000000%';
end $$;
