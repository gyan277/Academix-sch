-- Comprehensive Diagnostic for Teacher Fee Collection Issue
-- Run this to find out why teacher can't see their class

-- Step 1: Check if teacher record exists
SELECT 
  '1. Teacher Record Check' as step,
  t.id as teacher_id,
  t.user_id,
  t.full_name,
  t.class_assigned,
  t.school_id,
  u.email,
  u.role
FROM teachers t
JOIN users u ON t.user_id = u.id
ORDER BY t.full_name;

-- Step 2: Check current user (replace with actual user_id if known)
-- Get this from browser console or Supabase Auth
SELECT 
  '2. Current User Check' as step,
  id as user_id,
  email,
  role,
  raw_user_meta_data
FROM auth.users
WHERE email LIKE '%teacher%' OR email LIKE '%@%'
ORDER BY email;

-- Step 3: Check if user has teacher record
SELECT 
  '3. User-Teacher Link Check' as step,
  u.id as user_id,
  u.email,
  u.role,
  t.id as teacher_id,
  t.full_name,
  t.class_assigned,
  CASE 
    WHEN t.id IS NULL THEN '❌ NO TEACHER RECORD'
    WHEN t.class_assigned IS NULL THEN '⚠️ NO CLASS ASSIGNED'
    WHEN t.class_assigned = '' THEN '⚠️ EMPTY CLASS'
    ELSE '✅ HAS CLASS: ' || t.class_assigned
  END as status
FROM users u
LEFT JOIN teachers t ON t.user_id = u.id
WHERE u.role = 'teacher'
ORDER BY u.email;

-- Step 4: Check RLS policies on teachers table
SELECT 
  '4. RLS Policies Check' as step,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'teachers'
ORDER BY policyname;

-- Step 5: Check school_settings for feature toggle
SELECT 
  '5. Feature Toggle Check' as step,
  id as school_id,
  school_name,
  enable_teacher_fee_collection,
  CASE 
    WHEN enable_teacher_fee_collection = true THEN '✅ ENABLED'
    WHEN enable_teacher_fee_collection = false THEN '❌ DISABLED'
    ELSE '⚠️ NULL (not set)'
  END as feature_status
FROM school_settings;

-- Step 6: Check if students exist in classes
SELECT 
  '6. Students by Class' as step,
  class,
  COUNT(*) as student_count,
  school_id
FROM students
WHERE status = 'active'
GROUP BY class, school_id
ORDER BY class;

-- Step 7: Test query that TeacherDashboard uses
-- Replace 'USER_ID_HERE' with actual user_id from Step 2
-- SELECT 
--   '7. Test Teacher Query' as step,
--   class_assigned, 
--   full_name, 
--   id
-- FROM teachers
-- WHERE user_id = 'USER_ID_HERE';

SELECT '✅ Diagnostic complete! Review results above.' as result;
