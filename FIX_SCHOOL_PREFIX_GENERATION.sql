-- =====================================================
-- FIX SCHOOL PREFIX GENERATION
-- =====================================================
-- This script fixes student ID prefixes to match actual school names
-- Nhyiaeso International School -> NHY, Mount Olivet -> MOU, etc.

-- =====================================================
-- STEP 1: SHOW CURRENT PROBLEM
-- =====================================================

SELECT 'STEP 1: Current school names and what prefixes they should have' as status;

SELECT 
  school_name,
  UPPER(LEFT(REPLACE(REPLACE(school_name, ' ', ''), '.', ''), 3)) as correct_prefix,
  id as school_id
FROM public.school_settings
ORDER BY school_name;

-- Show students with wrong prefixes
SELECT 
  ss.school_name,
  s.student_number,
  s.full_name,
  LEFT(s.student_number, 3) as current_prefix,
  UPPER(LEFT(REPLACE(REPLACE(ss.school_name, ' ', ''), '.', ''), 3)) as should_be_prefix
FROM public.students s
JOIN public.school_settings ss ON ss.id = s.school_id
WHERE s.status = 'active' AND s.student_number IS NOT NULL
ORDER BY ss.school_name, s.student_number;

-- =====================================================
-- STEP 2: DROP OLD SYSTEM
-- =====================================================

SELECT 'STEP 2: Removing old trigger system' as status;

DROP TRIGGER IF EXISTS generate_school_specific_student_id_trigger ON public.students;
DROP TRIGGER IF EXISTS auto_assign_student_id_trigger ON public.students;
DROP FUNCTION IF EXISTS generate_school_specific_student_id();
DROP FUNCTION IF EXISTS auto_assign_student_id();

-- =====================================================
-- STEP 3: FIX ALL EXISTING STUDENT IDs
-- =====================================================

SELECT 'STEP 3: Fixing all student IDs with correct school prefixes' as status;

-- Nhyiaeso International School -> NHY
WITH numbered_students AS (
  SELECT 
    s.id,
    ROW_NUMBER() OVER (ORDER BY s.created_at) as row_num
  FROM public.students s
  JOIN public.school_settings ss ON ss.id = s.school_id
  WHERE s.status = 'active' 
    AND ss.school_name ILIKE '%nhyiaeso%'
)
UPDATE public.students 
SET 
  student_id = 'NHY' || LPAD(ns.row_num::TEXT, 4, '0'),
  student_number = 'NHY' || LPAD(ns.row_num::TEXT, 4, '0')
FROM numbered_students ns
WHERE students.id = ns.id;

-- Mount Olivet Methodist Academy -> MOU
WITH numbered_students AS (
  SELECT 
    s.id,
    ROW_NUMBER() OVER (ORDER BY s.created_at) as row_num
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

-- Test School -> TES
WITH numbered_students AS (
  SELECT 
    s.id,
    ROW_NUMBER() OVER (ORDER BY s.created_at) as row_num
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

-- Any other schools - use first 3 letters of school name
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
          AND ss.school_name NOT ILIKE '%nhyiaeso%'
          AND ss.school_name NOT ILIKE '%mount%olivet%' 
          AND ss.school_name NOT ILIKE '%moma%'
          AND ss.school_name NOT ILIKE '%test%school%'
    LOOP
        -- Generate prefix from school name (remove spaces, take first 3 letters)
        prefix := UPPER(LEFT(REPLACE(REPLACE(school_rec.school_name, ' ', ''), '.', ''), 3));
        counter := 1;
        
        RAISE NOTICE 'Processing school: % -> Prefix: %', school_rec.school_name, prefix;
        
        FOR student_rec IN 
            SELECT id, full_name FROM public.students 
            WHERE school_id = school_rec.id 
              AND status = 'active'
            ORDER BY created_at
        LOOP
            new_id := prefix || LPAD(counter::TEXT, 4, '0');
            
            UPDATE public.students 
            SET 
                student_id = new_id,
                student_number = new_id
            WHERE id = student_rec.id;
            
            RAISE NOTICE 'Updated %: %', student_rec.full_name, new_id;
            counter := counter + 1;
        END LOOP;
    END LOOP;
END $;

-- =====================================================
-- STEP 4: CREATE PROPER FUNCTION
-- =====================================================

SELECT 'STEP 4: Creating proper prefix generation function' as status;

CREATE OR REPLACE FUNCTION auto_generate_proper_student_id()
RETURNS TRIGGER AS $
DECLARE
    school_name_val TEXT;
    school_prefix TEXT;
    next_number INTEGER;
    new_student_id TEXT;
BEGIN
    IF NEW.student_number IS NULL OR NEW.student_number = '' THEN
        
        -- Get school name
        SELECT school_name INTO school_name_val
        FROM public.school_settings 
        WHERE id = NEW.school_id;
        
        -- Generate prefix based on actual school name
        IF school_name_val ILIKE '%nhyiaeso%' THEN
            school_prefix := 'NHY';
        ELSIF school_name_val ILIKE '%mount%olivet%' OR school_name_val ILIKE '%moma%' THEN
            school_prefix := 'MOU';
        ELSIF school_name_val ILIKE '%test%school%' THEN
            school_prefix := 'TES';
        ELSE
            -- Use first 3 letters of school name (remove spaces and dots)
            school_prefix := UPPER(LEFT(REPLACE(REPLACE(COALESCE(school_name_val, 'STU'), ' ', ''), '.', ''), 3));
            -- Ensure we have 3 characters
            IF LENGTH(school_prefix) < 3 THEN
                school_prefix := RPAD(school_prefix, 3, 'X');
            END IF;
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
        
        -- Set both fields
        NEW.student_number := new_student_id;
        NEW.student_id := new_student_id;
        
        RAISE NOTICE 'Generated % for school %', new_student_id, school_name_val;
        
    END IF;
    
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- STEP 5: CREATE TRIGGER
-- =====================================================

SELECT 'STEP 5: Creating trigger' as status;

CREATE TRIGGER auto_generate_proper_student_id_trigger
    BEFORE INSERT ON public.students
    FOR EACH ROW
    EXECUTE FUNCTION auto_generate_proper_student_id();

-- =====================================================
-- STEP 6: VERIFICATION
-- =====================================================

SELECT 'STEP 6: Verification - all students should now have correct prefixes' as status;

SELECT 
  ss.school_name,
  CASE 
    WHEN ss.school_name ILIKE '%nhyiaeso%' THEN 'NHY'
    WHEN ss.school_name ILIKE '%mount%olivet%' OR ss.school_name ILIKE '%moma%' THEN 'MOU'
    WHEN ss.school_name ILIKE '%test%school%' THEN 'TES'
    ELSE UPPER(LEFT(REPLACE(REPLACE(ss.school_name, ' ', ''), '.', ''), 3))
  END as expected_prefix,
  COUNT(s.id) as student_count,
  MIN(s.student_number) as first_id,
  MAX(s.student_number) as last_id,
  string_agg(s.student_number, ', ' ORDER BY s.student_number) as all_ids
FROM public.students s
JOIN public.school_settings ss ON ss.id = s.school_id
WHERE s.status = 'active' AND s.student_number IS NOT NULL
GROUP BY ss.school_name, ss.id
ORDER BY ss.school_name;

-- Show what next IDs will be
SELECT 
  '🧪 NEXT STUDENT ID PREVIEW:' as preview;

SELECT 
  ss.school_name,
  CASE 
    WHEN ss.school_name ILIKE '%nhyiaeso%' THEN 'NHY'
    WHEN ss.school_name ILIKE '%mount%olivet%' OR ss.school_name ILIKE '%moma%' THEN 'MOU'
    WHEN ss.school_name ILIKE '%test%school%' THEN 'TES'
    ELSE UPPER(LEFT(REPLACE(REPLACE(ss.school_name, ' ', ''), '.', ''), 3))
  END as prefix,
  COALESCE(MAX(
    CASE 
      WHEN s.student_number LIKE 
           CASE 
             WHEN ss.school_name ILIKE '%nhyiaeso%' THEN 'NHY%'
             WHEN ss.school_name ILIKE '%mount%olivet%' OR ss.school_name ILIKE '%moma%' THEN 'MOU%'
             WHEN ss.school_name ILIKE '%test%school%' THEN 'TES%'
             ELSE UPPER(LEFT(REPLACE(REPLACE(ss.school_name, ' ', ''), '.', ''), 3)) || '%'
           END
           AND LENGTH(s.student_number) = 7
           AND SUBSTRING(s.student_number FROM 4) ~ '^[0-9]+$'
      THEN CAST(SUBSTRING(s.student_number FROM 4) AS INTEGER)
      ELSE 0 
    END
  ), 0) + 1 as next_number,
  CASE 
    WHEN ss.school_name ILIKE '%nhyiaeso%' THEN 'NHY'
    WHEN ss.school_name ILIKE '%mount%olivet%' OR ss.school_name ILIKE '%moma%' THEN 'MOU'
    WHEN ss.school_name ILIKE '%test%school%' THEN 'TES'
    ELSE UPPER(LEFT(REPLACE(REPLACE(ss.school_name, ' ', ''), '.', ''), 3))
  END || LPAD((COALESCE(MAX(
    CASE 
      WHEN s.student_number LIKE 
           CASE 
             WHEN ss.school_name ILIKE '%nhyiaeso%' THEN 'NHY%'
             WHEN ss.school_name ILIKE '%mount%olivet%' OR ss.school_name ILIKE '%moma%' THEN 'MOU%'
             WHEN ss.school_name ILIKE '%test%school%' THEN 'TES%'
             ELSE UPPER(LEFT(REPLACE(REPLACE(ss.school_name, ' ', ''), '.', ''), 3)) || '%'
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
  '🎉 SCHOOL PREFIXES FIXED!' as result,
  'Nhyiaeso International School -> NHY0001, NHY0002...' as nhyiaeso,
  'Mount Olivet Methodist Academy -> MOU0001, MOU0002...' as mount_olivet,
  'Test School -> TES0001, TES0002...' as test_school,
  'Other schools -> First 3 letters of school name' as others,
  'New students will get correct prefixes automatically!' as future;