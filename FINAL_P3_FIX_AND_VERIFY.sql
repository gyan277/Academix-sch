-- FINAL P3 FIX AND VERIFICATION
-- This script will fix any school_id mismatches and verify everything is correct

-- ============================================
-- STEP 1: Check Current State
-- ============================================

-- Sir Isaac's info
SELECT 
  '1. Sir Isaac Info' as step,
  id,
  email,
  full_name,
  role,
  school_id,
  status
FROM users
WHERE email = 'careerghana01@gmail.com';

-- P3 Students current state
SELECT 
  '2. P3 Students Current State' as step,
  id,
  student_number,
  full_name,
  class,
  status,
  school_id
FROM students
WHERE class = 'P3'
ORDER BY full_name;

-- ============================================
-- STEP 2: Fix School ID Mismatch (if any)
-- ============================================

-- Update P3 students to match Sir Isaac's school_id
UPDATE students
SET school_id = (SELECT school_id FROM users WHERE email = 'careerghana01@gmail.com')
WHERE class = 'P3'
  AND school_id != (SELECT school_id FROM users WHERE email = 'careerghana01@gmail.com');

-- ============================================
-- STEP 3: Verify Fix
-- ============================================

-- Check if school_ids now match
SELECT 
  '3. School ID Match Verification' as step,
  'Teacher' as type,
  u.school_id,
  u.email as identifier
FROM users u
WHERE u.email = 'careerghana01@gmail.com'

UNION ALL

SELECT 
  '3. School ID Match Verification' as step,
  'P3 Student' as type,
  s.school_id,
  s.full_name as identifier
FROM students s
WHERE s.class = 'P3'
ORDER BY type, identifier;

-- ============================================
-- STEP 4: Test the Exact Frontend Query
-- ============================================

-- This simulates what the frontend will query
SELECT 
  '4. Frontend Query Simulation' as step,
  s.id,
  s.student_number,
  s.full_name,
  s.class,
  s.status,
  s.school_id
FROM students s
WHERE s.class = 'P3'
  AND s.status = 'active'
  AND s.school_id = (SELECT school_id FROM users WHERE email = 'careerghana01@gmail.com')
ORDER BY s.full_name;

-- ============================================
-- STEP 5: Verify Teacher Assignment
-- ============================================

SELECT 
  '5. Teacher Class Assignment' as step,
  tc.id,
  u.full_name as teacher_name,
  u.email as teacher_email,
  tc.class,
  tc.academic_year,
  tc.created_at
FROM teacher_classes tc
JOIN users u ON tc.teacher_id = u.id
WHERE u.email = 'careerghana01@gmail.com'
  AND tc.academic_year = '2024/2025';

-- ============================================
-- STEP 6: Final Summary
-- ============================================

SELECT 
  '6. Final Summary' as step,
  (SELECT COUNT(*) FROM students WHERE class = 'P3' AND status = 'active') as total_p3_students,
  (SELECT COUNT(*) FROM students WHERE class = 'P3' AND status = 'active' 
   AND school_id = (SELECT school_id FROM users WHERE email = 'careerghana01@gmail.com')) as p3_students_matching_teacher,
  (SELECT COUNT(*) FROM teacher_classes WHERE teacher_id = (SELECT id FROM users WHERE email = 'careerghana01@gmail.com') 
   AND class = 'P3' AND academic_year = '2024/2025') as teacher_assignments_to_p3,
  CASE 
    WHEN (SELECT COUNT(*) FROM students WHERE class = 'P3' AND status = 'active' 
          AND school_id = (SELECT school_id FROM users WHERE email = 'careerghana01@gmail.com')) > 0
    THEN '✅ READY - Sir Isaac should see P3 students'
    ELSE '❌ PROBLEM - No matching students found'
  END as status;
