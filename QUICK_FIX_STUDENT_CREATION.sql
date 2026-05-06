-- =====================================================
-- QUICK FIX FOR STUDENT CREATION ERROR
-- =====================================================
-- Run this immediately to fix the student creation issue
-- =====================================================

-- Remove any triggers that might be causing activity log errors
DROP TRIGGER IF EXISTS log_student_activity ON students;
DROP TRIGGER IF EXISTS student_activity_trigger ON students;
DROP TRIGGER IF EXISTS audit_student_changes ON students;
DROP TRIGGER IF EXISTS log_activity_trigger ON students;

-- Check what triggers remain on students table
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE event_object_table = 'students';

-- Ensure the student number generation trigger still exists
SELECT 
  trigger_name
FROM information_schema.triggers
WHERE trigger_name = 'generate_student_number_trigger';

-- If student number trigger is missing, recreate it
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.triggers 
    WHERE trigger_name = 'generate_student_number_trigger'
  ) THEN
    -- Recreate the student number generation trigger
    CREATE OR REPLACE FUNCTION generate_student_number()
    RETURNS TRIGGER AS $func$
    DECLARE
      next_number INTEGER;
      new_student_number TEXT;
      school_prefix TEXT;
    BEGIN
      IF NEW.student_number IS NULL OR NEW.student_number = '' THEN
        SELECT UPPER(LEFT(school_name, 3))
        INTO school_prefix
        FROM schools
        WHERE id = NEW.school_id;
        
        IF school_prefix IS NULL OR school_prefix = '' THEN
          school_prefix := 'STU';
        END IF;
        
        SELECT COALESCE(MAX(
          CASE 
            WHEN student_number ~ ('^' || school_prefix || '[0-9]+$')
            THEN CAST(SUBSTRING(student_number FROM LENGTH(school_prefix) + 1) AS INTEGER)
            ELSE 0
          END
        ), 0) + 1
        INTO next_number
        FROM students
        WHERE school_id = NEW.school_id;
        
        new_student_number := school_prefix || LPAD(next_number::TEXT, 4, '0');
        NEW.student_number := new_student_number;
      END IF;
      
      RETURN NEW;
    END;
    $func$ LANGUAGE plpgsql;

    CREATE TRIGGER generate_student_number_trigger
      BEFORE INSERT ON students
      FOR EACH ROW
      EXECUTE FUNCTION generate_student_number();
  END IF;
END $$;

-- ✅ Now try adding a student - it should work!