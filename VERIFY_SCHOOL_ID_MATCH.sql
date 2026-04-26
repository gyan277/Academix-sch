-- Quick verification that school_ids match

-- Sir Isaac's school_id
SELECT 
  'Sir Isaac' as person,
  school_id,
  email
FROM users
WHERE email = 'careerghana01@gmail.com';

-- P3 Students' school_ids
SELECT 
  'P3 Students' as person,
  school_id,
  COUNT(*) as count,
  STRING_AGG(full_name, ', ') as students
FROM students
WHERE class = 'P3'
GROUP BY school_id;

-- If they don't match, run this fix:
UPDATE students
SET school_id = (SELECT school_id FROM users WHERE email = 'careerghana01@gmail.com')
WHERE class = 'P3';

-- Then verify again:
SELECT 
  'After Fix' as status,
  s.school_id as student_school_id,
  u.school_id as teacher_school_id,
  CASE 
    WHEN s.school_id = u.school_id THEN 'MATCH ✓'
    ELSE 'MISMATCH ✗'
  END as match_status,
  COUNT(s.id) as student_count
FROM students s
CROSS JOIN users u
WHERE s.class = 'P3'
  AND u.email = 'careerghana01@gmail.com'
GROUP BY s.school_id, u.school_id;
