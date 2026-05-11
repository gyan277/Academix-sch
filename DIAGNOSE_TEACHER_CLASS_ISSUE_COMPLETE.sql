-- Complete diagnosis of teacher class assignment issue
-- Run this to see exactly what's wrong

-- 1. Check the teacher's account details
SELECT 
    '=== TEACHER ACCOUNT ===' as section,
    u.id,
    u.email,
    u.full_name,
    u.role,
    u.school_id,
    ss.school_name,
    ss.current_academic_year
FROM users u
LEFT JOIN school_settings ss ON u.school_id = ss.id
WHERE u.email = 'georgegyan@gmail.com';

-- 2. Check teacher_classes table for this teacher
SELECT 
    '=== TEACHER_CLASSES TABLE ===' as section,
    tc.id,
    tc.teacher_id,
    tc.class,
    tc.academic_year,
    tc.school_id,
    tc.created_at
FROM teacher_classes tc
JOIN users u ON u.id = tc.teacher_id
WHERE u.email = 'georgegyan@gmail.com';

-- 3. Check what academic year the school is using
SELECT 
    '=== SCHOOL SETTINGS ===' as section,
    id,
    school_name,
    current_academic_year,
    current_term
FROM school_settings
WHERE school_name LIKE '%Mount Olivet%';

-- 4. Test the RPC function
SELECT 
    '=== RPC FUNCTION TEST ===' as section,
    * 
FROM get_teacher_class(
    (SELECT id FROM users WHERE email = 'georgegyan@gmail.com')
);

-- 5. Check if there's an academic year mismatch
SELECT 
    '=== ACADEMIC YEAR MISMATCH CHECK ===' as section,
    ss.school_name,
    ss.current_academic_year as school_academic_year,
    tc.academic_year as teacher_class_academic_year,
    CASE 
        WHEN ss.current_academic_year = tc.academic_year THEN '✅ MATCH'
        ELSE '❌ MISMATCH - This is the problem!'
    END as status
FROM users u
JOIN school_settings ss ON u.school_id = ss.id
LEFT JOIN teacher_classes tc ON u.id = tc.teacher_id
WHERE u.email = 'georgegyan@gmail.com';

-- 6. Show all teacher assignments for this school
SELECT 
    '=== ALL TEACHERS AT THIS SCHOOL ===' as section,
    u.email,
    u.full_name,
    tc.class,
    tc.academic_year,
    ss.current_academic_year as school_year
FROM users u
JOIN school_settings ss ON u.school_id = ss.id
LEFT JOIN teacher_classes tc ON u.id = tc.teacher_id
WHERE ss.school_name LIKE '%Mount Olivet%'
  AND u.role = 'teacher'
ORDER BY u.created_at DESC;
