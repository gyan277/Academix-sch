-- Diagnose Teacher Class Assignment Issue
-- Run this to check why teacher doesn't see assigned classes

-- 1. Check if teacher_classes table has the assignment
SELECT 
  tc.id,
  tc.teacher_id,
  u.email as teacher_email,
  u.full_name as teacher_name,
  tc.class,
  tc.subject_id,
  s.subject_name,
  tc.academic_year,
  tc.created_at
FROM teacher_classes tc
LEFT JOIN users u ON tc.teacher_id = u.id
LEFT JOIN subjects s ON tc.subject_id = s.subject_id
ORDER BY tc.created_at DESC;

-- 2. Check teacher's user record
SELECT 
  id,
  email,
  full_name,
  role,
  school_id
FROM users
WHERE role = 'teacher'
ORDER BY created_at DESC;

-- 3. Check if there's a mismatch in teacher_id
-- The teacher_id in teacher_classes should match the user's id (UUID)
SELECT 
  'Checking for ID mismatches' as check_type,
  tc.teacher_id,
  u.id as user_id,
  u.email,
  CASE 
    WHEN tc.teacher_id = u.id THEN 'MATCH ✓'
    ELSE 'MISMATCH ✗'
  END as id_status
FROM teacher_classes tc
LEFT JOIN users u ON tc.teacher_id = u.id
WHERE u.role = 'teacher';

-- 4. Check current academic year setting
SELECT 
  'Current academic year in assignments' as info,
  DISTINCT academic_year
FROM teacher_classes;

-- 5. If you just assigned a teacher, check the most recent assignment
SELECT 
  'Most recent assignment' as info,
  tc.*,
  u.email as teacher_email
FROM teacher_classes tc
LEFT JOIN users u ON tc.teacher_id = u.id
ORDER BY tc.created_at DESC
LIMIT 5;

-- SOLUTION: If teacher_id doesn't match user.id, you need to use the correct UUID
-- The teacher_id should be the UUID from the users table, not from staff table

-- To fix a wrong assignment, run:
-- UPDATE teacher_classes 
-- SET teacher_id = (SELECT id FROM users WHERE email = 'teacher@email.com')
-- WHERE teacher_id = 'wrong-id';
