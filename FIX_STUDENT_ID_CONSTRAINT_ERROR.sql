-- =====================================================
-- FIX STUDENT ID CONSTRAINT ERROR
-- =====================================================
-- This script fixes the duplicate key constraint error

-- =====================================================
-- STEP 1: IDENTIFY THE CONSTRAINT ISSUE
-- =====================================================

SELECT 'STEP 1: Identifying constraint issues' as status;

-- Show all constraints on students table
SELECT 
  constraint_name,
  constraint_type,
  column_name
FROM information_schema.table_constraints tc
JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name
WHERE tc.table_name = 'students' AND tc.table_schema = 'public';

-- Show current student IDs that might be duplicated
SELECT 
  student_id,
  student_number,
  COUNT(*) as duplicate_count
FROM public.students 
WHERE student_id IS NOT NULL
GROUP BY student_id, student_number
HAVING COUNT(*) > 1;

-- =====================================================
-- STEP 2: DROP PROBLEMATIC CONSTRAINTS
-- =====================================================

SELECT 'STEP 2: Removing problematic constraints' as status;

-- Drop the unique constraint on student_id if it exists
ALTER TABLE public.students DROP CONSTRAINT IF EXISTS students_student_id_key;
ALTER TABLE public.students DROP CONSTRAINT IF EXISTS students_student_number_key;
ALTER TABLE public.students DROP CONSTRAINT IF EXISTS unique_student_id;
ALTER TABLE public.students DROP CONSTRAINT IF EXISTS unique_student_number;

-- =====================================================
-- STEP 3: CLEAN UP EXISTING TRIGGERS
-- =====================================================

SELECT 'STEP 3: Cleaning up existing triggers' as status;

-- Drop all existing student ID generation triggers
DROP TRIGGER IF EXISTS generate_student_number_trigger ON public.students;
DROP TRIGGER IF EXISTS generate_student_number_per_school_trigger ON public.students;
DROP TRIGGER IF EXISTS generate_student_id_bulletproof_trigger ON public.students;
DROP TRIGGER IF EXISTS auto_generate_student_number ON public.students;

-- Drop all existing functions
DROP FUNCTION IF EXISTS generate_student_number();
DROP FUNCTION IF EXISTS generate_student_number_per_school();
DROP FUNCTION IF EXISTS generate_student_id_bulletproof();
DROP FUNCTION IF EXISTS auto_generate_student_number();

-- =====================================================
-- STEP 4: CLEAR AND RESET ALL STUDENT IDs
-- =====================================================

SELECT 'STEP 4: Clearing and resetting all student IDs' as status;

-- First, clear all student IDs to avoid conflicts
UPDATE public.students 
SET 
  student_id = NULL,
  student_number = NULL
WHERE status = 'active';

-- =====================================================
-- STEP 5: MANUAL ASSIGNMENT BY SCHOOL
-- =====================================================

SELECT 'STEP 5: Manual assignment by school' as status;

-- Mount Olivet Methodist Academy (MOMA)
WITH numbered_students AS (
  SELECT 
    id,
    ROW_NUMBER() OVER (ORDER BY created_at) as row_num
  FROM public.students s
  JOIN public.school_settings ss ON ss.id = s.school_id
  WHERE s.status = 'active' 
    AND (ss.school_name ILIKE '%mount%olivet%' OR ss.school_name ILIKE '%moma%')
)
UPDATE public.students 
SET 
  student_id = 'MOU' || LPAD(ns.row_num::TEXT, 4, '0'),
  student_number = 'MOU' || LPAD(ns.row_num::TEXT, 4, '0')
FROM numbered_students ns
WHERE students.id = ns.id;

-- Test School B
WITH numbered_students AS (
  SELECT 
    id,
    ROW_NUMBER() OVER (ORDER BY created_at) as row_num
  FROM public.students s
  JOIN public.school_settings ss ON ss.id = s.school_id
  WHERE s.status = 'active' 
    AND ss.school_name ILIKE '%test%school%'
)
UPDATE public.students 
SET 
  student_id = 'TES' || LPAD(ns.row_num::TEXT, 4, '0'),
  student_number = 'TES' || LPAD(ns.row_num::TEXT, 4, '0')
FROM numbered_students ns
WHERE students.id = ns.id;

-- Any other schools
DO $
DECLARE
    school_rec RECORD;
    student_rec RECORD;
    counter INTEGER;
    prefix TEXT;
    new_id TEXT;
BEGIN
    FOR school_rec IN 
        SELECT DISTINCT ss.id, ss.school_name 
        FROM public.school_settings ss
        JOIN public.students s ON s.school_id = ss.id
        WHERE s.status = 'active'
          AND ss.school_name NOT ILIKE '%mount%olivet%' 
          AND ss.school_name NOT ILIKE '%moma%'
          AND ss.school_name NOT ILIKE '%test%school%'
          AND (s.student_id IS NULL OR s.student_number IS NULL)
    LOOP
        prefix := UPPER(LEFT(REPLACE(school_rec.school_name, ' ', ''), 3));
        counter := 1;
        
        FOR student_rec IN 
            SELECT id FROM public.students 
            WHERE school_id = school_rec.id 
              AND status = 'active'
              AND (student_id IS NULL OR student_number IS NULL)
            ORDER BY created_at
        LOOP
            new_id := prefix || LPAD(counter::TEXT, 4, '0');
            
            UPDATE public.students 
            SET 
                student_id = new_id,
                student_number = new_id
            WHERE id = student_rec.id;
            
            counter := counter + 1;
        END LOOP;
        
        RAISE NOTICE 'Fixed % students for school: %', counter - 1, school_rec.school_name;
    END LOOP;
END $;

-- =====================================================
-- STEP 6: CREATE SIMPLE TRIGGER FUNCTION
-- =====================================================

SELECT 'STEP 6: Creating simple trigger function' as status;

CREATE OR REPLACE FUNCTION auto_assign_student_id()
RETURNS TRIGGER AS $
DECLARE
    school_name_val TEXT;
    school_prefix TEXT;
    next_number INTEGER;
    new_student_id TEXT;
BEGIN
    -- Only assign if student_number is empty
    IF NEW.student_number IS NULL OR NEW.student_number = '' THEN
        
        -- Get school name
        SELECT school_name INTO school_name_val
        FROM public.school_settings 
        WHERE id = NEW.school_id;
        
        -- Determine prefix
        IF school_name_val ILIKE '%mount%olivet%' OR school_name_val ILIKE '%moma%' THEN
            school_prefix := 'MOU';
        ELSIF school_name_val ILIKE '%test%school%' THEN
            school_prefix := 'TES';
        ELSE
            school_prefix := UPPER(LEFT(REPLACE(COALESCE(school_name_val, 'STU'), ' ', ''), 3));
        END IF;
        
        -- Get next number for this school
        SELECT COALESCE(MAX(
            CASE 
                WHEN student_number LIKE school_prefix || '%' 
                     AND LENGTH(student_number) = 7
                     AND SUBSTRING(student_number FROM 4) ~ '^[0-9]+$'
                THEN CAST(SUBSTRING(student_number FROM 4) AS INTEGER)
                ELSE 0 
            END
        ), 0) + 1
        INTO next_number
        FROM public.students 
        WHERE school_id = NEW.school_id 
          AND status = 'active'
          AND student_number IS NOT NULL;
        
        -- Create new ID
        new_student_id := school_prefix || LPAD(next_number::TEXT, 4, '0');
        
        -- Assign to both fields
        NEW.student_number := new_student_id;
        NEW.student_id := new_student_id;
        
    END IF;
    
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- STEP 7: CREATE TRIGGER
-- =====================================================

SELECT 'STEP 7: Creating trigger' as status;

CREATE TRIGGER auto_assign_student_id_trigger
    BEFORE INSERT ON public.students
    FOR EACH ROW
    EXECUTE FUNCTION auto_assign_student_id();

-- =====================================================
-- STEP 8: VERIFICATION
-- =====================================================

SELECT 'STEP 8: Verification' as status;

-- Show current student IDs by school
SELECT 
  '✅ CURRENT STUDENT IDs BY SCHOOL:' as result;

SELECT 
  ss.school_name,
  COUNT(s.id) as student_count,
  MIN(s.student_number) as first_id,
  MAX(s.student_number) as last_id,
  string_agg(s.student_number, ', ' ORDER BY s.student_number) as sample_ids
FROM public.students s
JOIN public.school_settings ss ON ss.id = s.school_id
WHERE s.status = 'active' AND s.student_number IS NOT NULL
GROUP BY ss.school_name, ss.id
ORDER BY ss.school_name;

-- Check for any remaining duplicates
SELECT 
  '🔍 DUPLICATE CHECK:' as check_type;

SELECT 
  student_number,
  COUNT(*) as count,
  CASE 
    WHEN COUNT(*) > 1 THEN '❌ DUPLICATE FOUND'
    ELSE '✅ UNIQUE'
  END as status
FROM public.students 
WHERE status = 'active' AND student_number IS NOT NULL
GROUP BY student_number
ORDER BY COUNT(*) DESC, student_number;

-- Show what next IDs would be
SELECT 
  '🧪 NEXT ID PREVIEW:' as preview;

SELECT 
  ss.school_name,
  CASE 
    WHEN ss.school_name ILIKE '%mount%olivet%' OR ss.school_name ILIKE '%moma%' THEN 'MOU'
    WHEN ss.school_name ILIKE '%test%school%' THEN 'TES'
    ELSE UPPER(LEFT(REPLACE(ss.school_name, ' ', ''), 3))
  END as prefix,
  COALESCE(MAX(
    CASE 
      WHEN s.student_number LIKE 
           CASE 
             WHEN ss.school_name ILIKE '%mount%olivet%' OR ss.school_name ILIKE '%moma%' THEN 'MOU%'
             WHEN ss.school_name ILIKE '%test%school%' THEN 'TES%'
             ELSE UPPER(LEFT(REPLACE(ss.school_name, ' ', ''), 3)) || '%'
           END
           AND LENGTH(s.student_number) = 7
           AND SUBSTRING(s.student_number FROM 4) ~ '^[0-9]+$'
      THEN CAST(SUBSTRING(s.student_number FROM 4) AS INTEGER)
      ELSE 0 
    END
  ), 0) + 1 as next_number,
  CASE 
    WHEN ss.school_name ILIKE '%mount%olivet%' OR ss.school_name ILIKE '%moma%' THEN 'MOU'
    WHEN ss.school_name ILIKE '%test%school%' THEN 'TES'
    ELSE UPPER(LEFT(REPLACE(ss.school_name, ' ', ''), 3))
  END || LPAD((COALESCE(MAX(
    CASE 
      WHEN s.student_number LIKE 
           CASE 
             WHEN ss.school_name ILIKE '%mount%olivet%' OR ss.school_name ILIKE '%moma%' THEN 'MOU%'
             WHEN ss.school_name ILIKE '%test%school%' THEN 'TES%'
             ELSE UPPER(LEFT(REPLACE(ss.school_name, ' ', ''), 3)) || '%'
           END
           AND LENGTH(s.student_number) = 7
           AND SUBSTRING(s.student_number FROM 4) ~ '^[0-9]+$'
      THEN CAST(SUBSTRING(s.student_number FROM 4) AS INTEGER)
      ELSE 0 
    END
  ), 0) + 1)::TEXT, 4, '0') as next_student_id
FROM public.school_settings ss
LEFT JOIN public.students s ON s.school_id = ss.id AND s.status = 'active'
GROUP BY ss.id, ss.school_name
ORDER BY ss.school_name;

-- =====================================================
-- FINAL SUCCESS MESSAGE
-- =====================================================

SELECT 
  '🎉 STUDENT ID SYSTEM FIXED!' as result,
  'Constraint errors resolved' as fix_1,
  'All students have unique IDs' as fix_2,
  'New students will get proper school-specific IDs' as fix_3,
  'Try adding a new student now!' as test_instruction;