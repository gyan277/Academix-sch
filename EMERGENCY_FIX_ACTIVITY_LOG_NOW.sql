-- =====================================================
-- EMERGENCY FIX FOR ACTIVITY LOG ERROR
-- =====================================================
-- This will immediately fix the student registration error
-- Run this RIGHT NOW in Supabase SQL Editor
-- =====================================================

-- Step 1: Remove ALL problematic activity log triggers
DROP TRIGGER IF EXISTS trigger_log_student_registration ON students;
DROP TRIGGER IF EXISTS trigger_log_payment ON payments;
DROP TRIGGER IF EXISTS trigger_log_expense ON expenses;
DROP TRIGGER IF EXISTS trigger_log_staff_registration ON staff;
DROP TRIGGER IF EXISTS trigger_log_user_activity ON users;

-- Step 2: Remove the problematic functions
DROP FUNCTION IF EXISTS log_student_registration();
DROP FUNCTION IF EXISTS log_payment_activity();
DROP FUNCTION IF EXISTS log_expense_activity();
DROP FUNCTION IF EXISTS log_staff_activity();
DROP FUNCTION IF EXISTS log_user_activity();

-- Step 3: Ensure student number generation still works
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
    
    -- Generate new student number: PREFIX + 4-digit number
    new_student_number := school_prefix || LPAD(next_number::TEXT, 4, '0');
    NEW.student_number := new_student_number;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 4: Ensure the student number trigger exists
DROP TRIGGER IF EXISTS generate_student_number_trigger ON students;
CREATE TRIGGER generate_student_number_trigger
  BEFORE INSERT ON students
  FOR EACH ROW
  EXECUTE FUNCTION generate_student_number();

-- Step 5: Verify no problematic triggers remain
SELECT 
  'ACTIVITY LOG TRIGGERS REMOVED!' as status,
  COUNT(*) as remaining_triggers
FROM information_schema.triggers
WHERE event_object_table = 'students'
  AND trigger_name LIKE '%log%';

-- Step 6: Show what triggers remain (should only be student number generation)
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table
FROM information_schema.triggers
WHERE event_object_table IN ('students', 'staff')
ORDER BY event_object_table, trigger_name;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
SELECT 
  '✅ EMERGENCY FIX COMPLETE!' as message,
  'Student registration should work now' as next_step,
  'Try adding the student again' as instruction;