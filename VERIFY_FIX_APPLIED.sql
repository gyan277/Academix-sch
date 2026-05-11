-- Verify the fix was applied correctly

-- 1. Check current state
SELECT 
    '=== CURRENT STATE ===' as section,
    ss.school_name,
    ss.current_academic_year as school_year,
    u.email as teacher_email,
    u.full_name as teacher_name,
    tc.class as assigned_class,
    tc.academic_year as teacher_assignment_year,
    CASE 
        WHEN ss.current_academic_year = tc.academic_year THEN '✅ MATCHING'
        ELSE '❌ MISMATCH - Still broken!'
    END as status
FROM users u
JOIN school_settings ss ON u.school_id = ss.id
LEFT JOIN teacher_classes tc ON u.id = tc.teacher_id
WHERE u.email = 'georgegyan@gmail.com';

-- 2. Check if RPC function works
SELECT 
    '=== RPC FUNCTION TEST ===' as section,
    *
FROM get_teacher_class(
    (SELECT id FROM users WHERE email = 'georgegyan@gmail.com')
);

-- 3. Simulate what the Attendance page query would return
SELECT 
    '=== WHAT ATTENDANCE PAGE SEES ===' as section,
    tc.class,
    tc.academic_year,
    ss.current_academic_year as school_current_year
FROM teacher_classes tc
JOIN users u ON u.id = tc.teacher_id
JOIN school_settings ss ON u.school_id = ss.id
WHERE u.email = 'georgegyan@gmail.com'
  AND tc.academic_year = ss.current_academic_year;  -- This is the filter that was failing

-- 4. If still not working, show what needs to be fixed
SELECT 
    '=== DIAGNOSIS ===' as section,
    CASE 
        WHEN COUNT(*) = 0 THEN '❌ No teacher_classes record found at all!'
        WHEN COUNT(*) > 0 AND MAX(tc.academic_year) != MAX(ss.current_academic_year) 
            THEN '❌ Academic year mismatch: teacher=' || MAX(tc.academic_year) || ' school=' || MAX(ss.current_academic_year)
        ELSE '✅ Everything looks good - teacher needs to refresh page'
    END as diagnosis
FROM users u
JOIN school_settings ss ON u.school_id = ss.id
LEFT JOIN teacher_classes tc ON u.id = tc.teacher_id
WHERE u.email = 'georgegyan@gmail.com';
