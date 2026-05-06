-- =====================================================
-- NUCLEAR FIX FOR ACTIVITY LOG ERROR
-- =====================================================
-- This completely removes the problematic activity logging
-- =====================================================

-- Step 1: Drop ALL activity log triggers
DROP TRIGGER IF EXISTS trigger_log_student_registration ON students;
DROP TRIGGER IF EXISTS trigger_log_payment ON payments;
DROP TRIGGER IF EXISTS trigger_log_expense ON expenses;

-- Step 2: Drop the problematic functions
DROP FUNCTION IF EXISTS log_student_registration();
DROP FUNCTION IF EXISTS log_payment_activity();
DROP FUNCTION IF EXISTS log_expense_activity();

-- Step 3: Verify no triggers remain on students table
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table
FROM information_schema.triggers
WHERE event_object_table = 'students';

-- Step 4: Recreate ONLY the student number generation (the important one)
CREATE OR REPLACE FUNCTION generate_student_number()
RETURNS TRIGGER AS $$
DECLARE
  next_number INTEGER;
  new_student_number TEXT;
  school_prefix TEXT;
BEGIN
  -- Only generate if student_number is NULL or empty
  IF NEW.student_number IS NULL OR NEW.student_number = '' THEN
    
    -- Get school prefix (first 3 letters, uppercase)
    SELECT UPPER(LEFT(school_name, 3))
    INTO school_prefix
    FROM schools
    WHERE id = NEW.school_id;
    
    -- Default if no school found
    IF school_prefix IS NULL OR school_prefix = '' THEN
      school_prefix := 'STU';
    END IF;
    
    -- Get next number for this school
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
    
    -- Generate new student number
    new_student_number := school_prefix || LPAD(next_number::TEXT, 4, '0');
    NEW.student_number := new_student_number;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 5: Ensure student number trigger exists
DROP TRIGGER IF EXISTS generate_student_number_trigger ON students;
CREATE TRIGGER generate_student_number_trigger
  BEFORE INSERT ON students
  FOR EACH ROW
  EXECUTE FUNCTION generate_student_number();

-- Step 6: Verify only the student number trigger exists
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE event_object_table = 'students';

-- =====================================================
-- OPTIONAL: Disable activity_log table temporarily
-- =====================================================

-- If you want to completely disable activity logging:
-- ALTER TABLE activity_log DISABLE TRIGGER ALL;

-- Or drop the table entirely (CAREFUL - this removes all activity history):
-- DROP TABLE IF EXISTS activity_log CASCADE;

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Test that student creation will work now
SELECT 'Activity log triggers removed. Student creation should work now!' as status;

-- Check what school prefixes will be used
SELECT 
  id,
  school_name,
  UPPER(LEFT(school_name, 3)) as student_id_prefix
FROM schools;

-- ✅ Now try adding a student - it should work without activity log errors!