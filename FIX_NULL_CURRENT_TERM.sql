-- Fix NULL current_term in school_settings
-- Set default term to "Term 1" for all schools

UPDATE school_settings
SET current_term = 'Term 1'
WHERE current_term IS NULL;

-- Verify the update
SELECT 
  s.name as school_name,
  ss.current_academic_year,
  ss.current_term
FROM school_settings ss
JOIN schools s ON s.id = ss.school_id;
