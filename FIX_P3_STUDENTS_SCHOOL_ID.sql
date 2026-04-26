-- Fix P3 Students School ID Issue
-- Ensure all P3 students have the correct school_id

-- 1. First, check what school_id the teacher has
SELECT 
  'Teacher Info' as info,
  id,
  email,
  full_name,
  school_id
FROM users
WHERE role = 'teacher'
ORDER BY created_at DESC
LIMIT 1;

-- 2. Check what school_id P3 students have
SELECT 
  'P3 Students Info' as info,
  id,
  student_number,
  full_name,
  class,
  school_id,
  status
FROM students
WHERE class = 'P3';

-- 3. Get the correct school_id (from Mount Olivet Methodist Academy)
SELECT 
  'School Info' as info,
  id as school_id,
  school_name,
  school_prefix
FROM schools
WHERE school_name LIKE '%Mount Olivet%' OR school_prefix = 'MOU';

-- 4. FIX: Update all P3 students to have the correct school_id
-- Replace 'CORRECT-SCHOOL-ID-HERE' with the actual school_id from step 3
UPDATE students
SET school_id = (
  SELECT id FROM schools 
  WHERE school_name LIKE '%Mount Olivet%' OR school_prefix = 'MOU'
  LIMIT 1
)
WHERE class = 'P3' AND (school_id IS NULL OR school_id != (
  SELECT id FROM schools 
  WHERE school_name LIKE '%Mount Olivet%' OR school_prefix = 'MOU'
  LIMIT 1
));

-- 5. Also ensure all students have status = 'active'
UPDATE students
SET status = 'active'
WHERE class = 'P3' AND (status IS NULL OR status != 'active');

-- 6. Verify the fix
SELECT 
  'After Fix - P3 Students' as info,
  student_number,
  full_name,
  class,
  school_id,
  status
FROM students
WHERE class = 'P3'
ORDER BY full_name;

-- 7. Verify teacher and students now have matching school_id
SELECT 
  'Verification' as check_type,
  u.email as teacher_email,
  u.school_id as teacher_school_id,
  COUNT(s.id) as p3_students_count
FROM users u
CROSS JOIN students s
WHERE u.role = 'teacher'
  AND s.class = 'P3'
  AND s.school_id = u.school_id
  AND s.status = 'active'
GROUP BY u.email, u.school_id;
