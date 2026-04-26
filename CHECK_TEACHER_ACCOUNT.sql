-- =====================================================
-- CHECK AND FIX TEACHER ACCOUNT
-- =====================================================

-- Step 1: Check if teacher exists in auth.users
SELECT 
  id,
  email,
  email_confirmed_at,
  created_at,
  raw_user_meta_data
FROM auth.users 
WHERE email = 'REPLACE_WITH_TEACHER_EMAIL';

-- If email_confirmed_at is NULL, the email is not confirmed
-- This is why login fails

-- Step 2: Check if teacher profile exists in public.users
SELECT 
  id,
  email,
  full_name,
  role,
  status
FROM public.users 
WHERE email = 'REPLACE_WITH_TEACHER_EMAIL';

-- =====================================================
-- FIX: Manually confirm the teacher's email
-- =====================================================

-- Replace 'REPLACE_WITH_TEACHER_EMAIL' with the actual teacher email
UPDATE auth.users 
SET email_confirmed_at = NOW()
WHERE email = 'REPLACE_WITH_TEACHER_EMAIL' 
  AND email_confirmed_at IS NULL;

-- Verify the fix
SELECT 
  id,
  email,
  email_confirmed_at,
  'Email is now confirmed' as status
FROM auth.users 
WHERE email = 'REPLACE_WITH_TEACHER_EMAIL';

-- =====================================================
-- ALTERNATIVE: Disable email confirmation in Supabase
-- =====================================================
-- Go to Supabase Dashboard:
-- 1. Authentication → Settings
-- 2. Find "Enable email confirmations"
-- 3. Toggle it OFF
-- 4. Save changes
--
-- This will allow users to login immediately after signup
-- without needing to confirm their email
-- =====================================================
