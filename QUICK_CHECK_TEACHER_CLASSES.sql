-- Quick check: What classes are assigned to teachers?
-- Run this in Supabase SQL Editor

SELECT 
    u.full_name,
    u.email,
    tc.class,
    tc.academic_year,
    s.school_name
FROM users u
LEFT JOIN teacher_classes tc ON tc.teacher_id = u.id
LEFT JOIN school_settings s ON s.id = u.school_id
WHERE u.role = 'teacher'
ORDER BY u.created_at DESC;
