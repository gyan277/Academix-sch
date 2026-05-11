-- Diagnose teacher class assignment issue for new school
-- Run this to see what's happening

-- 1. Check all schools
SELECT 
    id,
    school_name,
    email
FROM school_settings
ORDER BY created_at DESC;

-- 2. Check all teachers and their assignments
SELECT 
    u.id as teacher_id,
    u.email,
    u.full_name,
    u.role,
    u.school_id,
    ss.school_name,
    tc.class as assigned_class,
    tc.academic_year
FROM users u
LEFT JOIN school_settings ss ON u.school_id = ss.id
LEFT JOIN teacher_classes tc ON u.id = tc.teacher_id AND u.school_id = tc.school_id
WHERE u.role = 'teacher'
ORDER BY u.created_at DESC;

-- 3. Check staff table for the teacher
SELECT 
    s.id,
    s.full_name,
    s.position,
    s.school_id,
    ss.school_name,
    s.created_at
FROM staff s
LEFT JOIN school_settings ss ON s.school_id = ss.id
WHERE s.position ILIKE '%teacher%'
ORDER BY s.created_at DESC;

-- 4. Check if teacher_classes record exists
SELECT 
    tc.id,
    tc.teacher_id,
    tc.class,
    tc.academic_year,
    tc.school_id,
    ss.school_name,
    u.email as teacher_email,
    u.full_name as teacher_name
FROM teacher_classes tc
LEFT JOIN school_settings ss ON tc.school_id = ss.id
LEFT JOIN users u ON tc.teacher_id = u.id
ORDER BY tc.created_at DESC;

-- 5. Check what the teacher portal would see (simulate teacher login)
-- Replace 'TEACHER_EMAIL_HERE' with the actual teacher's email
SELECT 
    u.id,
    u.email,
    u.full_name,
    u.role,
    u.school_id,
    ss.school_name,
    tc.class as assigned_class
FROM users u
LEFT JOIN school_settings ss ON u.school_id = ss.id
LEFT JOIN teacher_classes tc ON u.id = tc.teacher_id AND u.school_id = tc.school_id
WHERE u.email = 'TEACHER_EMAIL_HERE';
