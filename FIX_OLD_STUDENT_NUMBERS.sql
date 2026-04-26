-- =====================================================
-- FIX OLD STUDENT NUMBERS
-- =====================================================
-- This script updates old student numbers that start with "STU"
-- to the new school-based format (e.g., MOU0001)
-- =====================================================

-- First, let's see what we have
SELECT 
  id,
  student_number,
  full_name,
  class,
  school_id
FROM public.students
WHERE student_number LIKE 'STU%'
ORDER BY student_number;

-- =====================================================
-- UPDATE OLD STUDENT NUMBERS
-- =====================================================

DO $$
DECLARE
  student_record RECORD;
  school_prefix TEXT;
  new_student_number TEXT;
  next_number INTEGER;
BEGIN
  -- Loop through students with old STU numbers
  FOR student_record IN 
    SELECT id, school_id, student_number, full_name
    FROM public.students 
    WHERE student_number LIKE 'STU%'
    ORDER BY student_number
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
    -- This will find the highest number and add 1
    SELECT COALESCE(MAX(
      CASE 
        WHEN student_number ~ '^[A-Z]{3}[0-9]+$' 
        THEN CAST(SUBSTRING(student_number FROM 4) AS INTEGER)
        ELSE 0
      END
    ), 0) + 1
    INTO next_number
    FROM public.students
    WHERE school_id = student_record.school_id
      AND student_number NOT LIKE 'STU%'; -- Exclude old format
    
    -- Generate new student number
    new_student_number := school_prefix || LPAD(next_number::TEXT, 4, '0');
    
    -- Update the student
    UPDATE public.students
    SET student_number = new_student_number
    WHERE id = student_record.id;
    
    RAISE NOTICE 'Updated % from % to %', 
      student_record.full_name, 
      student_record.student_number, 
      new_student_number;
  END LOOP;
END $$;

-- =====================================================
-- VERIFY THE UPDATES
-- =====================================================

-- Check if any STU numbers remain
SELECT 
  COUNT(*) as old_format_count
FROM public.students
WHERE student_number LIKE 'STU%';

-- Show all student numbers in new format
SELECT 
  student_number,
  full_name,
  class,
  admission_date
FROM public.students
ORDER BY student_number;

-- =====================================================
-- ALTERNATIVE: If you want to keep sequential order
-- =====================================================
-- If you want the old students to keep their numbers
-- but with the new prefix (STU0001 -> MOU0001, STU0002 -> MOU0002)
-- Uncomment and run this instead:

/*
DO $$
DECLARE
  student_record RECORD;
  school_prefix TEXT;
  new_student_number TEXT;
  old_number TEXT;
BEGIN
  FOR student_record IN 
    SELECT id, school_id, student_number, full_name
    FROM public.students 
    WHERE student_number LIKE 'STU%'
    ORDER BY student_number
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
    
    -- Extract the number part from STU0001 -> 0001
    old_number := SUBSTRING(student_record.student_number FROM 4);
    
    -- Create new number with school prefix
    new_student_number := school_prefix || old_number;
    
    -- Update the student
    UPDATE public.students
    SET student_number = new_student_number
    WHERE id = student_record.id;
    
    RAISE NOTICE 'Updated % from % to %', 
      student_record.full_name, 
      student_record.student_number, 
      new_student_number;
  END LOOP;
END $$;
*/

-- =====================================================
-- COMPLETE!
-- =====================================================
-- 
-- All old STU numbers have been updated to the new format.
-- 
-- Old format: STU0001, STU0002
-- New format: MOU0001, MOU0002 (or your school prefix)
-- 
-- =====================================================
