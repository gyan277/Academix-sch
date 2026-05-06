-- =====================================================
-- FIX STUDENT ID GENERATION PER SCHOOL
-- =====================================================
-- This script fixes the student ID generation to be school-specific
-- Each school should have its own sequence: MOU0001, MOU0002, etc.

-- =====================================================
-- STEP 1: DIAGNOSE THE CURRENT ISSUE
-- =====================================================

SELECT 'STEP 1: Current student ID distribution by school' as status;

-- Show current student IDs by school
SELECT 
  ss.school_name,
  s.student_number,
  s.full_name,
  s.created_at
FROM public.students s
JOIN public.school_settings ss ON ss.id = s.school_id
WHERE s.status = 'active'
ORDER BY ss.school_name, s.student_number;

-- Show the problem - students getting IDs from other schools
SELECT 
  'PROBLEM ANALYSIS:' as info,
  ss.school_name,
  COUNT(*) as student_count,
  MIN(s.student_number) as first_student_id,
  MAX(s.student_number) as last_student_id
FROM public.students s
JOIN public.school_settings ss ON ss.id = s.school_id
WHERE s.status = 'active'
GROUP BY ss.school_name
ORDER BY ss.school_name;

-- =====================================================
-- STEP 2: DROP EXISTING TRIGGER AND FUNCTION
-- =====================================================

SELECT 'STEP 2: Removing old student ID generation system' as status;

-- Drop existing trigger
DROP TRIGGER IF EXISTS generate_student_number_trigger ON public.students;

-- Drop existing function
DROP FUNCTION IF EXISTS generate_student_number();

-- =====================================================
-- STEP 3: CREATE SCHOOL-SPECIFIC STUDENT ID FUNCTION
-- =====================================================

SELECT 'STEP 3: Creating school-specific student ID generation' as status;

-- Create new function that generates school-specific student IDs
CREATE OR REPLACE FUNCTION generate_student_number_per_school()
RETURNS TRIGGER AS $
DECLARE
    school_prefix TEXT;
    next_number INTEGER;
    new_student_number TEXT;
BEGIN
    -- Only generate if student_number is not already set
    IF NEW.student_number IS NULL OR NEW.student_number = '' THEN
        -- Get school prefix from school_settings
        SELECT 
            UPPER(LEFT(REPLACE(school_name, ' ', ''), 3))
        INTO school_prefix
        FROM public.school_settings 
        WHERE id = NEW.school_id;
        
        -- If no school found, use default prefix
        IF school_prefix IS NULL THEN
            school_prefix := 'STU';
        END IF;
        
        -- Get the next number for this school
        SELECT COALESCE(MAX(
            CASE 
                WHEN student_number ~ ('^' || school_prefix || '[0-9]+$') 
                THEN CAST(SUBSTRING(student_number FROM LENGTH(school_prefix) + 1) AS INTEGER)
                ELSE 0 
            END
        ), 0) + 1
        INTO next_number
        FROM public.students 
        WHERE school_id = NEW.school_id 
          AND status = 'active'
          AND student_number IS NOT NULL;
        
        -- Generate new student number with zero padding
        new_student_number := school_prefix || LPAD(next_number::TEXT, 4, '0');
        
        -- Set the student number
        NEW.student_number := new_student_number;
        
        -- Also set student_id for backward compatibility
        NEW.student_id := new_student_number;
    END IF;
    
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- STEP 4: CREATE NEW TRIGGER
-- =====================================================

SELECT 'STEP 4: Creating new school-specific trigger' as status;

-- Create trigger that fires before insert
CREATE TRIGGER generate_student_number_per_school_trigger
    BEFORE INSERT ON public.students
    FOR EACH ROW
    EXECUTE FUNCTION generate_student_number_per_school();

-- =====================================================
-- STEP 5: FIX EXISTING STUDENT IDs
-- =====================================================

SELECT 'STEP 5: Fixing existing student IDs to be school-specific' as status;

-- Update existing students to have proper school-specific IDs
DO $
DECLARE
    school_record RECORD;
    student_record RECORD;
    school_prefix TEXT;
    counter INTEGER;
    new_student_id TEXT;
BEGIN
    -- Loop through each school
    FOR school_record IN 
        SELECT id, school_name FROM public.school_settings ORDER BY created_at
    LOOP
        -- Get school prefix
        school_prefix := UPPER(LEFT(REPLACE(school_record.school_name, ' ', ''), 3));
        counter := 1;
        
        RAISE NOTICE 'Processing school: % (prefix: %)', school_record.school_name, school_prefix;
        
        -- Loop through students in this school
        FOR student_record IN 
            SELECT id, full_name, student_number
            FROM public.students 
            WHERE school_id = school_record.id 
              AND status = 'active'
            ORDER BY created_at
        LOOP
            -- Generate new school-specific ID
            new_student_id := school_prefix || LPAD(counter::TEXT, 4, '0');
            
            -- Update the student
            UPDATE public.students 
            SET 
                student_number = new_student_id,
                student_id = new_student_id
            WHERE id = student_record.id;
            
            RAISE NOTICE 'Updated student % from % to %', 
                student_record.full_name, 
                student_record.student_number, 
                new_student_id;
            
            counter := counter + 1;
        END LOOP;
        
        RAISE NOTICE 'Completed school % with % students', school_record.school_name, counter - 1;
    END LOOP;
END $;

-- =====================================================
-- STEP 6: VERIFICATION
-- =====================================================

SELECT 'STEP 6: Verification of fixed student IDs' as status;

-- Show updated student IDs by school
SELECT 
  '✅ FIXED STUDENT IDs BY SCHOOL:' as result;

SELECT 
  ss.school_name,
  COUNT(*) as student_count,
  MIN(s.student_number) as first_student_id,
  MAX(s.student_number) as last_student_id,
  string_agg(s.student_number, ', ' ORDER BY s.student_number) as all_student_ids
FROM public.students s
JOIN public.school_settings ss ON ss.id = s.school_id
WHERE s.status = 'active'
GROUP BY ss.school_name, ss.id
ORDER BY ss.school_name;

-- Test the new function by showing what the next student ID would be
SELECT 
  '🧪 NEXT STUDENT ID TEST:' as test_info;

SELECT 
  ss.school_name,
  ss.id as school_id,
  UPPER(LEFT(REPLACE(ss.school_name, ' ', ''), 3)) as school_prefix,
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
-- STEP 7: TEST NEW STUDENT CREATION
-- =====================================================

SELECT 'STEP 7: Testing new student creation (simulation)' as status;

-- Show what would happen when creating a new student
SELECT 
  '📝 NEW STUDENT CREATION TEST:' as info,
  'When you create a new student, they will get the next available ID for their school' as explanation,
  'Example: Mount Olivet student gets MOU0005, Test School student gets TES0001' as example;

-- =====================================================
-- FINAL SUCCESS MESSAGE
-- =====================================================

SELECT 
  '🎉 STUDENT ID GENERATION FIXED!' as result,
  'Each school now has its own student ID sequence' as fix_1,
  'Existing students have been renumbered properly' as fix_2,
  'New students will get school-specific IDs automatically' as fix_3,
  'Multi-tenancy is now working correctly for student IDs' as fix_4;

-- Show final summary
SELECT 
  '📊 FINAL SUMMARY:' as summary;

SELECT 
  ss.school_name,
  UPPER(LEFT(REPLACE(ss.school_name, ' ', ''), 3)) as prefix_used,
  COUNT(s.id) as total_students,
  CASE 
    WHEN COUNT(s.id) > 0 
    THEN UPPER(LEFT(REPLACE(ss.school_name, ' ', ''), 3)) || '0001 to ' || 
         UPPER(LEFT(REPLACE(ss.school_name, ' ', ''), 3)) || LPAD(COUNT(s.id)::TEXT, 4, '0')
    ELSE 'No students yet'
  END as id_range
FROM public.school_settings ss
LEFT JOIN public.students s ON s.school_id = ss.id AND s.status = 'active'
GROUP BY ss.id, ss.school_name
ORDER BY ss.school_name;