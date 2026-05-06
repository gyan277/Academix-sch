-- =====================================================
-- STANDARDIZE ALL STUDENT IDs WITH SCHOOL PREFIX
-- =====================================================
-- This ensures ALL students have IDs like: MOU0001, KNU0001, etc.
-- Format: [FIRST 3 LETTERS OF SCHOOL NAME] + [4-digit number]
-- =====================================================

-- Step 1: Check current schools and their prefixes
SELECT 
  id,
  school_name,
  UPPER(LEFT(school_name, 3)) as prefix,
  COUNT(s.id) as student_count
FROM schools sc
LEFT JOIN students s ON sc.id = s.school_id
GROUP BY sc.id, sc.school_name
ORDER BY sc.school_name;

-- Step 2: Drop existing trigger and function
DROP TRIGGER IF EXISTS generate_student_number_trigger ON students;
DROP FUNCTION IF EXISTS generate_student_number();

-- Step 3: Create the perfect student number generation function
CREATE OR REPLACE FUNCTION generate_student_number()
RETURNS TRIGGER AS $$
DECLARE
  next_number INTEGER;
  new_student_number TEXT;
  school_prefix TEXT;
BEGIN
  -- Only generate if student_number is NULL or empty
  IF NEW.student_number IS NULL OR NEW.student_number = '' THEN
    
    -- Get the school prefix (first 3 letters of school name, uppercase)
    SELECT UPPER(LEFT(school_name, 3))
    INTO school_prefix
    FROM schools
    WHERE id = NEW.school_id;
    
    -- If no school found, use default prefix
    IF school_prefix IS NULL OR school_prefix = '' THEN
      school_prefix := 'STU';
    END IF;
    
    -- Get the next sequential number for this school
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
    
    -- Generate the new student number: PREFIX + 4-digit number
    new_student_number := school_prefix || LPAD(next_number::TEXT, 4, '0');
    
    -- Assign the generated number
    NEW.student_number := new_student_number;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 4: Create trigger for new students
CREATE TRIGGER generate_student_number_trigger
  BEFORE INSERT ON students
  FOR EACH ROW
  EXECUTE FUNCTION generate_student_number();

-- Step 5: Fix ALL existing students to have proper format
DO $$
DECLARE
  school_record RECORD;
  student_record RECORD;
  counter INTEGER;
  school_prefix TEXT;
  new_student_number TEXT;
BEGIN
  -- Loop through each school
  FOR school_record IN 
    SELECT id, school_name, UPPER(LEFT(school_name, 3)) as prefix
    FROM schools
    ORDER BY school_name
  LOOP
    school_prefix := school_record.prefix;
    counter := 1;
    
    RAISE NOTICE 'Processing school: % (prefix: %)', school_record.school_name, school_prefix;
    
    -- Loop through all students in this school, ordered by creation date
    FOR student_record IN 
      SELECT id, full_name, student_number
      FROM students 
      WHERE school_id = school_record.id
      ORDER BY created_at, id
    LOOP
      -- Generate new standardized student number
      new_student_number := school_prefix || LPAD(counter::TEXT, 4, '0');
      
      -- Update the student
      UPDATE students
      SET student_number = new_student_number
      WHERE id = student_record.id;
      
      RAISE NOTICE 'Updated % from % to %', 
        student_record.full_name, 
        COALESCE(student_record.student_number, 'NULL'), 
        new_student_number;
      
      counter := counter + 1;
    END LOOP;
  END LOOP;
END $$;

-- Step 6: Verify all students now have proper format
SELECT 
  sc.school_name,
  UPPER(LEFT(sc.school_name, 3)) as expected_prefix,
  s.student_number,
  s.full_name,
  s.class,
  CASE 
    WHEN s.student_number ~ ('^' || UPPER(LEFT(sc.school_name, 3)) || '[0-9]{4}$') 
    THEN '✅ Correct'
    ELSE '❌ Wrong Format'
  END as format_check
FROM students s
JOIN schools sc ON s.school_id = sc.id
ORDER BY sc.school_name, s.student_number;

-- Step 7: Show summary by school
SELECT 
  sc.school_name,
  UPPER(LEFT(sc.school_name, 3)) as prefix,
  COUNT(s.id) as total_students,
  MIN(s.student_number) as first_id,
  MAX(s.student_number) as last_id
FROM schools sc
LEFT JOIN students s ON sc.id = s.school_id
GROUP BY sc.id, sc.school_name
ORDER BY sc.school_name;

-- =====================================================
-- EXAMPLES OF EXPECTED RESULTS:
-- =====================================================
-- Mount Olivet Methodist Academy → MOU0001, MOU0002, MOU0003...
-- KNUST → KNU0001, KNU0002, KNU0003...
-- University of Ghana → UNI0001, UNI0002, UNI0003...
-- Any School Name → [FIRST 3 LETTERS]0001, [FIRST 3 LETTERS]0002...
-- =====================================================

-- ✅ COMPLETE! All students now have standardized IDs
-- ✅ New students will automatically get proper IDs
-- ✅ Format: [SCHOOL_PREFIX][4-DIGIT-NUMBER]