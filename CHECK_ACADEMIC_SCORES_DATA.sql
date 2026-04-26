-- Check if there's any academic scores data in the database
-- This will help diagnose why Reports page shows 0.0% school average

-- 1. Check if academic_scores table has any data
SELECT 
  COUNT(*) as total_records,
  COUNT(DISTINCT school_id) as schools_with_scores,
  COUNT(DISTINCT student_id) as students_with_scores,
  COUNT(DISTINCT class) as classes_with_scores
FROM academic_scores;

-- 2. Check academic scores by school
SELECT 
  s.name as school_name,
  COUNT(acs.id) as score_records,
  COUNT(DISTINCT acs.student_id) as students_assessed,
  COUNT(DISTINCT acs.class) as classes_assessed,
  acs.academic_year,
  acs.term
FROM academic_scores acs
JOIN schools s ON s.id = acs.school_id
GROUP BY s.name, acs.academic_year, acs.term
ORDER BY s.name, acs.academic_year, acs.term;

-- 3. Check sample academic scores data
SELECT 
  st.full_name as student_name,
  st.class,
  sub.name as subject,
  acs.class_score,
  acs.exam_score,
  acs.total_score,
  acs.grade,
  acs.academic_year,
  acs.term,
  acs.grading_period
FROM academic_scores acs
JOIN students st ON st.id = acs.student_id
JOIN subjects sub ON sub.id = acs.subject_id
ORDER BY st.class, st.full_name, sub.name
LIMIT 20;

-- 4. Check school settings for current academic year and term
SELECT 
  s.name as school_name,
  ss.current_academic_year,
  ss.current_term
FROM school_settings ss
JOIN schools s ON s.id = ss.school_id;

-- 5. Calculate what the school average SHOULD be
SELECT 
  acs.academic_year,
  acs.term,
  COUNT(DISTINCT acs.student_id) as total_students,
  COUNT(DISTINCT acs.class) as classes_assessed,
  ROUND(AVG(acs.total_score), 1) as school_average,
  MAX(student_avg.avg_score) as top_performer_score
FROM academic_scores acs
LEFT JOIN (
  SELECT 
    student_id,
    AVG(total_score) as avg_score
  FROM academic_scores
  GROUP BY student_id
) student_avg ON student_avg.student_id = acs.student_id
GROUP BY acs.academic_year, acs.term;
