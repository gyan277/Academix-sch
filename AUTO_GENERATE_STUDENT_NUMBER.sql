-- =====================================================
-- AUTO-GENERATE STUDENT NUMBER TRIGGER
-- =====================================================
-- This trigger automatically generates a unique student_number
-- when a new student is inserted into the students table
-- =====================================================

-- Drop existing trigger and function if they exist
DROP TRIGGER IF EXISTS generate_student_number_trigger ON public.students;
DROP FUNCTION IF EXISTS generate_student_number();

-- Create function to generate student number
CREATE OR REPLACE FUNCTION generate_student_number()
RETURNS TRIGGER AS $$
DECLARE
  next_number INTEGER;
  new_student_number TEXT;
  school_prefix TEXT;
BEGIN
  -- Only generate if student_number is NULL or empty
  IF NEW.student_number IS NULL OR NEW.student_number = '' THEN
    
    -- Get the school prefix (first 3 letters of school name, or use 'STU' as default)
    SELECT COALESCE(
      UPPER(SUBSTRING(name FROM 1 FOR 3)),
      'STU'
    ) INTO school_prefix
    FROM public.school_settings
    WHERE id = NEW.school_id;
    
    -- If no school found, use default prefix
    IF school_prefix IS NULL THEN
      school_prefix := 'STU';
    END IF;
    
    -- Get the next number for this school
    SELECT COALESCE(MAX(
      CASE 
        WHEN student_number ~ '^[A-Z]{3}[0-9]+$' 
        THEN CAST(SUBSTRING(student_number FROM 4) AS INTEGER)
        ELSE 0
      END
    ), 0) + 1
    INTO next_number
    FROM public.students
    WHERE school_id = NEW.school_id;
    
    -- Generate the new student number (e.g., MOU0001, MOU0002, etc.)
    new_student_number := school_prefix || LPAD(next_number::TEXT, 4, '0');
    
    -- Assign the generated number
    NEW.student_number := new_student_number;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger that fires before insert
CREATE TRIGGER generate_student_number_trigger
  BEFORE INSERT ON public.students
  FOR EACH ROW
  EXECUTE FUNCTION generate_student_number();

-- =====================================================
-- VERIFY THE TRIGGER
-- =====================================================

-- Check if trigger was created
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE trigger_name = 'generate_student_number_trigger';

-- =====================================================
-- TEST THE TRIGGER (Optional)
-- =====================================================

-- You can test by inserting a student without student_number
-- The trigger should automatically generate it

-- Example test (uncomment to run):
/*
INSERT INTO public.students (
  school_id,
  full_name,
  date_of_birth,
  gender,
  class,
  parent_name,
  parent_phone,
  admission_date,
  status
) VALUES (
  (SELECT id FROM public.school_settings LIMIT 1),
  'Test Student',
  '2010-01-01',
  'Male',
  'P1',
  'Test Parent',
  '+233501234567',
  CURRENT_DATE,
  'active'
);

-- Check the generated student_number
SELECT student_number, full_name FROM public.students WHERE full_name = 'Test Student';

-- Clean up test data
DELETE FROM public.students WHERE full_name = 'Test Student';
*/

-- =====================================================
-- UPDATE EXISTING STUDENTS WITHOUT STUDENT_NUMBER
-- =====================================================

-- This will generate student numbers for existing students that don't have one
DO $$
DECLARE
  student_record RECORD;
  next_number INTEGER := 1;
  school_prefix TEXT;
  new_student_number TEXT;
BEGIN
  -- Loop through students without student_number
  FOR student_record IN 
    SELECT id, school_id 
    FROM public.students 
    WHERE student_number IS NULL OR student_number = ''
    ORDER BY created_at, id
  LOOP
    -- Get school prefix
    SELECT COALESCE(
      UPPER(SUBSTRING(name FROM 1 FOR 3)),
      'STU'
    ) INTO school_prefix
    FROM public.school_settings
    WHERE id = student_record.school_id;
    
    IF school_prefix IS NULL THEN
      school_prefix := 'STU';
    END IF;
    
    -- Get next available number for this school
    SELECT COALESCE(MAX(
      CASE 
        WHEN student_number ~ '^[A-Z]{3}[0-9]+$' 
        THEN CAST(SUBSTRING(student_number FROM 4) AS INTEGER)
        ELSE 0
      END
    ), 0) + 1
    INTO next_number
    FROM public.students
    WHERE school_id = student_record.school_id;
    
    -- Generate student number
    new_student_number := school_prefix || LPAD(next_number::TEXT, 4, '0');
    
    -- Update the student
    UPDATE public.students
    SET student_number = new_student_number
    WHERE id = student_record.id;
    
    RAISE NOTICE 'Generated student number % for student ID %', new_student_number, student_record.id;
  END LOOP;
END $$;

-- =====================================================
-- VERIFY RESULTS
-- =====================================================

-- Check students with their generated numbers
SELECT 
  student_number,
  full_name,
  class,
  admission_date
FROM public.students
ORDER BY student_number;

-- Count students by school
SELECT 
  ss.name as school_name,
  COUNT(*) as student_count,
  COUNT(CASE WHEN s.student_number IS NOT NULL THEN 1 END) as with_number,
  COUNT(CASE WHEN s.student_number IS NULL THEN 1 END) as without_number
FROM public.students s
LEFT JOIN public.school_settings ss ON s.school_id = ss.id
GROUP BY ss.name;

-- =====================================================
-- COMPLETE!
-- =====================================================
-- 
-- The trigger is now active and will automatically generate
-- student numbers for all new students.
-- 
-- Format: [SCHOOL_PREFIX][NUMBER]
-- Example: MOU0001, MOU0002, MOU0003, etc.
-- 
-- Where:
-- - SCHOOL_PREFIX = First 3 letters of school name (e.g., "MOU" for "Mount Olivet")
-- - NUMBER = Sequential 4-digit number (0001, 0002, etc.)
-- 
-- =====================================================
