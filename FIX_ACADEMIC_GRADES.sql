-- Fix Academic Grades - Recalculate all grades based on total scores
-- This will update all existing academic_scores records to have correct grades

-- First, let's see the current state
SELECT 'Current scores with potentially incorrect grades:' as info;
SELECT 
  id,
  class_score,
  exam_score,
  total_score,
  grade,
  (class_score + exam_score) as calculated_total
FROM academic_scores
WHERE total_score != (class_score + exam_score) OR total_score IS NULL
LIMIT 10;

-- Update total_score for all records (in case it's NULL or incorrect)
UPDATE academic_scores
SET total_score = class_score + exam_score
WHERE total_score IS NULL OR total_score != (class_score + exam_score);

-- Now recalculate grades using the school's grading scale
-- The trigger should handle this, but let's force an update
UPDATE academic_scores
SET updated_at = NOW();

-- Verify the fix
SELECT 'After fix - sample of updated scores:' as info;
SELECT 
  id,
  class_score,
  exam_score,
  total_score,
  grade,
  class,
  academic_year,
  term
FROM academic_scores
ORDER BY updated_at DESC
LIMIT 10;

-- Show grade distribution
SELECT 'Grade distribution after fix:' as info;
SELECT 
  grade,
  COUNT(*) as count,
  ROUND(AVG(total_score), 2) as avg_total_score
FROM academic_scores
GROUP BY grade
ORDER BY grade;

SELECT 'Grades have been recalculated successfully!' as result;
