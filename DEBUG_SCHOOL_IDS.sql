-- DEBUG: Find out what's really going on with school_ids

-- 1. Show Sir Isaac's exact school_id
SELECT 
  '1. Sir Isaac school_id' as info,
  id as user_id,
  email,
  school_id,
  school_id::text as school_id_text
FROM users
WHERE email = 'careerghana01@gmail.com';

-- 2. Show ALL P3 students with their school_ids
SELECT 
  '2. P3 Students school_ids' as info,
  id,
  full_name,
  school_id,
  school_id::text as school_id_text,
  class,
  status
FROM students
WHERE class = 'P3';

-- 3. Show ALL unique school_ids in students table
SELECT 
  '3. All school_ids in students' as info,
  school_id,
  school_id::text as school_id_text,
  COUNT(*) as student_count
FROM students
GROUP BY school_id;

-- 4. Show ALL unique school_ids in users table
SELECT 
  '4. All school_ids in users' as info,
  school_id,
  school_id::text as school_id_text,
  COUNT(*) as user_count,
  STRING_AGG(email, ', ') as emails
FROM users
GROUP BY school_id;

-- 5. Check if school_id columns are the same type
SELECT 
  '5. Column Types' as info,
  'students.school_id' as table_column,
  data_type,
  udt_name
FROM information_schema.columns
WHERE table_name = 'students' AND column_name = 'school_id'

UNION ALL

SELECT 
  '5. Column Types' as info,
  'users.school_id' as table_column,
  data_type,
  udt_name
FROM information_schema.columns
WHERE table_name = 'users' AND column_name = 'school_id';

-- 6. Try to match them directly
SELECT 
  '6. Direct Match Test' as info,
  s.full_name as student_name,
  s.school_id as student_school_id,
  u.email as teacher_email,
  u.school_id as teacher_school_id,
  CASE 
    WHEN s.school_id = u.school_id THEN 'MATCH'
    WHEN s.school_id::text = u.school_id::text THEN 'TEXT MATCH'
    ELSE 'NO MATCH'
  END as match_status
FROM students s
CROSS JOIN users u
WHERE s.class = 'P3'
  AND u.email = 'careerghana01@gmail.com'
LIMIT 5;
