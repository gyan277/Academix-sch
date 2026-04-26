-- FIX NULL SCHOOL IDS
-- The problem: Both Sir Isaac and P3 students have NULL school_id

-- Step 1: Find a valid school_id to use (from admin or another user)
SELECT 
  '1. Find Valid School ID' as step,
  school_id,
  email,
  role,
  full_name
FROM users
WHERE school_id IS NOT NULL
LIMIT 5;

-- Step 2: If there's a valid school_id, use it. Otherwise create one.
-- Let's check if there's a school in the schools table
SELECT 
  '2. Check Schools Table' as step,
  id as school_id,
  school_name,
  school_code
FROM schools
LIMIT 5;

-- Step 3: FIX - Set Sir Isaac's school_id to the first valid school
-- Replace 'PASTE_SCHOOL_ID_HERE' with the actual school_id from Step 1 or 2
UPDATE users
SET school_id = (
  SELECT COALESCE(
    (SELECT school_id FROM users WHERE school_id IS NOT NULL LIMIT 1),
    (SELECT id FROM schools LIMIT 1)
  )
)
WHERE email = 'careerghana01@gmail.com';

-- Step 4: FIX - Set all P3 students to the same school_id as Sir Isaac
UPDATE students
SET school_id = (SELECT school_id FROM users WHERE email = 'careerghana01@gmail.com')
WHERE class = 'P3';

-- Step 5: VERIFY - Check if they now match
SELECT 
  '5. Verification' as step,
  'Teacher' as type,
  school_id,
  email as identifier
FROM users
WHERE email = 'careerghana01@gmail.com'

UNION ALL

SELECT 
  '5. Verification' as step,
  'P3 Students' as type,
  school_id,
  COUNT(*)::text || ' students' as identifier
FROM students
WHERE class = 'P3'
GROUP BY school_id;

-- Step 6: Final test - should return 5 students
SELECT 
  '6. Final Test' as step,
  COUNT(*) as matching_students
FROM students s
WHERE s.class = 'P3'
  AND s.status = 'active'
  AND s.school_id = (SELECT school_id FROM users WHERE email = 'careerghana01@gmail.com')
  AND s.school_id IS NOT NULL;
