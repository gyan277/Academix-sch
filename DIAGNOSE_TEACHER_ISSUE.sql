-- =====================================================
-- DIAGNOSE TEACHER REGISTRATION ISSUE
-- =====================================================
-- This will show us exactly what's happening with teachers
-- =====================================================

-- Step 1: Check what's in the auth.users table (teachers created in Settings)
SELECT 
  'AUTH USERS (Teachers created in Settings):' as info,
  id,
  email,
  raw_user_meta_data->>'role' as role_in_metadata,
  raw_user_meta_data->>'full_name' as name_in_metadata,
  created_at
FROM auth.users
WHERE raw_user_meta_data->>'role' = 'teacher'
ORDER BY created_at DESC;

-- Step 2: Check what's in the users table (should match auth.users)
SELECT 
  'USERS TABLE (Should match auth.users):' as info,
  id,
  email,
  role,
  full_name,
  school_id,
  created_at
FROM users
WHERE role = 'teacher'
ORDER BY created_at DESC;

-- Step 3: Check what's in the staff table (what admin sees)
SELECT 
  'STAFF TABLE (What admin sees in teacher list):' as info,
  id,
  staff_number,
  full_name,
  position,
  specialization,
  school_id,
  status,
  created_at
FROM staff
WHERE position LIKE '%teacher%' OR position LIKE '%Teacher%'
ORDER BY created_at DESC;

-- Step 4: Check teacher class assignments
SELECT 
  'TEACHER CLASS ASSIGNMENTS:' as info,
  tca.id,
  u.email as teacher_email,
  u.full_name as teacher_name,
  tca.class_name,
  tca.subject,
  tca.school_id
FROM teacher_class_assignments tca
LEFT JOIN users u ON tca.teacher_id = u.id
ORDER BY u.full_name;

-- Step 5: Check if teacher_class_assignments table exists
SELECT 
  'TEACHER CLASS ASSIGNMENTS TABLE EXISTS:' as info,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.tables 
      WHERE table_name = 'teacher_class_assignments'
    ) 
    THEN 'YES - Table exists'
    ELSE 'NO - Table missing!'
  END as table_status;

-- Step 6: Show all schools to identify which school we're working with
SELECT 
  'ALL SCHOOLS:' as info,
  id,
  school_name,
  created_at
FROM schools
ORDER BY created_at DESC;

-- Step 7: Check what school the current admin belongs to
SELECT 
  'ADMIN SCHOOL INFO:' as info,
  u.email as admin_email,
  u.school_id,
  s.school_name
FROM users u
LEFT JOIN schools s ON u.school_id = s.id
WHERE u.role = 'admin'
ORDER BY u.created_at DESC;

-- =====================================================
-- SUMMARY
-- =====================================================
SELECT 
  'DIAGNOSIS COMPLETE!' as status,
  'Check the results above to see:' as instruction1,
  '1. Teachers in auth.users vs users vs staff tables' as instruction2,
  '2. Whether teacher_class_assignments table exists' as instruction3,
  '3. Current class assignments' as instruction4;