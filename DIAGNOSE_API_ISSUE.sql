-- =====================================================
-- DIAGNOSE API ISSUE
-- =====================================================
-- This script helps diagnose the teacher creation API issue

-- Check current database state
SELECT 'Current database state:' as info;

-- Check if we have schools
SELECT 
  'Schools in database:' as table_name,
  COUNT(*) as count
FROM public.school_settings;

-- Show schools
SELECT 
  id,
  school_name,
  email
FROM public.school_settings
ORDER BY school_name;

-- Check if we have the staff record that was created
SELECT 
  'Staff records:' as table_name,
  COUNT(*) as count
FROM public.staff;

-- Show staff records
SELECT 
  id,
  staff_id,
  full_name,
  position,
  email,
  school_id
FROM public.staff
ORDER BY full_name;

-- Check users table
SELECT 
  'Users in database:' as table_name,
  COUNT(*) as count
FROM public.users;

-- Show users
SELECT 
  id,
  email,
  role,
  full_name,
  school_id
FROM public.users
ORDER BY full_name;

-- Check if Daniel Gyan exists in staff but not in users
SELECT 
  s.full_name,
  s.staff_id,
  s.email,
  s.position,
  CASE WHEN u.id IS NOT NULL THEN 'Has Login Account' ELSE 'No Login Account' END as login_status
FROM public.staff s
LEFT JOIN public.users u ON u.full_name = s.full_name AND u.school_id = s.school_id
WHERE s.full_name ILIKE '%daniel%gyan%'
ORDER BY s.full_name;

-- Show what the next steps should be
SELECT 
  '🔍 DIAGNOSIS COMPLETE' as result,
  'Check if Daniel Gyan appears in staff table but not users table' as check1,
  'If so, the API call failed but staff record was created' as check2,
  'This means the server route has an issue' as check3;