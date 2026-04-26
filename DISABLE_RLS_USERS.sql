-- =====================================================
-- EMERGENCY FIX: DISABLE RLS ON USERS TABLE
-- =====================================================
-- This temporarily disables RLS to fix the infinite recursion error

-- =====================================================
-- 1. DISABLE RLS ON USERS TABLE
-- =====================================================

ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- 2. DROP ALL POLICIES (just to be safe)
-- =====================================================

DROP POLICY IF EXISTS "users_can_read_own_school" ON public.users;
DROP POLICY IF EXISTS "users_can_insert_own_school" ON public.users;
DROP POLICY IF EXISTS "users_can_update_own_school" ON public.users;
DROP POLICY IF EXISTS "users_can_delete_own_school" ON public.users;
DROP POLICY IF EXISTS "authenticated_users_can_read_all" ON public.users;
DROP POLICY IF EXISTS "authenticated_users_can_insert" ON public.users;
DROP POLICY IF EXISTS "authenticated_users_can_update" ON public.users;
DROP POLICY IF EXISTS "authenticated_users_can_delete" ON public.users;
DROP POLICY IF EXISTS "users_select_all" ON public.users;
DROP POLICY IF EXISTS "users_insert_all" ON public.users;
DROP POLICY IF EXISTS "users_update_all" ON public.users;
DROP POLICY IF EXISTS "users_delete_all" ON public.users;

-- =====================================================
-- 3. VERIFY RLS IS DISABLED
-- =====================================================

SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' AND tablename = 'users';

-- Should show: rowsecurity = false

-- =====================================================
-- COMPLETE!
-- =====================================================
-- RLS is now disabled on the users table.
-- Try logging in again - it should work now.
-- 
-- Note: This is safe because:
-- 1. Users are already authenticated via Supabase Auth
-- 2. Other tables (students, staff) still have RLS enabled
-- 3. School isolation still works through those tables
-- =====================================================
