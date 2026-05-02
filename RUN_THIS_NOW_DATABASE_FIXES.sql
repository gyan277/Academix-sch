-- ============================================
-- RUN THIS IN SUPABASE SQL EDITOR NOW
-- ============================================
-- This fixes 2 issues:
-- 1. Total score column error
-- 2. All grades showing "F"
-- ============================================

-- ============================================
-- FIX 1: Total Score Column
-- ============================================
-- Drop and recreate total_score as auto-calculated column

ALTER TABLE academic_scores 
DROP COLUMN IF EXISTS total_score CASCADE;

ALTER TABLE academic_scores 
ADD COLUMN total_score DECIMAL(5,2) 
GENERATED ALWAYS AS (COALESCE(class_score, 0) + COALESCE(exam_score, 0)) STORED;

-- Verify the fix
SELECT 
  column_name, 
  is_generated,
  generation_expression
FROM information_schema.columns
WHERE table_name = 'academic_scores' 
  AND column_name = 'total_score';

-- ============================================
-- FIX 2: Setup Grading Scale
-- ============================================
-- This creates the grading scale for your school

-- First, delete any existing grading scale
DELETE FROM grading_scale 
WHERE school_id = (
  SELECT id FROM schools WHERE school_name = 'Mount Olivet Methodist Academy' LIMIT 1
);

-- Insert the default grading scale
INSERT INTO grading_scale (school_id, grade, min_score, max_score)
SELECT 
  (SELECT id FROM schools WHERE school_name = 'Mount Olivet Methodist Academy' LIMIT 1),
  grade,
  min_score,
  max_score
FROM (VALUES
  ('A1', 80, 100),
  ('B2', 75, 79),
  ('B3', 70, 74),
  ('C4', 65, 69),
  ('C5', 60, 64),
  ('C6', 55, 59),
  ('D7', 50, 54),
  ('E8', 41, 49),
  ('F9', 0, 40),
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

-- ============================================
-- VERIFICATION
-- ============================================

-- Check if total_score is now auto-calculated
SELECT 
  student_id,
  class_score,
  exam_score,
  total_score,
  grade
FROM academic_scores
LIMIT 5;

-- Check grading scale count
SELECT COUNT(*) as grading_scale_count
FROM grading_scale
WHERE school_id = (
  SELECT id FROM schools WHERE school_name = 'Mount Olivet Methodist Academy' LIMIT 1
);

-- ============================================
-- ✅ AFTER RUNNING THIS:
-- ============================================
-- 1. Go to Academic page
-- 2. Try saving scores - should work without error
-- 3. Grades should show correctly (A1, B2, etc.) not all "F"
-- 4. Go to Settings → Grades to customize if needed
-- ============================================
