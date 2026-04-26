-- VERIFY ACADEMIC YEAR DATABASE FLOW
-- This script checks if the academic year system is properly set up

-- =====================================================
-- STEP 1: Check if school_settings table has current_academic_year column
-- =====================================================
SELECT 
  'Step 1: Check Column Exists' as test,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'school_settings'
  AND column_name = 'current_academic_year';

-- Expected: Should return one row showing the column exists

-- =====================================================
-- STEP 2: Check current academic year values for all schools
-- =====================================================
SELECT 
  'Step 2: Current Academic Years' as test,
  id as school_id,
  school_name,
  current_academic_year,
  CASE 
    WHEN current_academic_year IS NULL THEN '❌ NULL - Needs to be set'
    WHEN current_academic_year = '' THEN '❌ EMPTY - Needs to be set'
    ELSE '✅ Set'
  END as status
FROM school_settings
ORDER BY school_name;

-- Expected: Should show all schools with their academic years

-- =====================================================
-- STEP 3: Check if academic_scores uses academic_year
-- =====================================================
SELECT 
  'Step 3: Academic Scores Table' as test,
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'academic_scores'
  AND column_name = 'academic_year';

-- Expected: Should return one row

-- =====================================================
-- STEP 4: Check if teacher_classes uses academic_year
-- =====================================================
SELECT 
  'Step 4: Teacher Classes Table' as test,
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'teacher_classes'
  AND column_name = 'academic_year';

-- Expected: Should return one row

-- =====================================================
-- STEP 5: Check if class_subjects uses academic_year
-- =====================================================
SELECT 
  'Step 5: Class Subjects Table' as test,
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'class_subjects'
  AND column_name = 'academic_year';

-- Expected: Should return one row

-- =====================================================
-- STEP 6: Check if academic_terms uses academic_year
-- =====================================================
SELECT 
  'Step 6: Academic Terms Table' as test,
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'academic_terms'
  AND column_name = 'academic_year';

-- Expected: Should return one row

-- =====================================================
-- STEP 7: Test updating academic year
-- =====================================================
DO $$
DECLARE
  test_school_id UUID;
  old_year TEXT;
  new_year TEXT := '2025/2026';
BEGIN
  -- Get first school
  SELECT id, current_academic_year INTO test_school_id, old_year
  FROM school_settings
  LIMIT 1;
  
  IF test_school_id IS NULL THEN
    RAISE NOTICE 'Step 7: ❌ No schools found in database';
    RETURN;
  END IF;
  
  RAISE NOTICE 'Step 7: Testing academic year update';
  RAISE NOTICE '  School ID: %', test_school_id;
  RAISE NOTICE '  Old Year: %', COALESCE(old_year, 'NULL');
  
  -- Update to test year
  UPDATE school_settings
  SET current_academic_year = new_year
  WHERE id = test_school_id;
  
  RAISE NOTICE '  Updated to: %', new_year;
  
  -- Verify update
  SELECT current_academic_year INTO new_year
  FROM school_settings
  WHERE id = test_school_id;
  
  IF new_year = '2025/2026' THEN
    RAISE NOTICE '  ✅ Update successful!';
  ELSE
    RAISE NOTICE '  ❌ Update failed!';
  END IF;
  
  -- Restore old value
  UPDATE school_settings
  SET current_academic_year = old_year
  WHERE id = test_school_id;
  
  RAISE NOTICE '  Restored to: %', COALESCE(old_year, 'NULL');
  
END $$;

-- =====================================================
-- STEP 8: Check data distribution by academic year
-- =====================================================
SELECT 
  'Step 8: Academic Scores by Year' as test,
  academic_year,
  COUNT(*) as score_count,
  COUNT(DISTINCT student_id) as student_count,
  COUNT(DISTINCT subject_id) as subject_count
FROM academic_scores
GROUP BY academic_year
ORDER BY academic_year DESC;

-- Expected: Shows how many scores exist for each year

-- =====================================================
-- STEP 9: Check teacher assignments by academic year
-- =====================================================
SELECT 
  'Step 9: Teacher Assignments by Year' as test,
  academic_year,
  COUNT(*) as assignment_count,
  COUNT(DISTINCT teacher_id) as teacher_count,
  COUNT(DISTINCT class) as class_count
FROM teacher_classes
GROUP BY academic_year
ORDER BY academic_year DESC;

-- Expected: Shows teacher assignments per year

-- =====================================================
-- STEP 10: Summary Report
-- =====================================================
SELECT 
  '========================================' as summary;
SELECT 
  'ACADEMIC YEAR SYSTEM STATUS' as summary;
SELECT 
  '========================================' as summary;

SELECT 
  'Total Schools: ' || COUNT(*) as summary
FROM school_settings;

SELECT 
  'Schools with Academic Year Set: ' || COUNT(*) as summary
FROM school_settings
WHERE current_academic_year IS NOT NULL 
  AND current_academic_year != '';

SELECT 
  'Schools Missing Academic Year: ' || COUNT(*) as summary
FROM school_settings
WHERE current_academic_year IS NULL 
  OR current_academic_year = '';

SELECT 
  'Academic Years in Use: ' || COUNT(DISTINCT academic_year) as summary
FROM (
  SELECT academic_year FROM academic_scores
  UNION
  SELECT academic_year FROM teacher_classes
  UNION
  SELECT academic_year FROM class_subjects
  UNION
  SELECT academic_year FROM academic_terms
) years;

SELECT 
  '========================================' as summary;

-- =====================================================
-- RECOMMENDATIONS
-- =====================================================
DO $$
DECLARE
  missing_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO missing_count
  FROM school_settings
  WHERE current_academic_year IS NULL OR current_academic_year = '';
  
  IF missing_count > 0 THEN
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  RECOMMENDATIONS:';
    RAISE NOTICE '   % school(s) need academic year to be set', missing_count;
    RAISE NOTICE '   Go to Settings → Profile and set the academic year';
    RAISE NOTICE '';
  ELSE
    RAISE NOTICE '';
    RAISE NOTICE '✅ All schools have academic year set!';
    RAISE NOTICE '';
  END IF;
END $$;
