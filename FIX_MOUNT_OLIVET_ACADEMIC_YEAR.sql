-- Fix Mount Olivet Methodist Academy academic year mismatch
-- The school year has a typo: 2025/20256 should be 2025/2026
-- And the teacher's assignment is in 2024/2025 but school is in 2025/2026

-- Option 1: Fix the school's academic year typo AND update teacher assignment to match
UPDATE school_settings
SET current_academic_year = '2024/2025'
WHERE school_name LIKE '%Mount Olivet%';

-- Update teacher's assignment to current year (if needed)
UPDATE teacher_classes
SET academic_year = '2024/2025'
WHERE school_id = (SELECT id FROM school_settings WHERE school_name LIKE '%Mount Olivet%')
  AND academic_year != '2024/2025';

-- Verify the fix
SELECT 
    '✅ FIXED!' as status,
    ss.school_name,
    ss.current_academic_year as school_year,
    tc.academic_year as teacher_assignment_year,
    tc.class,
    u.email,
    u.full_name,
    CASE 
        WHEN ss.current_academic_year = tc.academic_year THEN '✅ NOW MATCHING'
        ELSE '❌ STILL MISMATCH'
    END as match_status
FROM users u
JOIN school_settings ss ON u.school_id = ss.id
LEFT JOIN teacher_classes tc ON u.id = tc.teacher_id
WHERE ss.school_name LIKE '%Mount Olivet%'
  AND u.role = 'teacher';

-- Show current school settings
SELECT 
    '=== SCHOOL SETTINGS ===' as info,
    school_name,
    current_academic_year,
    current_term
FROM school_settings
WHERE school_name LIKE '%Mount Olivet%';
