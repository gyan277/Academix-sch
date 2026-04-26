-- =====================================================
-- QUICK FIX: Create admin profile for existing auth user
-- =====================================================
-- Run this in Supabase SQL Editor to fix the login issue

-- Step 1: Create the admin profile
INSERT INTO public.users (id, email, full_name, role, phone)
SELECT 
  id,
  email,
  'Admin User',
  'admin',
  NULL
FROM auth.users 
WHERE email = 'admin@moma.com'
ON CONFLICT (id) DO UPDATE 
SET 
  role = 'admin', 
  full_name = 'Admin User';

-- Step 2: Verify it worked
SELECT 
  u.email,
  u.full_name,
  u.role,
  u.created_at
FROM public.users u
WHERE u.email = 'admin@moma.com';

-- =====================================================
-- If you see the admin user above, you're good to go!
-- Refresh your browser and try logging in again.
-- =====================================================
