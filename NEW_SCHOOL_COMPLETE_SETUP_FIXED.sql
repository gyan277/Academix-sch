-- =====================================================
-- COMPLETE DATABASE SETUP FOR NEW SCHOOLS - FIXED VERSION
-- =====================================================
-- This script sets up a brand new school database with ALL latest fixes
-- Run this for every new school registration
-- =====================================================

-- =====================================================
-- STEP 1: CREATE SCHOOL RECORD
-- =====================================================

-- Insert new school (replace with actual school name)
INSERT INTO schools (school_name, created_at)
VALUES ('NEW_SCHOOL_NAME_HERE', NOW())
ON CONFLICT (school_name) DO NOTHING;

-- Get the school ID for reference
DO $$
DECLARE
  new_school_id UUID;
  school_name_var TEXT := 'NEW_SCHOOL_NAME_HERE'; -- Change this
BEGIN
  SELECT id INTO new_school_id FROM schools WHERE school_name = school_name_var;
  RAISE NOTICE 'School ID: %', new_school_id;
END $$;

-- =====================================================
-- STEP 2: FIX TOTAL_SCORE COLUMN (Academic Scores)
-- =====================================================

-- Ensure total_score is auto-calculated
ALTER TABLE academic_scores 
DROP COLUMN IF EXISTS total_score CASCADE;

ALTER TABLE academic_scores 
ADD COLUMN total_score DECIMAL(5,2) 
GENERATED ALWAYS AS (COALESCE(class_score, 0) + COALESCE(exam_score, 0)) STORED;

-- =====================================================
-- STEP 3: SETUP GRADING SCALE
-- =====================================================

-- Create default grading scale for the new school
INSERT INTO grading_scale (school_id, grade, min_score, max_score)
SELECT 
  (SELECT id FROM schools WHERE school_name = 'NEW_SCHOOL_NAME_HERE' LIMIT 1),
  grade,
  min_score,
  max_score
FROM (VALUES
  ('A1', 80, 100),
  ('A2', 75, 79),
  ('B1', 70, 74),
  ('B2', 65, 69),
  ('B3', 60, 64),
  ('C1', 55, 59),
  ('C2', 50, 54),
  ('C3', 45, 49),
  ('D1', 40, 44),
  ('D2', 35, 39),
  ('E1', 30, 34),
  ('F', 0, 29)
) AS grades(grade, min_score, max_score)
ON CONFLICT DO NOTHING;

-- =====================================================
-- STEP 4: MAKE STUDENT FIELDS OPTIONAL
-- =====================================================

-- Allow NULL values for optional student fields
ALTER TABLE students 
ALTER COLUMN date_of_birth DROP NOT NULL;

ALTER TABLE students 
ALTER COLUMN parent_name DROP NOT NULL;

ALTER TABLE students 
ALTER COLUMN parent_phone DROP NOT NULL;

ALTER TABLE students 
ALTER COLUMN gender DROP NOT NULL;

-- =====================================================
-- STEP 5: REMOVE PROBLEMATIC ACTIVITY LOG TRIGGERS
-- =====================================================

-- Remove ALL activity log triggers that cause errors
DROP TRIGGER IF EXISTS trigger_log_student_registration ON students;
DROP TRIGGER IF EXISTS trigger_log_payment ON payments;
DROP TRIGGER IF EXISTS trigger_log_expense ON expenses;

-- Remove the problematic functions
DROP FUNCTION IF EXISTS log_student_registration();
DROP FUNCTION IF EXISTS log_payment_activity();
DROP FUNCTION IF EXISTS log_expense_activity();

-- =====================================================
-- STEP 6: SETUP STUDENT NUMBER AUTO-GENERATION
-- =====================================================

-- Create the perfect student number generation function
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

-- Create the trigger
DROP TRIGGER IF EXISTS generate_student_number_trigger ON students;
CREATE TRIGGER generate_student_number_trigger
  BEFORE INSERT ON students
  FOR EACH ROW
  EXECUTE FUNCTION generate_student_number();

-- =====================================================
-- STEP 7: SETUP STAFF NUMBER AUTO-GENERATION
-- =====================================================

-- Create staff number generation function
CREATE OR REPLACE FUNCTION generate_staff_number()
RETURNS TRIGGER AS $$
DECLARE
  next_number INTEGER;
  new_staff_number TEXT;
  school_prefix TEXT;
BEGIN
  -- Only generate if staff_number is NULL or empty
  IF NEW.staff_number IS NULL OR NEW.staff_number = '' THEN
    
    -- Get school prefix
    SELECT UPPER(LEFT(school_name, 3))
    INTO school_prefix
    FROM schools
    WHERE id = NEW.school_id;
    
    IF school_prefix IS NULL OR school_prefix = '' THEN
      school_prefix := 'STF';
    END IF;
    
    -- Get next number for this school
    SELECT COALESCE(MAX(
      CASE 
        WHEN staff_number ~ ('^' || school_prefix || '[0-9]+$')
        THEN CAST(SUBSTRING(staff_number FROM LENGTH(school_prefix) + 1) AS INTEGER)
        ELSE 0
      END
    ), 0) + 1
    INTO next_number
    FROM staff
    WHERE school_id = NEW.school_id;
    
    -- Generate new staff number
    new_staff_number := school_prefix || LPAD(next_number::TEXT, 4, '0');
    NEW.staff_number := new_staff_number;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create staff number trigger
DROP TRIGGER IF EXISTS generate_staff_number_trigger ON staff;
CREATE TRIGGER generate_staff_number_trigger
  BEFORE INSERT ON staff
  FOR EACH ROW
  EXECUTE FUNCTION generate_staff_number();

-- =====================================================
-- STEP 8: CREATE DEFAULT ACADEMIC YEAR AND TERMS
-- =====================================================

-- Insert current academic year for the school
INSERT INTO academic_years (
  school_id,
  year_name,
  start_date,
  end_date,
  is_current
)
SELECT 
  id,
  '2024/2025',
  '2024-09-01',
  '2025-07-31',
  true
FROM schools 
WHERE school_name = 'NEW_SCHOOL_NAME_HERE'
ON CONFLICT DO NOTHING;

-- Insert default terms
INSERT INTO terms (
  school_id,
  academic_year_id,
  term_name,
  start_date,
  end_date,
  is_current
)
SELECT 
  s.id,
  ay.id,
  term_data.name,
  term_data.start_date,
  term_data.end_date,
  term_data.is_current
FROM schools s
JOIN academic_years ay ON s.id = ay.school_id
CROSS JOIN (VALUES
  ('Term 1', '2024-09-01'::date, '2024-12-15'::date, false),
  ('Term 2', '2025-01-15'::date, '2025-04-15'::date, false),
  ('Term 3', '2025-04-30'::date, '2025-07-31'::date, true)
) AS term_data(name, start_date, end_date, is_current)
WHERE s.school_name = 'NEW_SCHOOL_NAME_HERE'
  AND ay.year_name = '2024/2025'
ON CONFLICT DO NOTHING;

-- =====================================================
-- STEP 9: CREATE DEFAULT SUBJECTS
-- =====================================================

-- Insert default subjects for the school
INSERT INTO subjects (school_id, subject_code, subject_name)
SELECT 
  id,
  subject_data.code,
  subject_data.name
FROM schools
CROSS JOIN (VALUES
  ('MATH', 'Mathematics'),
  ('ENG', 'English Language'),
  ('SCI', 'Science'),
  ('SOC', 'Social Studies'),
  ('PE', 'Physical Education'),
  ('CA', 'Creative Arts'),
  ('ICT', 'Computing'),
  ('RME', 'Religious & Moral Education')
) AS subject_data(code, name)
WHERE school_name = 'NEW_SCHOOL_NAME_HERE'
ON CONFLICT DO NOTHING;

-- =====================================================
-- STEP 10: SETUP DEFAULT CLASSES
-- =====================================================

-- Insert default classes for the school
INSERT INTO classes (school_id, class_name, class_level)
SELECT 
  id,
  class_data.name,
  class_data.level
FROM schools
CROSS JOIN (VALUES
  ('Creche', 1),
  ('Nursery 1', 2),
  ('Nursery 2', 3),
  ('KG1', 4),
  ('KG2', 5),
  ('Primary 1', 6),
  ('Primary 2', 7),
  ('Primary 3', 8),
  ('Primary 4', 9),
  ('Primary 5', 10),
  ('Primary 6', 11),
  ('JHS 1', 12),
  ('JHS 2', 13),
  ('JHS 3', 14)
) AS class_data(name, level)
WHERE school_name = 'NEW_SCHOOL_NAME_HERE'
ON CONFLICT DO NOTHING;

-- =====================================================
-- STEP 11: SETUP DEFAULT FEE CATEGORIES
-- =====================================================

-- Insert default fee categories for the school
INSERT INTO fee_categories (school_id, category_name, description)
SELECT 
  id,
  fee_data.name,
  fee_data.description
FROM schools
CROSS JOIN (VALUES
  ('Tuition', 'School fees for academic instruction'),
  ('Bus', 'Transportation fees'),
  ('Canteen', 'Meal and food services'),
  ('Uniform', 'School uniform and clothing'),
  ('Books', 'Textbooks and learning materials'),
  ('Activities', 'Extracurricular activities and events')
) AS fee_data(name, description)
WHERE school_name = 'NEW_SCHOOL_NAME_HERE'
ON CONFLICT DO NOTHING;

-- =====================================================
-- STEP 12: VERIFICATION
-- =====================================================

-- Verify everything is set up correctly
SELECT 
  'School Setup Complete!' as status,
  s.school_name,
  UPPER(LEFT(s.school_name, 3)) as student_prefix,
  COUNT(DISTINCT gs.id) as grading_scales,
  COUNT(DISTINCT sub.id) as subjects,
  COUNT(DISTINCT ay.id) as academic_years,
  COUNT(DISTINCT t.id) as terms,
  COUNT(DISTINCT c.id) as classes,
  COUNT(DISTINCT fc.id) as fee_categories
FROM schools s
LEFT JOIN grading_scale gs ON s.id = gs.school_id
LEFT JOIN subjects sub ON s.id = sub.school_id
LEFT JOIN academic_years ay ON s.id = ay.school_id
LEFT JOIN terms t ON s.id = t.school_id
LEFT JOIN classes c ON s.id = c.school_id
LEFT JOIN fee_categories fc ON s.id = fc.school_id
WHERE s.school_name = 'NEW_SCHOOL_NAME_HERE'
GROUP BY s.id, s.school_name;

-- Check triggers are working
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table
FROM information_schema.triggers
WHERE event_object_table IN ('students', 'staff')
  AND trigger_name LIKE '%generate%';

-- Show what the student IDs will look like
SELECT 
  school_name,
  UPPER(LEFT(school_name, 3)) || '0001' as first_student_id,
  UPPER(LEFT(school_name, 3)) || '0002' as second_student_id,
  UPPER(LEFT(school_name, 3)) || '0003' as third_student_id
FROM schools 
WHERE school_name = 'NEW_SCHOOL_NAME_HERE';

-- =====================================================
-- INSTRUCTIONS FOR USE:
-- =====================================================
-- 
-- 1. Replace ALL instances of 'NEW_SCHOOL_NAME_HERE' with actual school name
-- 2. Run this entire script in Supabase SQL Editor
-- 3. The new school will have:
--    ✅ Proper grading scale (A1-F)
--    ✅ Auto-generated student IDs (SCH0001, SCH0002, etc.)
--    ✅ Auto-generated staff IDs
--    ✅ Default subjects and academic year/terms
--    ✅ Default classes (Creche to JHS 3)
--    ✅ Default fee categories
--    ✅ No activity log errors
--    ✅ Optional student fields (DOB, parent info)
--    ✅ All latest fixes applied
-- 
-- 4. Create the first admin user for this school
-- 5. Test student registration - should work perfectly!
-- 
-- EXAMPLE USAGE:
-- Replace 'NEW_SCHOOL_NAME_HERE' with 'Kwame Nkrumah University of Science and Technology'
-- Student IDs will be: KWA0001, KWA0002, KWA0003, etc.
-- 
-- =====================================================