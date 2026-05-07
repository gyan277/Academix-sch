-- Check what's actually stored in teacher_classes table
-- Run this in Supabase SQL Editor

-- Check the most recent teacher class assignments
SELECT 
    tc.id,
    tc.teacher_id,
    u.full_name as teacher_name,
    tc.class as assigned_class,
    tc.academic_year,
    tc.school_id,
    tc.created_at
FROM teacher_classes tc
JOIN users u ON u.id = tc.teacher_id
ORDER BY tc.created_at DESC
LIMIT 10;

-- Also check if there are any duplicate assignments
SELECT 
    teacher_id,
    u.full_name,
    COUNT(*) as assignment_count,
    STRING_AGG(class, ', ') as all_classes
FROM teacher_classes tc
JOIN users u ON u.id = tc.teacher_id
GROUP BY teacher_id, u.full_name
HAVING COUNT(*) > 1;
