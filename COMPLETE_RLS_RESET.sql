-- =====================================================
-- COMPLETE RLS RESET - Fix All Recursion Issues
-- =====================================================
-- This script will completely reset RLS on all tables
-- to eliminate any possibility of recursion

-- =====================================================
-- STEP 1: Disable RLS on users table
-- =====================================================

ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- STEP 2: Drop ALL policies on users table
-- =====================================================

DO $$ 
DECLARE
    r RECORD;
BEGIN
    -- Drop all policies on users table
    FOR r IN (
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'users' 
        AND schemaname = 'public'
    ) LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON public.users CASCADE';
        RAISE NOTICE 'Dropped policy: %', r.policyname;
    END LOOP;
END $$;

-- =====================================================
-- STEP 3: Check for policies on OTHER tables that might
--         cause issues when querying users table
-- =====================================================

-- List all policies that reference the users table
SELECT 
    tablename,
    policyname,
    cmd,
    CASE 
        WHEN qual LIKE '%SELECT%FROM%users%' THEN 'POTENTIAL RECURSION RISK'
        ELSE 'OK'
    END as risk_level
FROM pg_policies 
WHERE schemaname = 'public'
  AND tablename != 'users'
  AND (qual LIKE '%users%' OR with_check LIKE '%users%')
ORDER BY tablename, policyname;

-- =====================================================
-- STEP 4: Temporarily disable RLS on other tables
--         that might be queried during login
-- =====================================================

-- These tables might be queried during login, so we'll
-- disable RLS temporarily to ensure login works

ALTER TABLE public.students DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.grades DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.teacher_classes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.class_subjects DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.grading_scale DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.school_settings DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- STEP 5: Drop all policies on these tables
-- =====================================================

DO $$ 
DECLARE
    r RECORD;
    tables_to_clean TEXT[] := ARRAY[
        'students', 'staff', 'grades', 'attendance', 
        'teacher_classes', 'class_subjects', 'grading_scale',
        'school_settings'
    ];
    table_name TEXT;
BEGIN
    FOREACH table_name IN ARRAY tables_to_clean
    LOOP
        FOR r IN (
            SELECT policyname 
            FROM pg_policies 
            WHERE tablename = table_name
            AND schemaname = 'public'
        ) LOOP
            EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON public.' || quote_ident(table_name) || ' CASCADE';
            RAISE NOTICE 'Dropped policy % on table %', r.policyname, table_name;
        END LOOP;
    END LOOP;
END $$;

-- =====================================================
-- STEP 6: Verify RLS is disabled on all tables
-- =====================================================

SELECT 
    tablename,
    rowsecurity as rls_enabled,
    CASE 
        WHEN rowsecurity = true THEN '⚠️ STILL ENABLED'
        ELSE '✓ DISABLED'
    END as status
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'users', 'students', 'staff', 'grades', 'attendance',
    'teacher_classes', 'class_subjects', 'grading_scale', 'school_settings'
  )
ORDER BY tablename;

-- Expected: All should show '✓ DISABLED'

-- =====================================================
-- STEP 7: Verify no policies exist
-- =====================================================

SELECT 
    tablename,
    COUNT(*) as policy_count
FROM pg_policies 
WHERE schemaname = 'public'
  AND tablename IN (
    'users', 'students', 'staff', 'grades', 'attendance',
    'teacher_classes', 'class_subjects', 'grading_scale', 'school_settings'
  )
GROUP BY tablename
ORDER BY tablename;

-- Expected: 0 rows (no policies on any of these tables)

-- =====================================================
-- STEP 8: Test query
-- =====================================================

SELECT 
    id,
    email,
    full_name,
    role,
    school_id,
    status
FROM public.users
WHERE email = 'admin@moma.com';

-- Expected: Should return your admin user without any errors

-- =====================================================
-- STEP 9: Test school_settings query
-- =====================================================

SELECT 
    id,
    school_name,
    school_email
FROM public.school_settings
ORDER BY created_at DESC
LIMIT 5;

-- Expected: Should return Mount Olivet Methodist Academy

-- =====================================================
-- COMPLETE!
-- =====================================================
-- 
-- All RLS policies have been removed from all tables.
-- This completely eliminates any possibility of recursion.
-- 
-- Your app will now work without RLS protection.
-- Multi-tenancy must be enforced in the application code.
-- 
-- After login works, you can selectively re-enable RLS
-- on tables that don't cause recursion issues.
-- 
-- =====================================================
-- NEXT STEPS:
-- =====================================================
-- 
-- 1. Clear browser cache (Ctrl+Shift+R or Cmd+Shift+R)
-- 2. Try logging in
-- 3. If login works, you're done!
-- 4. Later, you can re-enable RLS on specific tables
--    with simple policies that don't cause recursion
-- 
-- =====================================================
