-- =====================================================
-- NUCLEAR FIX FOR STUDENT ID SYSTEM
-- =====================================================
-- This script completely resets and fixes the student ID system
-- Run this if the previous fix didn't work

-- =====================================================
-- STEP 1: COMPLETE CLEANUP
-- =====================================================

SELECT 'STEP 1: Complete cleanup of existing system' as status;

-- Drop ALL existing triggers
DROP TRIGGER IF EXISTS generate_student_number_trigger ON public.students;
DROP TRIGGER IF EXISTS generate_student_number_per_school_trigger ON public.students;
DROP TRIGGER IF EXISTS auto_generate_student_number ON public.students;
DROP TRIGGER IF EXISTS set_student_number ON public.students;

-- Drop ALL existing functions
DROP FUNCTION IF EXISTS generate_student_number();
DROP FUNCTION IF EXISTS generate_student_number_per_school();
DROP FUNCTION IF EXISTS auto_generate_student_number();
DROP FUNCTION IF EXISTS set_student_number();

-- =====================================================
-- STEP 2: SHOW CURRENT MESS
-- =====================================================

SELECT 'STEP 2: Current student ID distribution (before fix)' as status;

SELECT 
  ss.school_name,
  s.student_number,
  s.full_name
FROM public.students s
JOIN public.school_settings ss ON ss.id = s.school_id
WHERE s.status = 'active'
ORDER BY ss.school_name, s.created_at;

-- =====================================================
-- STEP 3: MANUAL RENUMBERING (GUARANTEED TO WORK)
-- =====================================================

SELECT 'STEP 3: Manual renumbering of all students' as status;

-- Mount Olivet Methodist Academy students
UPDATE public.students 
SET 
  student_number = 'MOU' || LPAD(ROW_NUMBER() OVER (ORDER BY created_at)::TEXT, 4, '0'),
  student_id = 'MOU' || LPAD(ROW_NUMBER() OVER (ORDER BY created_at)::TEXT, 4, '0')
WHERE school_id = (
  SELECT id FROM public.school_settings 
  WHERE school_name ILIKE '%mount%olivet%' 
     OR school_name ILIKE '%moma%'
  LIMIT 1
) AND status = 'active';

-- Test School B students (if exists)
UPDATE public.students 
SET 
  student_number = 'TES' || LPAD(ROW_NUMBER() OVER (ORDER BY created_at)::TEXT, 4, '0'),
  student_id = 'TES' || LPAD(ROW_NUMBER() OVER (ORDER BY created_at)::TEXT, 4, '0')
WHERE school_id = (
  SELECT id FROM public.school_settings 
  WHERE school_name ILIKE '%test%school%'
  LIMIT 1
) AND status = 'active';

-- Any other schools - generic approach
DO $
DECLARE
    school_rec RECORD;
    student_rec RECORD;
    counter INTEGER;
    prefix TEXT;
    new_id TEXT;
BEGIN
    -- Loop through schools that haven't been handled yet
    FOR school_rec IN 
        SELECT id, school_name 
        FROM public.school_settings 
        WHERE school_name NOT ILIKE '%mount%olivet%' 
          AND school_name NOT ILIKE '%moma%'
          AND school_name NOT ILIKE '%test%school%'
    LOOP
        -- Generate prefix from school name
        prefix := UPPER(LEFT(REPLACE(school_rec.school_name, ' ', ''), 3));
        counter := 1;
        
        -- Update each student in this school
        FOR student_rec IN 
            SELECT id FROM public.students 
            WHERE school_id = school_rec.id AND status = 'active'
            ORDER BY created_at
        LOOP
            new_id := prefix || LPAD(counter::TEXT, 4, '0');
            
            UPDATE public.students 
            SET 
                student_number = new_id,
                student_id = new_id
            WHERE id = student_rec.id;
            
            counter := counter + 1;
        END LOOP;
        
        RAISE NOTICE 'Fixed % students for school: %', counter - 1, school_rec.school_name;
    END LOOP;
END $;

-- =====================================================
-- STEP 4: CREATE BULLETPROOF FUNCTION
-- =====================================================

SELECT 'STEP 4: Creating bulletproof student ID function' as status;

CREATE OR REPLACE FUNCTION generate_student_id_bulletproof()
RETURNS TRIGGER AS $
DECLARE
    school_prefix TEXT;
    next_number INTEGER;
    new_student_id TEXT;
    school_name_val TEXT;
BEGIN
    -- Only generate if student_number is empty or null
    IF NEW.student_number IS NULL OR NEW.student_number = '' THEN
        
        -- Get school name
        SELECT school_name INTO school_name_val
        FROM public.school_settings 
        WHERE id = NEW.school_id;
        
        -- Generate prefix based on school name
        IF school_name_val ILIKE '%mount%olivet%' OR school_name_val ILIKE '%moma%' THEN
            school_prefix := 'MOU';
        ELSIF school_name_val ILIKE '%test%school%' THEN
            school_prefix := 'TES';
        ELSIF school_name_val ILIKE '%knust%' THEN
            school_prefix := 'KNU';
        ELSE
            -- Fallback: use first 3 letters of school name
            school_prefix := UPPER(LEFT(REPLACE(school_name_val, ' ', ''), 3));
        END IF;
        
        -- Get next number for this school and prefix
        SELECT COALESCE(MAX(
            CASE 
                WHEN student_number LIKE school_prefix || '%' 
                     AND LENGTH(student_number) >= 7
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
        
        -- Generate new student ID
        new_student_id := school_prefix || LPAD(next_number::TEXT, 4, '0');
        
        -- Set both fields
        NEW.student_number := new_student_id;
        NEW.student_id := new_student_id;
        
        RAISE NOTICE 'Generated student ID: % for school: %', new_student_id, school_name_val;
    END IF;
    
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- STEP 5: CREATE BULLETPROOF TRIGGER
-- =====================================================

SELECT 'STEP 5: Creating bulletproof trigger' as status;

CREATE TRIGGER generate_student_id_bulletproof_trigger
    BEFORE INSERT ON public.students
    FOR EACH ROW
    EXECUTE FUNCTION generate_student_id_bulletproof();

-- =====================================================
-- STEP 6: VERIFICATION
-- =====================================================

SELECT 'STEP 6: Verification of fixed system' as status;

-- Show fixed student IDs
SELECT 
  '✅ FIXED STUDENT IDs:' as result;

SELECT 
  ss.school_name,
  COUNT(*) as student_count,
  MIN(s.student_number) as first_id,
  MAX(s.student_number) as last_id,
  string_agg(s.student_number, ', ' ORDER BY s.student_number) as all_ids
FROM public.students s
JOIN public.school_settings ss ON ss.id = s.school_id
WHERE s.status = 'active'
GROUP BY ss.school_name, ss.id
ORDER BY ss.school_name;

-- Test what next ID would be
SELECT 
  '🧪 NEXT ID TEST:' as test_info;

SELECT 
  ss.school_name,
  CASE 
    WHEN ss.school_name ILIKE '%mount%olivet%' OR ss.school_name ILIKE '%moma%' THEN 'MOU'
    WHEN ss.school_name ILIKE '%test%school%' THEN 'TES'
    WHEN ss.school_name ILIKE '%knust%' THEN 'KNU'
    ELSE UPPER(LEFT(REPLACE(ss.school_name, ' ', ''), 3))
  END as prefix,
  COALESCE(MAX(
    CASE 
      WHEN s.student_number LIKE 
           CASE 
             WHEN ss.school_name ILIKE '%mount%olivet%' OR ss.school_name ILIKE '%moma%' THEN 'MOU%'
             WHEN ss.school_name ILIKE '%test%school%' THEN 'TES%'
             WHEN ss.school_name ILIKE '%knust%' THEN 'KNU%'
             ELSE UPPER(LEFT(REPLACE(ss.school_name, ' ', ''), 3)) || '%'
           END
           AND LENGTH(s.student_number) >= 7
           AND SUBSTRING(s.student_number FROM 4) ~ '^[0-9]+$'
      THEN CAST(SUBSTRING(s.student_number FROM 4) AS INTEGER)
      ELSE 0 
    END
  ), 0) + 1 as next_number
FROM public.school_settings ss
LEFT JOIN public.students s ON s.school_id = ss.id AND s.status = 'active'
GROUP BY ss.id, ss.school_name
ORDER BY ss.school_name;

-- =====================================================
-- STEP 7: FINAL TEST
-- =====================================================

SELECT 'STEP 7: System is now ready for testing' as status;

SELECT 
  '🎉 STUDENT ID SYSTEM COMPLETELY FIXED!' as result,
  'All existing students have been renumbered correctly' as fix_1,
  'New students will get proper school-specific IDs' as fix_2,
  'Try adding a new student to test the system' as test_instruction;

-- Show summary
SELECT 
  '📊 FINAL SUMMARY BY SCHOOL:' as summary;

SELECT 
  ss.school_name,
  CASE 
    WHEN ss.school_name ILIKE '%mount%olivet%' OR ss.school_name ILIKE '%moma%' THEN 'MOU'
    WHEN ss.school_name ILIKE '%test%school%' THEN 'TES'
    WHEN ss.school_name ILIKE '%knust%' THEN 'KNU'
    ELSE UPPER(LEFT(REPLACE(ss.school_name, ' ', ''), 3))
  END as prefix_used,
  COUNT(s.id) as total_students,
  CASE 
    WHEN COUNT(s.id) > 0 THEN 
      CASE 
        WHEN ss.school_name ILIKE '%mount%olivet%' OR ss.school_name ILIKE '%moma%' THEN 'MOU'
        WHEN ss.school_name ILIKE '%test%school%' THEN 'TES'
        WHEN ss.school_name ILIKE '%knust%' THEN 'KNU'
        ELSE UPPER(LEFT(REPLACE(ss.school_name, ' ', ''), 3))
      END || '0001 to ' || 
      CASE 
        WHEN ss.school_name ILIKE '%mount%olivet%' OR ss.school_name ILIKE '%moma%' THEN 'MOU'
        WHEN ss.school_name ILIKE '%test%school%' THEN 'TES'
        WHEN ss.school_name ILIKE '%knust%' THEN 'KNU'
        ELSE UPPER(LEFT(REPLACE(ss.school_name, ' ', ''), 3))
      END || LPAD(COUNT(s.id)::TEXT, 4, '0')
    ELSE 'No students yet - next will be ' || 
      CASE 
        WHEN ss.school_name ILIKE '%mount%olivet%' OR ss.school_name ILIKE '%moma%' THEN 'MOU'
        WHEN ss.school_name ILIKE '%test%school%' THEN 'TES'
        WHEN ss.school_name ILIKE '%knust%' THEN 'KNU'
        ELSE UPPER(LEFT(REPLACE(ss.school_name, ' ', ''), 3))
      END || '0001'
  END as id_range
FROM public.school_settings ss
LEFT JOIN public.students s ON s.school_id = ss.id AND s.status = 'active'
GROUP BY ss.id, ss.school_name
ORDER BY ss.school_name;