-- COMPREHENSIVE DIAGNOSIS FOR TEACHER CLASS DISPLAY ISSUE
-- Run this to understand what the frontend should be seeing

-- 1. Verify teacher exists and has correct data
SELECT 
  'Teacher Account' as check_type,
  id,
  email,
  full_name,
  role,
  school_id
FROM users
WHERE email = 'georgegyan@gmail.com';

-- 2. Check teacher_classes assignments
SELECT 
  'Teacher Classes' as check_type,
  tc.id,
  tc.teacher_id,
  tc.class,
  tc.academic_year,
  tc.school_id,
  tc.created_at
FROM teacher_classes tc
JOIN users u ON u.id = tc.teacher_id
WHERE u.email = 'georgegyan@gmail.com';

-- 3. Check RLS policies on teacher_classes table
SELECT 
  'RLS Policies' as check_type,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'teacher_classes';

-- 4. Test the EXACT query that the frontend uses
-- This simulates what Attendance.tsx does
SELECT 
  'Frontend Query Simulation' as check_type,
  class
FROM teacher_classes
WHERE teacher_id = '3d40ae98-73c1-438c-840a-e058a87a0af9';

-- 5. Check if there are any triggers or functions that might interfere
SELECT 
  'Triggers on teacher_classes' as check_type,
  trigger_name,
  event_manipulation,
  action_statement
FROM information_schema.triggers
WHERE event_object_table = 'teacher_classes';

-- 6. Verify the teacher can read their own record (RLS test)
-- Run this AS the teacher user if possible
SET ROLE authenticated;
SELECT 
  'RLS Test (as authenticated)' as check_type,
  *
FROM teacher_classes
WHERE teacher_id = '3d40ae98-73c1-438c-840a-e058a87a0af9';
RESET ROLE;
