-- =====================================================
-- DEBUG AUTHENTICATION ISSUE
-- =====================================================
-- Run these queries one by one to diagnose the problem

-- Step 1: Check if user exists in auth.users
SELECT 
  id, 
  email, 
  created_at,
  email_confirmed_at,
  raw_user_meta_data
FROM auth.users 
WHERE email = 'admin@moma.com';

-- Step 2: Check if user exists in public.users
SELECT 
  id, 
  email, 
  full_name,
  role,
  created_at
FROM public.users 
WHERE email = 'admin@moma.com';

-- Step 3: Check if the trigger exists
SELECT 
  trigger_name, 
  event_manipulation, 
  event_object_table
FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';

-- Step 4: Check if the function exists
SELECT 
  routine_name, 
  routine_type
FROM information_schema.routines 
WHERE routine_name = 'handle_new_user';

-- =====================================================
-- FIX: If user exists in auth but not in public.users
-- =====================================================
-- Copy the user ID from Step 1 and paste it below:

INSERT INTO public.users (id, email, full_name, role, phone)
VALUES (
  'PASTE-USER-ID-HERE',  -- Replace with actual UUID from Step 1
  'admin@moma.com',
  'Admin User',
  'admin',
  NULL
)
ON CONFLICT (id) DO UPDATE 
SET 
  role = 'admin', 
  full_name = 'Admin User',
  email = 'admin@moma.com';

-- =====================================================
-- ALTERNATIVE: Create user profile for ALL auth users
-- =====================================================
-- This will create profiles for any auth users missing them:

INSERT INTO public.users (id, email, full_name, role, phone)
SELECT 
  au.id,
  au.email,
  COALESCE(au.raw_user_meta_data->>'full_name', 'User'),
  COALESCE(au.raw_user_meta_data->>'role', 'admin'),
  au.raw_user_meta_data->>'phone'
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE pu.id IS NULL;

-- =====================================================
-- VERIFY: Check if it worked
-- =====================================================
SELECT 
  au.email as auth_email,
  pu.email as profile_email,
  pu.role,
  pu.full_name
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE au.email = 'admin@moma.com';
