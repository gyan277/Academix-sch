-- =====================================================
-- DIAGNOSE STUDENT ID GENERATION ISSUE
-- =====================================================
-- This script will help us understand exactly what's wrong

-- =====================================================
-- 1. CHECK CURRENT STUDENT IDs BY SCHOOL
-- =====================================================

SELECT '1. CURRENT STUDENT IDs BY SCHOOL:' as info;

SELECT 
  ss.school_name,
  ss.id as school_id,
  s.student_number,
  s.student_id,
  s.full_name,
  s.created_at
FROM public.students s
JOIN public.school_settings ss ON ss.id = s.school_id
WHERE s.status = 'active'
ORDER BY ss.school_name, s.created_at;

-- =====================================================
-- 2. CHECK WHAT TRIGGERS EXIST
-- =====================================================

SELECT '2. CURRENT TRIGGERS ON STUDENTS TABLE:' as info;

SELECT 
  trigger_name,
  event_manipulation,
  action_timing,
  action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'students'
  AND event_object_schema = 'public';

-- =====================================================
-- 3. CHECK WHAT FUNCTIONS EXIST
-- =====================================================

SELECT '3. STUDENT ID GENERATION FUNCTIONS:' as info;

SELECT 
  routine_name,
  routine_type,
  routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name LIKE '%student%';

-- =====================================================
-- 4. CHECK SCHOOL PREFIXES
-- =====================================================

SELECT '4. SCHOOL PREFIXES THAT SHOULD BE USED:' as info;

SELECT 
  school_name,
  UPPER(LEFT(REPLACE(school_name, ' ', ''), 3)) as calculated_prefix,
  id as school_id
FROM public.school_settings
ORDER BY school_name;

-- =====================================================
-- 5. CHECK CURRENT ID PATTERNS
-- =====================================================

SELECT '5. CURRENT ID PATTERNS BY SCHOOL:' as info;

SELECT 
  ss.school_name,
  COUNT(*) as student_count,
  MIN(s.student_number) as first_id,
  MAX(s.student_number) as last_id,
  string_agg(DISTINCT LEFT(s.student_number, 3), ', ') as prefixes_used
FROM public.students s
JOIN public.school_settings ss ON ss.id = s.school_id
WHERE s.status = 'active' AND s.student_number IS NOT NULL
GROUP BY ss.school_name, ss.id
ORDER BY ss.school_name;

-- =====================================================
-- 6. IDENTIFY THE PROBLEM
-- =====================================================

SELECT '6. PROBLEM IDENTIFICATION:' as info;

-- Check if students have wrong prefixes
SELECT 
  ss.school_name,
  UPPER(LEFT(REPLACE(ss.school_name, ' ', ''), 3)) as expected_prefix,
  s.student_number,
  LEFT(s.student_number, 3) as actual_prefix,
  CASE 
    WHEN LEFT(s.student_number, 3) = UPPER(LEFT(REPLACE(ss.school_name, ' ', ''), 3)) 
    THEN '✅ CORRECT'
    ELSE '❌ WRONG PREFIX'
  END as status
FROM public.students s
JOIN public.school_settings ss ON ss.id = s.school_id
WHERE s.status = 'active' AND s.student_number IS NOT NULL
ORDER BY ss.school_name, s.student_number;

-- =====================================================
-- 7. CHECK WHAT HAPPENS ON INSERT
-- =====================================================

SELECT '7. TESTING WHAT WOULD HAPPEN ON NEW INSERT:' as info;

-- Simulate what the next student ID would be for each school
SELECT 
  ss.school_name,
  ss.id as school_id,
  UPPER(LEFT(REPLACE(ss.school_name, ' ', ''), 3)) as prefix,
  COALESCE(MAX(
    CASE 
      WHEN s.student_number ~ ('^' || UPPER(LEFT(REPLACE(ss.school_name, ' ', ''), 3)) || '[0-9]+$') 
      THEN CAST(SUBSTRING(s.student_number FROM LENGTH(UPPER(LEFT(REPLACE(ss.school_name, ' ', ''), 3))) + 1) AS INTEGER)
      ELSE 0 
    END
  ), 0) + 1 as next_number,
  UPPER(LEFT(REPLACE(ss.school_name, ' ', ''), 3)) || LPAD((COALESCE(MAX(
    CASE 
      WHEN s.student_number ~ ('^' || UPPER(LEFT(REPLACE(ss.school_name, ' ', ''), 3)) || '[0-9]+$') 
      THEN CAST(SUBSTRING(s.student_number FROM LENGTH(UPPER(LEFT(REPLACE(ss.school_name, ' ', ''), 3))) + 1) AS INTEGER)
      ELSE 0 
    END
  ), 0) + 1)::TEXT, 4, '0') as next_student_id
FROM public.school_settings ss
LEFT JOIN public.students s ON s.school_id = ss.id AND s.status = 'active'
GROUP BY ss.id, ss.school_name
ORDER BY ss.school_name;

-- =====================================================
-- 8. CHECK IF THERE ARE DUPLICATE IDs
-- =====================================================

SELECT '8. CHECK FOR DUPLICATE STUDENT IDs:' as info;

SELECT 
  student_number,
  COUNT(*) as duplicate_count,
  string_agg(full_name, ', ') as students_with_same_id
FROM public.students 
WHERE status = 'active' AND student_number IS NOT NULL
GROUP BY student_number
HAVING COUNT(*) > 1;

-- =====================================================
-- 9. FINAL DIAGNOSIS
-- =====================================================

SELECT '9. DIAGNOSIS SUMMARY:' as summary;

WITH diagnosis AS (
  SELECT 
    COUNT(DISTINCT ss.id) as total_schools,
    COUNT(s.id) as total_students,
    COUNT(CASE WHEN LEFT(s.student_number, 3) = UPPER(LEFT(REPLACE(ss.school_name, ' ', ''), 3)) THEN 1 END) as correct_prefix_count,
    COUNT(CASE WHEN LEFT(s.student_number, 3) != UPPER(LEFT(REPLACE(ss.school_name, ' ', ''), 3)) THEN 1 END) as wrong_prefix_count
  FROM public.students s
  JOIN public.school_settings ss ON ss.id = s.school_id
  WHERE s.status = 'active' AND s.student_number IS NOT NULL
)
SELECT 
  total_schools,
  total_students,
  correct_prefix_count,
  wrong_prefix_count,
  CASE 
    WHEN wrong_prefix_count = 0 THEN '✅ All student IDs have correct school prefixes'
    WHEN wrong_prefix_count > 0 THEN '❌ ' || wrong_prefix_count || ' students have wrong school prefixes'
    ELSE 'No students found'
  END as diagnosis
FROM diagnosis;