-- Comprehensive diagnostic for class assignment display issue
-- Run this in Supabase SQL Editor

-- 1. Check what the frontend sees when loading staff
SELECT 
    s.id as staff_id,
    s.full_name as staff_name,
    s.position,
    s.school_id as staff_school_id,
    s.status
FROM staff s
WHERE s.status = 'active'
ORDER BY s.full_name;

-- 2. Check users table for matching teacher accounts
SELECT 
    u.id as user_id,
    u.full_name as user_name,
    u.email,
    u.role,
    u.school_id as user_school_id
FROM users u
WHERE u.role = 'teacher'
ORDER BY u.full_name;

-- 3. Check teacher_classes assignments
SELECT 
    tc.id,
    tc.teacher_id,
    u.full_name as teacher_name,
    u.email,
    tc.class as assigned_class,
    tc.academic_year,
    tc.school_id,
    tc.created_at
FROM teacher_classes tc
JOIN users u ON u.id = tc.teacher_id
ORDER BY tc.created_at DESC;

-- 4. FULL JOIN to see the complete picture
SELECT 
    s.full_name as staff_name,
    s.position,
    s.school_id as staff_school_id,
    u.id as user_id,
    u.full_name as user_name,
    u.email,
    u.role,
    u.school_id as user_school_id,
    tc.class as assigned_class,
    tc.academic_year,
    CASE 
        WHEN u.id IS NULL THEN '❌ No user account'
        WHEN tc.class IS NULL THEN '⚠️ No class assignment'
        ELSE '✅ Complete'
    END as status
FROM staff s
LEFT JOIN users u ON LOWER(TRIM(u.full_name)) = LOWER(TRIM(s.full_name)) 
    AND u.school_id = s.school_id
    AND u.role = 'teacher'
LEFT JOIN teacher_classes tc ON tc.teacher_id = u.id 
    AND tc.school_id = s.school_id
WHERE s.status = 'active' 
    AND s.position ILIKE '%teacher%'
ORDER BY s.full_name;

-- 5. Check for name matching issues (case sensitivity, extra spaces)
SELECT 
    s.full_name as staff_name,
    u.full_name as user_name,
    s.full_name = u.full_name as exact_match,
    LOWER(TRIM(s.full_name)) = LOWER(TRIM(u.full_name)) as case_insensitive_match,
    LENGTH(s.full_name) as staff_name_length,
    LENGTH(u.full_name) as user_name_length
FROM staff s
CROSS JOIN users u
WHERE s.status = 'active' 
    AND s.position ILIKE '%teacher%'
    AND u.role = 'teacher'
    AND s.school_id = u.school_id
    AND LOWER(TRIM(s.full_name)) = LOWER(TRIM(u.full_name));
