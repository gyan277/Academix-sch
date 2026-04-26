-- Reassign P3 class to Sir Isaac (careerghana01@gmail.com)
-- Remove from Sir Chris and assign to Sir Isaac

-- 1. First, remove P3 from any current assignments
DELETE FROM teacher_classes 
WHERE class = 'P3';

-- 2. Assign P3 to Sir Isaac (careerghana01@gmail.com)
INSERT INTO teacher_classes (teacher_id, class, academic_year)
SELECT id, 'P3', '2024/2025'
FROM users
WHERE email = 'careerghana01@gmail.com' AND role = 'teacher';

-- 3. Verify the assignment
SELECT 
  'Verification - P3 is now assigned to:' as info,
  u.email,
  u.full_name,
  tc.class,
  tc.academic_year
FROM teacher_classes tc
JOIN users u ON tc.teacher_id = u.id
WHERE tc.class = 'P3';

-- 4. Show all teacher assignments
SELECT 
  u.email,
  u.full_name,
  STRING_AGG(tc.class, ', ') as assigned_classes
FROM users u
LEFT JOIN teacher_classes tc ON u.id = tc.teacher_id
WHERE u.role = 'teacher'
GROUP BY u.id, u.email, u.full_name
ORDER BY u.full_name;
