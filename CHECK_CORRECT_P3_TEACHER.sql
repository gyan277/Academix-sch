-- Check which teacher should be assigned to P3
-- and verify the assignment

-- 1. Show ALL teachers and their assigned classes
SELECT 
  u.email,
  u.full_name,
  u.role,
  STRING_AGG(tc.class, ', ') as assigned_classes,
  tc.academic_year
FROM users u
LEFT JOIN teacher_classes tc ON u.id = tc.teacher_id
WHERE u.role = 'teacher'
GROUP BY u.id, u.email, u.full_name, u.role, tc.academic_year
ORDER BY u.created_at DESC;

-- 2. Show specifically who is assigned to P3
SELECT 
  'Teachers assigned to P3' as info,
  u.email,
  u.full_name,
  tc.class,
  tc.academic_year,
  tc.created_at as assignment_date
FROM teacher_classes tc
JOIN users u ON tc.teacher_id = u.id
WHERE tc.class = 'P3'
ORDER BY tc.created_at DESC;

-- 3. Show all teachers (to find the correct one)
SELECT 
  'All teachers' as info,
  id,
  email,
  full_name,
  created_at
FROM users
WHERE role = 'teacher'
ORDER BY created_at DESC;

-- 4. If you need to reassign P3 to a different teacher:
-- First, delete the wrong assignment:
-- DELETE FROM teacher_classes WHERE class = 'P3';

-- Then, insert the correct assignment (replace 'CORRECT-TEACHER-ID' with actual teacher's user ID):
-- INSERT INTO teacher_classes (teacher_id, class, academic_year)
-- VALUES ('CORRECT-TEACHER-ID', 'P3', '2024/2025');

-- Example: If the correct teacher email is 'teacher@example.com':
-- INSERT INTO teacher_classes (teacher_id, class, academic_year)
-- SELECT id, 'P3', '2024/2025'
-- FROM users
-- WHERE email = 'teacher@example.com' AND role = 'teacher';
