-- =====================================================
-- QUICK NEW SCHOOL SETUP
-- =====================================================
-- Replace 'SCHOOL_NAME_HERE' with the actual school name
-- This will create a complete setup for the new school
-- =====================================================

-- CHANGE THIS LINE - Replace with actual school name
-- Example: 'Mount Olivet Methodist Academy' or 'Kwame Nkrumah University'
\set school_name 'SCHOOL_NAME_HERE'

-- =====================================================
-- AUTOMATED SETUP (DO NOT MODIFY BELOW THIS LINE)
-- =====================================================

-- Create the school
INSERT INTO schools (school_name, created_at)
VALUES (:'school_name', NOW())
ON CONFLICT (school_name) DO NOTHING;

-- Get school ID
DO $$
DECLARE
  new_school_id UUID;
  school_name_var TEXT := :'school_name';
  school_prefix TEXT;
BEGIN
  -- Get the school ID
  SELECT id INTO new_school_id FROM schools WHERE school_name = school_name_var;
  school_prefix := UPPER(LEFT(school_name_var, 3));
  
  RAISE NOTICE '🏫 School: %', school_name_var;
  RAISE NOTICE '🆔 School ID: %', new_school_id;
  RAISE NOTICE '📝 Student ID Prefix: %', school_prefix;
  RAISE NOTICE '📋 Example Student IDs: %0001, %0002, %0003', school_prefix, school_prefix, school_prefix;
END $$;

-- Setup grading scale
INSERT INTO grading_scale (school_id, grade, min_score, max_score)
SELECT 
  (SELECT id FROM schools WHERE school_name = :'school_name'),
  grade, min_score, max_score
FROM (VALUES
  ('A1', 80, 100), ('A2', 75, 79), ('B1', 70, 74), ('B2', 65, 69),
  ('B3', 60, 64), ('C1', 55, 59), ('C2', 50, 54), ('C3', 45, 49),
  ('D1', 40, 44), ('D2', 35, 39), ('E1', 30, 34), ('F', 0, 29)
) AS grades(grade, min_score, max_score)
ON CONFLICT DO NOTHING;

-- Setup academic year
INSERT INTO academic_years (school_id, year_name, start_date, end_date, is_current)
SELECT id, '2024/2025', '2024-09-01', '2025-07-31', true
FROM schools WHERE school_name = :'school_name'
ON CONFLICT DO NOTHING;

-- Setup terms
INSERT INTO terms (school_id, academic_year_id, term_name, start_date, end_date, is_current)
SELECT s.id, ay.id, term_data.name, term_data.start_date, term_data.end_date, term_data.is_current
FROM schools s
JOIN academic_years ay ON s.id = ay.school_id
CROSS JOIN (VALUES
  ('Term 1', '2024-09-01'::date, '2024-12-15'::date, false),
  ('Term 2', '2025-01-15'::date, '2025-04-15'::date, false),
  ('Term 3', '2025-04-30'::date, '2025-07-31'::date, true)
) AS term_data(name, start_date, end_date, is_current)
WHERE s.school_name = :'school_name' AND ay.year_name = '2024/2025'
ON CONFLICT DO NOTHING;

-- Setup subjects
INSERT INTO subjects (school_id, subject_code, subject_name)
SELECT id, subject_data.code, subject_data.name
FROM schools
CROSS JOIN (VALUES
  ('MATH', 'Mathematics'), ('ENG', 'English Language'), ('SCI', 'Science'),
  ('SOC', 'Social Studies'), ('PE', 'Physical Education'), ('CA', 'Creative Arts'),
  ('ICT', 'Computing'), ('RME', 'Religious & Moral Education')
) AS subject_data(code, name)
WHERE school_name = :'school_name'
ON CONFLICT DO NOTHING;

-- Verification
SELECT 
  '✅ SCHOOL SETUP COMPLETE!' as status,
  s.school_name,
  UPPER(LEFT(s.school_name, 3)) as student_prefix,
  COUNT(DISTINCT gs.id) as grading_scales,
  COUNT(DISTINCT sub.id) as subjects,
  COUNT(DISTINCT ay.id) as academic_years,
  COUNT(DISTINCT t.id) as terms
FROM schools s
LEFT JOIN grading_scale gs ON s.id = gs.school_id
LEFT JOIN subjects sub ON s.id = sub.school_id
LEFT JOIN academic_years ay ON s.id = ay.school_id
LEFT JOIN terms t ON s.id = t.school_id
WHERE s.school_name = :'school_name'
GROUP BY s.id, s.school_name;

-- =====================================================
-- USAGE INSTRUCTIONS:
-- =====================================================
-- 
-- 1. Change the school name in line 8:
--    \set school_name 'Your Actual School Name'
-- 
-- 2. Run this script in Supabase SQL Editor
-- 
-- 3. The school will be ready with:
--    ✅ Grading scale (12 grades)
--    ✅ Academic year 2024/2025
--    ✅ 3 terms (Term 3 is current)
--    ✅ 8 default subjects
--    ✅ Auto-generated student IDs
-- 
-- 4. Create admin user and test!
-- 
-- =====================================================