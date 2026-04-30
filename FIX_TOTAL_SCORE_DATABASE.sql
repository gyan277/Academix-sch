-- COMPLETE FIX for total_score column error
-- Run this in Supabase SQL Editor

-- Step 1: Drop the existing total_score column
ALTER TABLE academic_scores 
DROP COLUMN IF EXISTS total_score CASCADE;

-- Step 2: Add it back as a STORED generated column (not GENERATED ALWAYS)
-- This allows the database to calculate it automatically
ALTER TABLE academic_scores 
ADD COLUMN total_score DECIMAL(5,2) 
GENERATED ALWAYS AS (COALESCE(class_score, 0) + COALESCE(exam_score, 0)) STORED;

-- Step 3: Verify the fix
SELECT 
  column_name, 
  data_type,
  is_generated,
  generation_expression
FROM information_schema.columns
WHERE table_name = 'academic_scores' 
  AND column_name IN ('class_score', 'exam_score', 'total_score');

-- Step 4: Test with a sample query
SELECT 
  student_id,
  class_score,
  exam_score,
  total_score,
  grade
FROM academic_scores
LIMIT 5;

-- ✅ After running this, the frontend code (already fixed) will work correctly
-- The database will auto-calculate total_score from class_score + exam_score
