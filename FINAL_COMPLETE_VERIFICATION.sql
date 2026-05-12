-- FINAL COMPLETE VERIFICATION
-- Run this after NUCLEAR_FIX_TEACHER_DISPLAY.sql to verify everything

-- ============================================
-- COMPREHENSIVE SYSTEM CHECK
-- ============================================

-- 1. School Information
SELECT 
  '1️⃣ School Info' as check,
  id,
  school_name,
  school_prefix,
  current_academic_year,
  current_term
FROM schools
WHERE school_name LIKE '%Mount Olivet%';

-- 2. Teacher Account
SELECT 
  '2️⃣ Teacher Account' as check,
  id,
  email,
  full_name,
  role,
  school_id,
  CASE 
    WHEN school_id IS NOT NULL THEN '✅ Has school_id'
    ELSE '❌ Missing school_id'
  END as school_status
FROM users
WHERE email = 'georgegyan@gmail.com';

-- 3. Teacher Class Assignment
SELECT 
  '3️⃣ Class Assignment' as check,
  tc.id,
  tc.teacher_id,
  tc.class,
  tc.academic_year,
  tc.school_id,
  u.email as teacher_email,
  s.school_name,
  CASE 
    WHEN tc.academic_year = s.current_academic_year THEN '✅ Year matches'
    ELSE '⚠️ Year mismatch: ' || tc.academic_year || ' vs ' || s.current_academic_year
  END as year_status
FROM teacher_classes tc
JOIN users u ON u.id = tc.teacher_id
JOIN schools s ON s.id = tc.school_id
WHERE u.email = 'georgegyan@gmail.com';

-- 4. RLS Policies on teacher_classes
SELECT 
  '4️⃣ RLS Policies' as check,
  policyname,
  cmd as operation,
  CASE 
    WHEN cmd = 'SELECT' THEN '✅ Read access'
    WHEN cmd = 'ALL' THEN '✅ Full access'
    ELSE cmd
  END as access_type,
  CASE 
    WHEN policyname LIKE '%teacher%' THEN '👨‍🏫 For teachers'
    WHEN policyname LIKE '%admin%' THEN '👨‍💼 For admins'
    ELSE 'Other'
  END as target_role
FROM pg_policies
WHERE tablename = 'teacher_classes'
ORDER BY policyname;

-- 5. Test Frontend Query (Exact simulation)
SELECT 
  '5️⃣ Frontend Query Test' as check,
  class,
  academic_year,
  '✅ This is what frontend should see' as status
FROM teacher_classes
WHERE teacher_id = '3d40ae98-73c1-438c-840a-e058a87a0af9';

-- 6. Students in Primary 1 (Mount Olivet)
SELECT 
  '6️⃣ Students in Class' as check,
  COUNT(*) as student_count,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ Has students'
    ELSE '⚠️ No students in class'
  END as status
FROM students
WHERE class = 'Primary 1'
AND school_id = (
  SELECT school_id FROM users WHERE email = 'georgegyan@gmail.com'
)
AND status = 'active';

-- 7. Subjects for Primary 1
SELECT 
  '7️⃣ Subjects for Class' as check,
  s.subject_name,
  cs.academic_year,
  cs.is_active
FROM class_subjects cs
JOIN subjects s ON s.id = cs.subject_id
WHERE cs.class = 'Primary 1'
AND cs.school_id = (
  SELECT school_id FROM users WHERE email = 'georgegyan@gmail.com'
)
AND cs.is_active = true;

-- 8. Overall System Status
SELECT 
  '8️⃣ System Status' as check,
  CASE 
    WHEN (
      SELECT COUNT(*) FROM teacher_classes 
      WHERE teacher_id = '3d40ae98-73c1-438c-840a-e058a87a0af9'
    ) > 0 THEN '✅ PASS: Teacher has class assignment'
    ELSE '❌ FAIL: No class assignment found'
  END as assignment_status,
  CASE 
    WHEN (
      SELECT COUNT(*) FROM pg_policies 
      WHERE tablename = 'teacher_classes' 
      AND cmd = 'SELECT'
    ) > 0 THEN '✅ PASS: RLS policies exist'
    ELSE '❌ FAIL: No RLS policies'
  END as rls_status,
  CASE 
    WHEN (
      SELECT COUNT(*) FROM students 
      WHERE class = 'Primary 1'
      AND school_id = (SELECT school_id FROM users WHERE email = 'georgegyan@gmail.com')
      AND status = 'active'
    ) > 0 THEN '✅ PASS: Students exist in class'
    ELSE '⚠️ WARNING: No students in class'
  END as students_status;

-- 9. Expected Console Output
SELECT 
  '9️⃣ Expected Browser Console' as check,
  '🔍 Loading teacher classes for: 3d40ae98-73c1-438c-840a-e058a87a0af9 georgegyan@gmail.com' as line1,
  '📚 Teacher classes query result: { assignments: [{class: "Primary 1"}], error: null }' as line2,
  '✅ Found classes: ["Primary 1"]' as line3;

-- 10. Action Items
SELECT 
  '🔟 Action Items' as check,
  CASE 
    WHEN (SELECT COUNT(*) FROM teacher_classes WHERE teacher_id = '3d40ae98-73c1-438c-840a-e058a87a0af9') = 0
    THEN '❌ CRITICAL: Run NUCLEAR_FIX_TEACHER_DISPLAY.sql first!'
    WHEN (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'teacher_classes' AND cmd = 'SELECT') = 0
    THEN '❌ CRITICAL: RLS policies missing! Run NUCLEAR_FIX_TEACHER_DISPLAY.sql'
    ELSE '✅ Database is ready. Next steps:
    1. Verify Netlify deployment is complete
    2. Have teacher hard refresh browser (Ctrl+Shift+R)
    3. Check browser console for debug messages
    4. Check Network tab for API response'
  END as next_steps;
