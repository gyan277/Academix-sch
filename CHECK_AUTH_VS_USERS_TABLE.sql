-- Check Auth Users vs Users Table Mismatch
-- This will help diagnose why password reset isn't finding users

-- 1. Check what's in the users table
SELECT 
  id,
  email,
  full_name,
  role,
  school_id
FROM users
ORDER BY email;

-- 2. Check Supabase Auth users (if you have access)
-- Go to: Authentication > Users in Supabase Dashboard
-- Compare the emails there with the emails above

-- 3. The issue is likely:
--    - Auth users exist but users table doesn't have matching emails
--    - OR users table has emails but Auth doesn't have those users

-- SOLUTION:
-- You need to ensure every user in Supabase Auth also exists in the users table
-- with the EXACT same email address (case-sensitive!)
