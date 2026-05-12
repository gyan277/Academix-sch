-- QUICK FIX FOR SCHOOL_ID FOREIGN KEY ERROR
-- The error means the school_id being sent doesn't exist in schools table

-- Step 1: Check what schools exist
SELECT 'Schools in database:' as info, id, school_name, school_prefix FROM schools;

-- Step 2: Check Gyan Daniel's school_id
SELECT 
  'Gyan Daniel student record:' as info,
  id, 
  student_number, 
  full_name, 
  school_id,
  class
FROM students 
WHERE full_name LIKE '%Gyan%' OR full_name LIKE '%Daniel%';

-- Step 3: Fix - Update all MOU students to have correct school_id
UPDATE students 
SET school_id = (SELECT id FROM schools WHERE school_prefix = 'MOU' LIMIT 1)
WHERE student_number LIKE 'MOU%';

-- Step 4: Fix - Update all NHY students to have correct school_id  
UPDATE students 
SET school_id = (SELECT id FROM schools WHERE school_prefix = 'NHY' LIMIT 1)
WHERE student_number LIKE 'NHY%';

-- Step 5: Verify the fix
SELECT 
  'After fix - Gyan Daniel:' as info,
  s.student_number,
  s.full_name,
  s.school_id,
  sc.school_name
FROM students s
LEFT JOIN schools sc ON sc.id = s.school_id
WHERE s.full_name LIKE '%Gyan%' OR s.full_name LIKE '%Daniel%';

-- Step 6: Check if there are any students with NULL or invalid school_id
SELECT 
  'Students with invalid school_id:' as info,
  COUNT(*) as count
FROM students s
LEFT JOIN schools sc ON sc.id = s.school_id
WHERE s.school_id IS NULL OR sc.id IS NULL;
