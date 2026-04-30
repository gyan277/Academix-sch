-- Check the grading scale configuration
SELECT 
  grade,
  min_score,
  max_score,
  school_id
FROM grading_scale
ORDER BY min_score DESC;

-- Check if there's a grading scale set up
SELECT COUNT(*) as grading_scale_count
FROM grading_scale;

-- Check what grades are being assigned
SELECT 
  total_score,
  grade,
  COUNT(*) as count
FROM academic_scores
GROUP BY total_score, grade
ORDER BY total_score DESC;
