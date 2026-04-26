-- =====================================================
-- DIAGNOSE TEACHER CREATION ISSUE
-- =====================================================

-- Step 1: Check Supabase Auth settings
-- Go to Supabase Dashboard → Authentication → Settings
-- Verify these settings:
-- ✅ Enable email confirmations: OFF (disabled)
-- ✅ Enable sign ups: ON (enabled)

-- Step 2: Check if any teachers exist in auth.users
SELECT 
  'Teachers in auth.users' as check_type,
  COUNT(*) as count
FROM auth.users au
WHERE au.id IN (SELECT id FROM public.users WHERE role = 'teacher');

-- Step 3: Check if any teachers exist in public.users
SELECT 
  'Teachers in public.users' as check_type,
  COUNT(*) as count
FROM public.users
WHERE role = 'teacher';

-- Step 4: List all teachers with their auth status
SELECT 
  pu.full_name,
  pu.email,
  pu.role,
  pu.status,
  au.email_confirmed_at,
  CASE 
    WHEN au.email_confirmed_at IS NULL THEN '❌ Email not confirmed'
    ELSE '✅ Email confirmed'
  END as email_status,
  au.created_at as auth_created,
  pu.created_at as profile_created
FROM public.users pu
LEFT JOIN auth.users au ON pu.id = au.id
WHERE pu.role = 'teacher'
ORDER BY pu.created_at DESC;

-- Step 5: Check RLS policies on users table
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE tablename = 'users'
ORDER BY policyname;

-- Step 6: Test if authenticated users can insert into users table
-- This should return 'true' if RLS allows inserts
SELECT 
  'Can authenticated users insert into users table?' as question,
  EXISTS (
    SELECT 1 
    FROM pg_policies 
    WHERE tablename = 'users' 
      AND cmd = 'INSERT'
      AND policyname LIKE '%authenticated%'
  ) as answer;

-- =====================================================
-- COMMON ISSUES AND FIXES
-- =====================================================

-- Issue 1: Email confirmation still required
-- Fix: Disable in Supabase Dashboard → Authentication → Settings

-- Issue 2: Sign ups disabled
-- Fix: Enable in Supabase Dashboard → Authentication → Settings

-- Issue 3: RLS blocking inserts
-- Fix: Run this to allow authenticated users to insert
DROP POLICY IF EXISTS "authenticated_users_can_insert" ON public.users;
CREATE POLICY "authenticated_users_can_insert"
  ON public.users FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Issue 4: Trigger not creating user profile
-- Fix: Check if trigger exists
SELECT 
  trigger_name,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';

-- If trigger doesn't exist, recreate it:
/*
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name, role, phone, status)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'New User'),
    COALESCE(NEW.raw_user_meta_data->>'role', 'teacher'),
    NEW.raw_user_meta_data->>'phone',
    'active'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
*/
