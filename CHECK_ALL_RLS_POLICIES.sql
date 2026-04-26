-- =====================================================
-- CHECK ALL RLS POLICIES IN THE DATABASE
-- =====================================================
-- This will show us ALL policies that might be causing issues

-- =====================================================
-- 1. Check which tables have RLS enabled
-- =====================================================

SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- =====================================================
-- 2. List ALL policies on ALL tables
-- =====================================================

SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    cmd,
    qual as using_expression,
    with_check as with_check_expression
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- =====================================================
-- 3. Find policies that might query the users table
-- =====================================================

SELECT 
    schemaname,
    tablename,
    policyname,
    qual as using_expression
FROM pg_policies 
WHERE schemaname = 'public'
  AND (
    qual LIKE '%users%' 
    OR with_check LIKE '%users%'
  )
ORDER BY tablename, policyname;

-- =====================================================
-- 4. Check specifically for users table policies
-- =====================================================

SELECT 
    policyname,
    cmd,
    qual as using_expression,
    with_check as with_check_expression
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename = 'users'
ORDER BY policyname;

-- =====================================================
-- 5. Check if there are any triggers on users table
-- =====================================================

SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE event_object_schema = 'public'
  AND event_object_table = 'users'
ORDER BY trigger_name;

-- =====================================================
-- ANALYSIS INSTRUCTIONS:
-- =====================================================
-- 
-- Look for:
-- 1. Any policy on 'users' table that contains "SELECT" in qual
-- 2. Any policy that has a subquery like "(SELECT ... FROM users ...)"
-- 3. Multiple policies on the same table that might conflict
-- 
-- If you see policies on the users table, they need to be dropped.
-- =====================================================
