-- Fix Academic Year Mismatch
-- The teacher_classes table is using 2026/2027 but the app expects 2024/2025

-- 1. Check what academic years are currently in teacher_classes
SELECT DISTINCT academic_year, COUNT(*) as count
FROM teacher_classes
GROUP BY academic_year;

-- 2. Update all teacher_classes to use 2024/2025
UPDATE teacher_classes
SET academic_year = '2024/2025'
WHERE academic_year != '2024/2025';

-- 3. Verify the update
SELECT 
  tc.id,
  u.email as teacher_email,
  tc.class,
  tc.academic_year,
  tc.created_at
FROM teacher_classes tc
LEFT JOIN users u ON tc.teacher_id = u.id
ORDER BY tc.created_at DESC;

-- 4. Check if teachers can now see their classes
SELECT 
  u.email as teacher_email,
  u.full_name,
  STRING_AGG(tc.class, ', ') as assigned_classes
FROM users u
LEFT JOIN teacher_classes tc ON u.id = tc.teacher_id AND tc.academic_year = '2024/2025'
WHERE u.role = 'teacher'
GROUP BY u.id, u.email, u.full_name;
