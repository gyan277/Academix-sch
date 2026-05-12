-- MANUAL FIX: Assign Sir Gyan to Primary 1 at Mount Olivet
-- Run this NOW to test if it's a database issue

-- Step 1: Get the teacher's info
SELECT 
    '=== TEACHER INFO ===' as section,
    u.id as teacher_id,
    u.email,
    u.full_name,
    u.school_id,
    ss.school_name,
    ss.current_academic_year
FROM users u
JOIN school_settings ss ON ss.id = u.school_id
WHERE u.email = 'georgegyan@gmail.com';

-- Step 2: Delete any existing assignment
DELETE FROM teacher_classes
WHERE teacher_id = (SELECT id FROM users WHERE email = 'georgegyan@gmail.com');

-- Step 3: Insert new assignment
INSERT INTO teacher_classes (
    teacher_id,
    class,
    academic_year,
    school_id
)
SELECT 
    u.id,
    'Primary 1',
    ss.current_academic_year,
    u.school_id
FROM users u
JOIN school_settings ss ON ss.id = u.school_id
WHERE u.email = 'georgegyan@gmail.com';

-- Step 4: Verify it was inserted
SELECT 
    '=== VERIFICATION ===' as section,
    tc.id,
    tc.teacher_id,
    u.email,
    u.full_name,
    tc.class,
    tc.academic_year,
    ss.school_name,
    ss.current_academic_year as school_year,
    CASE 
        WHEN tc.academic_year = ss.current_academic_year THEN '✅ YEARS MATCH'
        ELSE '❌ YEAR MISMATCH'
    END as status
FROM teacher_classes tc
JOIN users u ON u.id = tc.teacher_id
JOIN school_settings ss ON ss.id = tc.school_id
WHERE u.email = 'georgegyan@gmail.com';

-- Step 5: Test what the Attendance page query would return
SELECT 
    '=== WHAT ATTENDANCE PAGE WILL SEE ===' as section,
    tc.class
FROM teacher_classes tc
JOIN users u ON u.id = tc.teacher_id
JOIN school_settings ss ON u.school_id = ss.id
WHERE u.email = 'georgegyan@gmail.com'
  AND tc.academic_year = ss.current_academic_year;
