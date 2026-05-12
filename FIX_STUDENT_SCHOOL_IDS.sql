-- FIX STUDENT SCHOOL IDs
-- Assigns correct school_id to students who have NULL or invalid school_id

-- ============================================
-- STEP 1: Identify the issue
-- ============================================

SELECT 
  '1. Current Issue' as step,
  COUNT(*) as students_with_invalid_school_id
FROM students s
LEFT JOIN schools sc ON sc.id = s.school_id
WHERE s.school_id IS NULL OR sc.id IS NULL;

-- ============================================
-- STEP 2: Get the correct school IDs
-- ============================================

-- Show available schools
SELECT 
  '2. Available Schools' as step,
  id,
  school_name,
  school_prefix
FROM schools
ORDER BY school_name;

-- ============================================
-- STEP 3: Fix students based on student_number prefix
-- ============================================

-- Update students with MOU prefix to Mount Olivet
UPDATE students
SET school_id = (
  SELECT id FROM schools 
  WHERE school_prefix = 'MOU' 
  LIMIT 1
)
WHERE student_number LIKE 'MOU%'
AND (
  school_id IS NULL 
  OR school_id NOT IN (SELECT id FROM schools)
);

SELECT 
  '3a. Fixed MOU Students' as step,
  COUNT(*) as updated_count
FROM students
WHERE student_number LIKE 'MOU%'
AND school_id = (SELECT id FROM schools WHERE school_prefix = 'MOU' LIMIT 1);

-- Update students with NHY prefix to Nhyiaeso
UPDATE students
SET school_id = (
  SELECT id FROM schools 
  WHERE school_prefix = 'NHY' 
  LIMIT 1
)
WHERE student_number LIKE 'NHY%'
AND (
  school_id IS NULL 
  OR school_id NOT IN (SELECT id FROM schools)
);

SELECT 
  '3b. Fixed NHY Students' as step,
  COUNT(*) as updated_count
FROM students
WHERE student_number LIKE 'NHY%'
AND school_id = (SELECT id FROM schools WHERE school_prefix = 'NHY' LIMIT 1);

-- ============================================
-- STEP 4: Fix any remaining students without school_id
-- ============================================

-- If there are students without a prefix, assign them to the first school
UPDATE students
SET school_id = (SELECT id FROM schools ORDER BY created_at LIMIT 1)
WHERE school_id IS NULL
OR school_id NOT IN (SELECT id FROM schools);

SELECT 
  '4. Fixed Remaining Students' as step,
  COUNT(*) as students_still_without_school
FROM students s
LEFT JOIN schools sc ON sc.id = s.school_id
WHERE s.school_id IS NULL OR sc.id IS NULL;

-- ============================================
-- STEP 5: Verify the fix
-- ============================================

-- Show all students with their schools
SELECT 
  '5. Verification' as step,
  s.student_number,
  s.full_name,
  s.class,
  sc.school_name,
  CASE 
    WHEN s.school_id IS NULL THEN '❌ NULL'
    WHEN sc.id IS NULL THEN '❌ Invalid'
    ELSE '✅ Valid'
  END as status
FROM students s
LEFT JOIN schools sc ON sc.id = s.school_id
ORDER BY s.student_number
LIMIT 20;

-- ============================================
-- STEP 6: Check specific student (Gyan Daniel)
-- ============================================

SELECT 
  '6. Gyan Daniel Status' as step,
  s.id,
  s.student_number,
  s.full_name,
  s.school_id,
  sc.school_name,
  CASE 
    WHEN s.school_id IS NOT NULL AND sc.id IS NOT NULL THEN '✅ Ready for fee override'
    ELSE '❌ Still has issue'
  END as status
FROM students s
LEFT JOIN schools sc ON sc.id = s.school_id
WHERE s.full_name LIKE '%Gyan%Daniel%'
   OR s.full_name LIKE '%Daniel%Gyan%';

-- ============================================
-- FINAL STATUS
-- ============================================

SELECT 
  '✅ FIX COMPLETE' as status,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM students s
      LEFT JOIN schools sc ON sc.id = s.school_id
      WHERE s.school_id IS NULL OR sc.id IS NULL
    ) THEN '⚠️ Some students still have invalid school_id. Check manually.'
    ELSE '✅ All students now have valid school_id. Fee override should work!'
  END as message;
