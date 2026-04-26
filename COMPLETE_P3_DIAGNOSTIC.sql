-- Complete P3 Diagnostic
-- Check everything about Sir Isaac and P3 students

-- 1. Sir Isaac's user info
SELECT 
  '1. Sir Isaac User Info' as step,
  id as user_id,
  email,
  full_name,
  role,
  school_id,
  status
FROM users
WHERE email = 'careerghana01@gmail.com';

-- 2. Sir Isaac's class assignments
SELECT 
  '2. Sir Isaac Class Assignments' as step,
  tc.id,
  tc.teacher_id,
  tc.class,
  tc.academic_year,
  tc.created_at
FROM teacher_classes tc
JOIN users u ON tc.teacher_id = u.id
WHERE u.email = 'careerghana01@gmail.com';

-- 3. P3 Students info
SELECT 
  '3. P3 Students' as step,
  id,
  student_number,
  full_name,
  class,
  status,
  school_id
FROM students
WHERE class = 'P3'
ORDER BY full_name;

-- 4. Check if school_id matches
SELECT 
  '4. School ID Match Check' as step,
  'Teacher' as type,
  school_id,
  email as identifier
FROM users
WHERE email = 'careerghana01@gmail.com'

UNION ALL

SELECT 
  '4. School ID Match Check' as step,
  'P3 Students' as type,
  school_id,
  COUNT(*)::text || ' students' as identifier
FROM students
WHERE class = 'P3'
GROUP BY school_id;

-- 5. Test the exact query that the frontend uses
SELECT 
  '5. Frontend Query Test' as step,
  s.id,
  s.student_number,
  s.full_name,
  s.class,
  s.status,
  s.school_id
FROM students s
WHERE s.class = 'P3'
  AND s.status = 'active'
  AND s.school_id = (SELECT school_id FROM users WHERE email = 'careerghana01@gmail.com')
ORDER BY s.full_name;

-- 6. Check if there are any RLS issues
-- This query simulates what happens when Sir Isaac is logged in
SET LOCAL role TO authenticated;
SET LOCAL request.jwt.claims TO json_build_object(
  'sub', (SELECT id::text FROM users WHERE email = 'careerghana01@gmail.com')
)::text;

SELECT 
  '6. RLS Test (as Sir Isaac)' as step,
  COUNT(*) as student_count
FROM students
WHERE class = 'P3' AND status = 'active';

RESET role;
RESET request.jwt.claims;
