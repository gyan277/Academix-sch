-- =====================================================
-- COMPLETE TEACHER ACCOUNT FIX
-- =====================================================
-- This script will diagnose and fix teacher login issues

-- =====================================================
-- STEP 1: FIND THE TEACHER
-- =====================================================
-- Replace 'teacher@school.com' with the actual teacher email

-- Check if teacher exists in auth.users
SELECT 
  'AUTH.USERS CHECK' as step,
  id,
  email,
  email_confirmed_at,
  CASE 
    WHEN email_confirmed_at IS NULL THEN '❌ EMAIL NOT CONFIRMED - This prevents login'
    ELSE '✅ Email confirmed'
  END as email_status,
  created_at
FROM auth.users 
WHERE email = 'teacher@school.com';

-- Check if teacher exists in public.users
SELECT 
  'PUBLIC.USERS CHECK' as step,
  id,
  email,
  full_name,
  role,
  status,
  CASE 
    WHEN status = 'active' THEN '✅ Account active'
    ELSE '❌ ACCOUNT INACTIVE - This prevents login'
  END as account_status,
  created_at
FROM public.users 
WHERE email = 'teacher@school.com';

-- =====================================================
-- STEP 2: FIX EMAIL CONFIRMATION
-- =====================================================
-- This is the most common issue

UPDATE auth.users 
SET email_confirmed_at = NOW()
WHERE email = 'teacher@school.com' 
  AND email_confirmed_at IS NULL;

-- Verify the fix
SELECT 
  'EMAIL CONFIRMATION FIX' as step,
  email,
  email_confirmed_at,
  CASE 
    WHEN email_confirmed_at IS NOT NULL THEN '✅ Email is now confirmed - Teacher can login'
    ELSE '❌ Still not confirmed'
  END as status
FROM auth.users 
WHERE email = 'teacher@school.com';

-- =====================================================
-- STEP 3: FIX ACCOUNT STATUS
-- =====================================================
-- Make sure account is active

UPDATE public.users 
SET status = 'active'
WHERE email = 'teacher@school.com' 
  AND status != 'active';

-- Verify the fix
SELECT 
  'ACCOUNT STATUS FIX' as step,
  email,
  status,
  CASE 
    WHEN status = 'active' THEN '✅ Account is active - Teacher can login'
    ELSE '❌ Account is inactive'
  END as status_check
FROM public.users 
WHERE email = 'teacher@school.com';

-- =====================================================
-- STEP 4: ENSURE ROLE IS CORRECT
-- =====================================================

UPDATE public.users 
SET role = 'teacher'
WHERE email = 'teacher@school.com' 
  AND role != 'teacher';

-- Verify the fix
SELECT 
  'ROLE FIX' as step,
  email,
  role,
  CASE 
    WHEN role = 'teacher' THEN '✅ Role is correct'
    ELSE '❌ Role is wrong'
  END as role_check
FROM public.users 
WHERE email = 'teacher@school.com';

-- =====================================================
-- STEP 5: FINAL VERIFICATION
-- =====================================================
-- This shows the complete status of the teacher account

SELECT 
  '=== FINAL STATUS ===' as step,
  au.email,
  au.email_confirmed_at,
  CASE 
    WHEN au.email_confirmed_at IS NULL THEN '❌ NOT CONFIRMED'
    ELSE '✅ CONFIRMED'
  END as email_status,
  pu.full_name,
  pu.role,
  pu.status,
  CASE 
    WHEN pu.status = 'active' THEN '✅ ACTIVE'
    ELSE '❌ INACTIVE'
  END as account_status,
  CASE 
    WHEN au.email_confirmed_at IS NOT NULL AND pu.status = 'active' AND pu.role = 'teacher' 
    THEN '✅✅✅ TEACHER CAN LOGIN NOW ✅✅✅'
    ELSE '❌ STILL HAS ISSUES - Check above'
  END as can_login
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE au.email = 'teacher@school.com';

-- =====================================================
-- STEP 6: CHECK ALL TEACHERS
-- =====================================================
-- See status of all teachers in the system

SELECT 
  '=== ALL TEACHERS ===' as step,
  au.email,
  pu.full_name,
  CASE 
    WHEN au.email_confirmed_at IS NULL THEN '❌ NOT CONFIRMED'
    ELSE '✅ CONFIRMED'
  END as email_status,
  pu.status as account_status,
  pu.role,
  CASE 
    WHEN au.email_confirmed_at IS NOT NULL AND pu.status = 'active' 
    THEN '✅ CAN LOGIN'
    ELSE '❌ CANNOT LOGIN'
  END as login_status
FROM auth.users au
JOIN public.users pu ON au.id = pu.id
WHERE pu.role = 'teacher'
ORDER BY pu.created_at DESC;

-- =====================================================
-- INSTRUCTIONS
-- =====================================================
-- 1. Replace 'teacher@school.com' with the actual teacher email (appears 6 times above)
-- 2. Run this entire script in Supabase SQL Editor
-- 3. Look at the "FINAL STATUS" section - it should say "TEACHER CAN LOGIN NOW"
-- 4. If it still shows issues, check the individual steps above
-- 5. Try logging in again with the teacher credentials
-- =====================================================
