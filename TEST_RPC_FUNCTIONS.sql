-- Test RPC Functions
-- Run this in Supabase SQL Editor to verify they work

-- Test 1: Get teacher class (replace with actual user_id)
-- First, let's find a teacher user_id
SELECT 
  'Available Teachers:' as info,
  u.id as user_id,
  u.email,
  t.full_name,
  t.class_assigned
FROM users u
JOIN teachers t ON t.user_id = u.id
WHERE u.role = 'teacher'
LIMIT 5;

-- Test 2: Test the RPC function with a teacher user_id
-- Replace 'YOUR_TEACHER_USER_ID' with an actual user_id from above
SELECT * FROM get_teacher_class('YOUR_TEACHER_USER_ID'::uuid);

-- Test 3: Test feature enabled check (replace with your school_id)
SELECT * FROM is_teacher_fee_collection_enabled('YOUR_SCHOOL_ID'::uuid);

-- If you see results, the RPC functions work!
-- The issue might be with how the frontend is calling them.
