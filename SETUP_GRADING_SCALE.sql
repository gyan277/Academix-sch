-- Setup Grading Scale for Mount Olivet Methodist Academy
-- Run this in Supabase SQL Editor

-- First, check if grading scale exists
SELECT * FROM grading_scale WHERE school_id = (
  SELECT id FROM schools WHERE school_name = 'Mount Olivet Methodist Academy' LIMIT 1
);

-- Delete existing grading scale (if any)
DELETE FROM grading_scale 
WHERE school_id = (
  SELECT id FROM schools WHERE school_name = 'Mount Olivet Methodist Academy' LIMIT 1
);

-- Insert proper grading scale
INSERT INTO grading_scale (school_id, grade, min_score, max_score)
SELECT 
  (SELECT id FROM schools WHERE school_name = 'Mount Olivet Methodist Academy' LIMIT 1),
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
) AS grades(grade, min_score, max_score);

-- Verify the grading scale was created
SELECT 
  grade,
  min_score,
  max_score
FROM grading_scale
WHERE school_id = (
  SELECT id FROM schools WHERE school_name = 'Mount Olivet Methodist Academy' LIMIT 1
)
ORDER BY min_score DESC;

-- ✅ After running this, refresh the Academic page and grades will calculate correctly
