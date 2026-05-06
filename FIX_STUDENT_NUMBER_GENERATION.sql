-- =====================================================
-- FIX STUDENT NUMBER AUTO-GENERATION
-- =====================================================
-- This fixes the student number generation to work with the schools table
-- =====================================================

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS generate_student_number_trigger ON students;
DROP FUNCTION IF EXISTS generate_student_number();

-- Create corrected function to generate student number
CREATE OR REPLACE FUNCTION generate_student_number()
RETURNS TRIGGER AS $$
DECLARE
  next_number INTEGER;
  new_student_number TEXT;
  school_prefix TEXT;
BEGIN
  -- Only generate if student_number is NULL or empty
  IF NEW.student_number IS NULL OR NEW.student_number = '' THEN
    
    -- Get the school prefix (first 3 letters of school name)
    SELECT UPPER(LEFT(school_name, 3))
    INTO school_prefix
    FROM schools
    WHERE id = NEW.school_id;
    
    -- If no school found, use default prefix
    IF school_prefix IS NULL OR school_prefix = '' THEN
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
    FROM students
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
  BEFORE INSERT ON students
  FOR EACH ROW
  EXECUTE FUNCTION generate_student_number();

-- =====================================================
-- FIX EXISTING STUDENTS WITHOUT PROPER NUMBERS
-- =====================================================

-- Update students that have numbers like "0010" to proper format
DO $$
DECLARE
  student_record RECORD;
  next_number INTEGER;
  school_prefix TEXT;
  new_student_number TEXT;
BEGIN
  -- Loop through students with incorrect student numbers (no school prefix)
  FOR student_record IN 
    SELECT id, school_id, student_number, full_name
    FROM students 
    WHERE student_number IS NULL 
       OR student_number = '' 
       OR student_number ~ '^[0-9]+$'  -- Numbers without prefix like "0010"
    ORDER BY created_at, id
  LOOP
    -- Get school prefix
    SELECT UPPER(LEFT(school_name, 3))
    INTO school_prefix
    FROM schools
    WHERE id = student_record.school_id;
    
    IF school_prefix IS NULL OR school_prefix = '' THEN
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
    FROM students
    WHERE school_id = student_record.school_id;
    
    -- Generate student number
    new_student_number := school_prefix || LPAD(next_number::TEXT, 4, '0');
    
    -- Update the student
    UPDATE students
    SET student_number = new_student_number
    WHERE id = student_record.id;
    
    RAISE NOTICE 'Updated student % from % to %', 
      student_record.full_name, 
      COALESCE(student_record.student_number, 'NULL'), 
      new_student_number;
  END LOOP;
END $$;

-- =====================================================
-- VERIFY THE FIX
-- =====================================================

-- Check all students now have proper student numbers
SELECT 
  student_number,
  full_name,
  class,
  s.school_id,
  sc.school_name
FROM students s
LEFT JOIN schools sc ON s.school_id = sc.id
ORDER BY student_number;

-- Check the trigger exists
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table
FROM information_schema.triggers
WHERE trigger_name = 'generate_student_number_trigger';

-- ✅ After running this:
-- 1. All existing students will have proper numbers (MOU0001, MOU0002, etc.)
-- 2. New students will automatically get proper numbers
-- 3. Student numbers will include school prefix (first 3 letters of school name)