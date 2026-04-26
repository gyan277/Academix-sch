-- Check for duplicate student_id values in the students table
-- This will help identify if multiple students have the same student number

-- 1. Check for duplicate student_id values
SELECT 
  student_id,
  COUNT(*) as count,
  STRING_AGG(full_name, ', ') as students_with_same_id
FROM students
WHERE student_id IS NOT NULL
GROUP BY student_id
HAVING COUNT(*) > 1;

-- 2. Show all students with their IDs for verification
SELECT 
  id as uuid_id,
  student_id as student_number,
  full_name,
  class,
  status,
  created_at
FROM students
ORDER BY created_at DESC;

-- 3. Check if any students have NULL or empty student_id
SELECT 
  id,
  full_name,
  class,
  student_id
FROM students
WHERE student_id IS NULL OR student_id = '';

-- If you find duplicates, you can fix them by running:
-- UPDATE students 
-- SET student_id = NULL 
-- WHERE id = 'uuid-of-student-with-wrong-id';
-- 
-- Then the trigger will auto-generate a new unique student_id
