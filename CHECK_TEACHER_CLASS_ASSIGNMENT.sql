-- Check Teacher Class Assignments
-- Run this to see if teachers have classes assigned

-- Check all teachers and their class assignments
SELECT 
  t.id,
  t.full_name,
  t.class_assigned,
  u.email,
  u.role,
  t.school_id
FROM teachers t
JOIN users u ON t.user_id = u.id
ORDER BY t.full_name;

-- Check if class_assigned is NULL or empty
SELECT 
  COUNT(*) as total_teachers,
  COUNT(class_assigned) as teachers_with_class,
  COUNT(*) - COUNT(class_assigned) as teachers_without_class
FROM teachers;

-- Show teachers without class assignment
SELECT 
  t.id,
  t.full_name,
  t.class_assigned,
  u.email
FROM teachers t
JOIN users u ON t.user_id = u.id
WHERE t.class_assigned IS NULL OR t.class_assigned = '';
