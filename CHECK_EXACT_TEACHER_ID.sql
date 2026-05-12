-- Check the exact teacher_id that the frontend would use

-- 1. Get Sir Gyan's user ID
SELECT 
    '=== SIR GYAN USER ACCOUNT ===' as section,
    id as user_id,
    email,
    full_name,
    role,
    school_id
FROM users
WHERE email = 'georgegyan@gmail.com';

-- 2. Check if teacher_classes has a record with this exact ID
SELECT 
    '=== TEACHER_CLASSES RECORD ===' as section,
    tc.id,
    tc.teacher_id,
    tc.class,
    tc.academic_year,
    tc.school_id,
    tc.created_at
FROM teacher_classes tc
WHERE tc.teacher_id = (SELECT id FROM users WHERE email = 'georgegyan@gmail.com');

-- 3. Check staff table for Sir Gyan
SELECT 
    '=== STAFF TABLE ===' as section,
    id,
    full_name,
    position,
    school_id
FROM staff
WHERE full_name ILIKE '%gyan%';

-- 4. Simulate the exact Registrar query
SELECT 
    '=== WHAT REGISTRAR SEES ===' as section,
    s.id as staff_id,
    s.full_name as staff_name,
    u.id as user_id,
    u.email,
    tc.class as assigned_class
FROM staff s
LEFT JOIN users u ON 
    LOWER(TRIM(u.full_name)) = LOWER(TRIM(s.full_name))
    AND u.role = 'teacher'
    AND u.school_id = s.school_id
LEFT JOIN teacher_classes tc ON 
    tc.teacher_id = u.id
    AND tc.school_id = s.school_id
WHERE s.full_name ILIKE '%gyan%';
