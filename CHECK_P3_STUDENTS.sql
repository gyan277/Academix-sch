-- Check P3 Students Issue
-- Why can't the teacher see students in P3?

-- 1. Check if students exist in P3
SELECT 
  id,
  student_number,
  full_name,
  class,
  status,
  school_id,
  created_at
FROM students
WHERE class = 'P3'
ORDER BY full_name;

-- 2. Check the teacher's school_id
SELECT 
  id,
  email,
  full_name,
  role,
  school_id
FROM users
WHERE role = 'teacher'
ORDER BY created_at DESC
LIMIT 5;

-- 3. Check if school_id matches between teacher and students
SELECT 
  'Teacher school_id' as type,
  school_id,
  COUNT(*) as count
FROM users
WHERE role = 'teacher'
GROUP BY school_id

UNION ALL

SELECT 
  'P3 Students school_id' as type,
  school_id,
  COUNT(*) as count
FROM students
WHERE class = 'P3'
GROUP BY school_id;

-- 4. Check student status
SELECT 
  status,
  COUNT(*) as count
FROM students
WHERE class = 'P3'
GROUP BY status;

-- 5. Check RLS policies on students table
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'students';

-- SOLUTIONS:

-- If school_id mismatch, update students:
-- UPDATE students 
-- SET school_id = (SELECT school_id FROM users WHERE role = 'teacher' LIMIT 1)
-- WHERE class = 'P3';

-- If status is not active:
-- UPDATE students 
-- SET status = 'active'
-- WHERE class = 'P3';

-- If RLS is blocking, check that students table has proper policy:
-- CREATE POLICY "Users can view students from their school"
--   ON students FOR SELECT
--   USING (
--     school_id IN (
--       SELECT school_id FROM users WHERE id = auth.uid()
--     )
--   );
