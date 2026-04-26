-- =====================================================
-- UPDATE USER METADATA WITH SCHOOL_ID
-- =====================================================
-- Use this to add school_id to existing admin users
-- Run this in Supabase SQL Editor

-- =====================================================
-- STEP 1: GET YOUR SCHOOL_ID
-- =====================================================
-- First, find your school_id
SELECT id, school_name FROM public.school_settings;

-- Copy the 'id' value from the result
-- Example: a1b2c3d4-e5f6-7890-abcd-ef1234567890

-- =====================================================
-- STEP 2: UPDATE USER METADATA
-- =====================================================
-- Replace 'admin@moma.edu.gh' with your admin email
-- Replace 'YOUR_SCHOOL_ID_HERE' with the id from Step 1

UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
  COALESCE(raw_user_meta_data, '{}'::jsonb),
  '{school_id}',
  '"YOUR_SCHOOL_ID_HERE"'::jsonb
)
WHERE email = 'admin@moma.edu.gh';

-- =====================================================
-- STEP 3: VERIFY THE UPDATE
-- =====================================================
-- Check that the metadata was updated
SELECT 
  email,
  raw_user_meta_data->>'full_name' as full_name,
  raw_user_meta_data->>'role' as role,
  raw_user_meta_data->>'school_id' as school_id
FROM auth.users
WHERE email = 'admin@moma.edu.gh';

-- =====================================================
-- STEP 4: TRIGGER USER PROFILE UPDATE
-- =====================================================
-- The handle_new_user trigger should automatically update
-- the public.users table, but let's verify:

SELECT 
  u.email,
  u.full_name,
  u.role,
  u.school_id,
  s.school_name
FROM public.users u
LEFT JOIN public.school_settings s ON u.school_id = s.id
WHERE u.email = 'admin@moma.edu.gh';

-- If school_id is NULL in public.users, manually update it:
UPDATE public.users
SET school_id = 'YOUR_SCHOOL_ID_HERE'::UUID
WHERE email = 'admin@moma.edu.gh';

-- =====================================================
-- COMPLETE EXAMPLE (Copy and modify this)
-- =====================================================

-- Example for MOMA School:

-- 1. Get school_id
SELECT id, school_name FROM public.school_settings WHERE school_name = 'MOMA School';
-- Let's say it returns: a1b2c3d4-e5f6-7890-abcd-ef1234567890

-- 2. Update auth.users metadata
UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
  COALESCE(raw_user_meta_data, '{}'::jsonb),
  '{school_id}',
  '"a1b2c3d4-e5f6-7890-abcd-ef1234567890"'::jsonb
)
WHERE email = 'admin@moma.edu.gh';

-- 3. Update public.users table
UPDATE public.users
SET school_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'::UUID
WHERE email = 'admin@moma.edu.gh';

-- 4. Verify both tables
SELECT 
  au.email,
  au.raw_user_meta_data->>'school_id' as metadata_school_id,
  pu.school_id as profile_school_id,
  s.school_name
FROM auth.users au
JOIN public.users pu ON au.id = pu.id
LEFT JOIN public.school_settings s ON pu.school_id = s.id
WHERE au.email = 'admin@moma.edu.gh';

-- =====================================================
-- TROUBLESHOOTING
-- =====================================================

-- If you see an error about permissions, make sure you're
-- running this as a superuser or service_role

-- If school_id still shows NULL, check that:
-- 1. The school_id exists in school_settings
-- 2. The UUID format is correct (with quotes in jsonb_set)
-- 3. You're updating the correct email address

-- =====================================================
-- FOR MULTIPLE USERS
-- =====================================================

-- If you need to update multiple users for the same school:
UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
  COALESCE(raw_user_meta_data, '{}'::jsonb),
  '{school_id}',
  '"YOUR_SCHOOL_ID_HERE"'::jsonb
)
WHERE email IN ('admin1@moma.edu.gh', 'admin2@moma.edu.gh', 'teacher@moma.edu.gh');

UPDATE public.users
SET school_id = 'YOUR_SCHOOL_ID_HERE'::UUID
WHERE email IN ('admin1@moma.edu.gh', 'admin2@moma.edu.gh', 'teacher@moma.edu.gh');

-- =====================================================
-- SUCCESS!
-- =====================================================
-- After running these queries:
-- 1. Logout from EduManage
-- 2. Login again
-- 3. The profile should now have school_id
-- 4. You can add students/staff successfully
-- =====================================================
