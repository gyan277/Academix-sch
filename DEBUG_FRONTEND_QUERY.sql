-- Debug what the frontend query is seeing

-- 1. What's in the database
SELECT 
    '=== DATABASE RECORD ===' as section,
    tc.teacher_id,
    u.email,
    tc.class,
    tc.academic_year as teacher_class_year,
    tc.school_id
FROM teacher_classes tc
JOIN users u ON u.id = tc.teacher_id
WHERE u.email = 'georgegyan@gmail.com';

-- 2. What's the school's current academic year
SELECT 
    '=== SCHOOL SETTINGS ===' as section,
    id as school_id,
    school_name,
    current_academic_year,
    current_term
FROM school_settings
WHERE school_name LIKE '%Mount Olivet%';

-- 3. Simulate the EXACT frontend query
SELECT 
    '=== FRONTEND QUERY SIMULATION ===' as section,
    tc.class
FROM teacher_classes tc
WHERE tc.teacher_id = (SELECT id FROM users WHERE email = 'georgegyan@gmail.com')
  AND tc.academic_year = (
      SELECT current_academic_year 
      FROM school_settings 
      WHERE id = (SELECT school_id FROM users WHERE email = 'georgegyan@gmail.com')
  );

-- 4. Show the mismatch
SELECT 
    '=== THE PROBLEM ===' as section,
    tc.academic_year as "Teacher Assignment Year",
    ss.current_academic_year as "School Current Year",
    CASE 
        WHEN tc.academic_year = ss.current_academic_year THEN '✅ MATCH - Should work'
        ELSE '❌ MISMATCH - This is why it fails!'
    END as status,
    'Frontend filters by school year: ' || ss.current_academic_year as explanation,
    'But teacher_classes has: ' || tc.academic_year as problem
FROM teacher_classes tc
JOIN users u ON u.id = tc.teacher_id
JOIN school_settings ss ON ss.id = u.school_id
WHERE u.email = 'georgegyan@gmail.com';
