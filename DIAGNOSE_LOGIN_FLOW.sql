-- =====================================================
-- DIAGNOSE LOGIN FLOW
-- =====================================================
-- This script checks every step of the login process

-- =====================================================
-- 1. Check if user exists in auth.users
-- =====================================================

SELECT 
    id,
    email,
    email_confirmed_at,
    created_at,
    raw_user_meta_data
FROM auth.users 
WHERE email = 'admin@moma.com';

-- Expected: Should return 1 row with the admin user

-- =====================================================
-- 2. Check if user profile exists in public.users
-- =====================================================

SELECT 
    id,
    email,
    full_name,
    role,
    school_id,
    status,
    created_at
FROM public.users 
WHERE email = 'admin@moma.com';

-- Expected: Should return 1 row with matching id from auth.users

-- =====================================================
-- 3. Check if IDs match between auth and profile
-- =====================================================

SELECT 
    au.id as auth_id,
    au.email as auth_email,
    pu.id as profile_id,
    pu.email as profile_email,
    CASE 
        WHEN au.id = pu.id THEN 'MATCH ✓'
        ELSE 'MISMATCH ✗'
    END as id_status
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE au.email = 'admin@moma.com';

-- Expected: id_status should be 'MATCH ✓'

-- =====================================================
-- 4. Check RLS status on users table
-- =====================================================

SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled,
    CASE 
        WHEN rowsecurity = true THEN 'RLS ENABLED (might cause issues)'
        ELSE 'RLS DISABLED (good for debugging)'
    END as status
FROM pg_tables
WHERE schemaname = 'public' AND tablename = 'users';

-- Expected: rls_enabled should be false after running NUCLEAR_FIX_RLS.sql

-- =====================================================
-- 5. List ALL policies on users table
-- =====================================================

SELECT 
    policyname,
    cmd,
    permissive,
    qual as using_clause,
    with_check as with_check_clause
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'users'
ORDER BY policyname;

-- Expected: 0 rows after running NUCLEAR_FIX_RLS.sql

-- =====================================================
-- 6. Check for policies that reference users table
-- =====================================================

SELECT 
    tablename,
    policyname,
    cmd,
    qual as using_clause
FROM pg_policies 
WHERE schemaname = 'public'
  AND tablename != 'users'
  AND (qual LIKE '%users%' OR with_check LIKE '%users%')
ORDER BY tablename, policyname;

-- Expected: These are OK (other tables can reference users table)

-- =====================================================
-- 7. Check handle_new_user trigger
-- =====================================================

SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers
WHERE event_object_schema = 'public'
  AND event_object_table = 'users'
ORDER BY trigger_name;

-- Expected: Should see handle_new_user trigger

-- =====================================================
-- 8. Test direct query as if you were logged in
-- =====================================================

-- This simulates what happens when you login
-- If this works, the issue is in the frontend code
-- If this fails, the issue is in the database

SET LOCAL role authenticated;
SET LOCAL request.jwt.claims TO '{"sub": "YOUR_USER_ID_HERE"}';

SELECT 
    id,
    email,
    full_name,
    role,
    school_id
FROM public.users 
WHERE id = 'YOUR_USER_ID_HERE';

-- Replace YOUR_USER_ID_HERE with the actual id from step 1

-- =====================================================
-- 9. Check school_settings table
-- =====================================================

SELECT 
    id,
    school_name,
    school_email,
    created_at
FROM public.school_settings
ORDER BY created_at DESC;

-- Expected: Should see Mount Olivet Methodist Academy

-- =====================================================
-- 10. Verify admin user has school_id
-- =====================================================

SELECT 
    u.email,
    u.full_name,
    u.role,
    u.school_id,
    s.school_name,
    CASE 
        WHEN u.school_id IS NULL THEN 'NO SCHOOL ASSIGNED ✗'
        WHEN s.id IS NULL THEN 'SCHOOL NOT FOUND ✗'
        ELSE 'SCHOOL ASSIGNED ✓'
    END as school_status
FROM public.users u
LEFT JOIN public.school_settings s ON u.school_id = s.id
WHERE u.email = 'admin@moma.com';

-- Expected: school_status should be 'SCHOOL ASSIGNED ✓'

-- =====================================================
-- SUMMARY
-- =====================================================
-- 
-- After running this script, you should see:
-- 
-- ✓ User exists in auth.users
-- ✓ User profile exists in public.users
-- ✓ IDs match between auth and profile
-- ✓ RLS is disabled on users table
-- ✓ No policies exist on users table
-- ✓ School is assigned to user
-- 
-- If any of these checks fail, that's where the problem is!
-- =====================================================
