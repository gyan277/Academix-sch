-- =====================================================
-- SAFE FIX FOR ACTIVITY LOG ERROR
-- =====================================================
-- This version only removes triggers that actually exist
-- Run this in Supabase SQL Editor
-- =====================================================

-- Step 1: Remove only the triggers that exist (ignore errors for non-existent ones)
DO $$
BEGIN
    -- Try to drop student registration trigger
    BEGIN
        DROP TRIGGER IF EXISTS trigger_log_student_registration ON students;
        RAISE NOTICE 'Removed trigger_log_student_registration';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'trigger_log_student_registration not found (OK)';
    END;
    
    -- Try to drop payment trigger
    BEGIN
        DROP TRIGGER IF EXISTS trigger_log_payment ON payments;
        RAISE NOTICE 'Removed trigger_log_payment';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'trigger_log_payment not found (OK)';
    END;
    
    -- Try to drop staff trigger
    BEGIN
        DROP TRIGGER IF EXISTS trigger_log_staff_registration ON staff;
        RAISE NOTICE 'Removed trigger_log_staff_registration';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'trigger_log_staff_registration not found (OK)';
    END;
    
    -- Try to drop user trigger
    BEGIN
        DROP TRIGGER IF EXISTS trigger_log_user_activity ON users;
        RAISE NOTICE 'Removed trigger_log_user_activity';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'trigger_log_user_activity not found (OK)';
    END;
END $$;

-- Step 2: Remove only the functions that exist
DO $$
BEGIN
    -- Try to drop student registration function
    BEGIN
        DROP FUNCTION IF EXISTS log_student_registration();
        RAISE NOTICE 'Removed log_student_registration function';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'log_student_registration function not found (OK)';
    END;
    
    -- Try to drop payment function
    BEGIN
        DROP FUNCTION IF EXISTS log_payment_activity();
        RAISE NOTICE 'Removed log_payment_activity function';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'log_payment_activity function not found (OK)';
    END;
    
    -- Try to drop staff function
    BEGIN
        DROP FUNCTION IF EXISTS log_staff_activity();
        RAISE NOTICE 'Removed log_staff_activity function';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'log_staff_activity function not found (OK)';
    END;
    
    -- Try to drop user function
    BEGIN
        DROP FUNCTION IF EXISTS log_user_activity();
        RAISE NOTICE 'Removed log_user_activity function';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'log_user_activity function not found (OK)';
    END;
END $$;

-- Step 3: Ensure student number generation works
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

-- Step 5: Show what triggers remain on students table
SELECT 
  'REMAINING TRIGGERS ON STUDENTS TABLE:' as info,
  trigger_name,
  event_manipulation
FROM information_schema.triggers
WHERE event_object_table = 'students'
ORDER BY trigger_name;

-- Step 6: Show what school this is and what the student prefix will be
SELECT 
  'SCHOOL INFORMATION:' as info,
  school_name,
  UPPER(LEFT(school_name, 3)) as student_id_prefix,
  UPPER(LEFT(school_name, 3)) || '0001' as first_student_id
FROM schools
ORDER BY school_name;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
SELECT 
  '✅ SAFE FIX COMPLETE!' as status,
  'Activity log triggers safely removed' as message,
  'Student registration should work now' as next_step;