-- =====================================================
-- COMPREHENSIVE MULTI-TENANCY VERIFICATION
-- =====================================================
-- This script checks if multi-tenancy is working properly
-- across all tables and systems

-- =====================================================
-- 1. SCHOOL DISTRIBUTION CHECK
-- =====================================================

SELECT 
  '🏫 SCHOOL DISTRIBUTION ANALYSIS' as check_type;

-- Check how many schools exist
SELECT 
  'Total Schools:' as metric,
  COUNT(*) as count,
  string_agg(school_name, ', ') as school_names
FROM public.school_settings;

-- Check school_id distribution across users
SELECT 
  '👥 USER DISTRIBUTION BY SCHOOL:' as info;

SELECT 
  ss.school_name,
  ss.id as school_id,
  COUNT(u.id) as user_count,
  string_agg(DISTINCT u.role, ', ') as roles_present
FROM public.school_settings ss
LEFT JOIN public.users u ON u.school_id = ss.id
GROUP BY ss.id, ss.school_name
ORDER BY ss.school_name;

-- =====================================================
-- 2. STUDENT DISTRIBUTION CHECK
-- =====================================================

SELECT 
  '🎓 STUDENT DISTRIBUTION BY SCHOOL:' as info;

SELECT 
  ss.school_name,
  ss.id as school_id,
  COUNT(s.id) as student_count,
  COUNT(DISTINCT s.class) as unique_classes,
  string_agg(DISTINCT s.class, ', ') as classes_present
FROM public.school_settings ss
LEFT JOIN public.students s ON s.school_id = ss.id AND s.status = 'active'
GROUP BY ss.id, ss.school_name
ORDER BY ss.school_name;

-- =====================================================
-- 3. STAFF DISTRIBUTION CHECK
-- =====================================================

SELECT 
  '👨‍🏫 STAFF DISTRIBUTION BY SCHOOL:' as info;

SELECT 
  ss.school_name,
  ss.id as school_id,
  COUNT(st.id) as staff_count,
  COUNT(CASE WHEN st.position ILIKE '%teacher%' THEN 1 END) as teacher_count,
  COUNT(CASE WHEN st.position NOT ILIKE '%teacher%' THEN 1 END) as other_staff_count
FROM public.school_settings ss
LEFT JOIN public.staff st ON st.school_id = ss.id AND st.status = 'active'
GROUP BY ss.id, ss.school_name
ORDER BY ss.school_name;

-- =====================================================
-- 4. TEACHER CLASS ASSIGNMENT CHECK
-- =====================================================

SELECT 
  '📚 TEACHER CLASS ASSIGNMENTS BY SCHOOL:' as info;

SELECT 
  ss.school_name,
  tc.class,
  u.full_name as teacher_name,
  u.role,
  tc.academic_year
FROM public.school_settings ss
LEFT JOIN public.teacher_classes tc ON tc.school_id = ss.id
LEFT JOIN public.users u ON u.id = tc.teacher_id
WHERE tc.id IS NOT NULL
ORDER BY ss.school_name, tc.class, u.full_name;

-- =====================================================
-- 5. CROSS-SCHOOL CONTAMINATION CHECK
-- =====================================================

SELECT 
  '🚨 CROSS-SCHOOL CONTAMINATION CHECK:' as alert;

-- Check for users with NULL school_id (bad)
SELECT 
  'Users with NULL school_id:' as issue,
  COUNT(*) as count,
  CASE 
    WHEN COUNT(*) = 0 THEN '✅ GOOD - No NULL school_ids'
    ELSE '❌ BAD - Users missing school_id'
  END as status
FROM public.users 
WHERE school_id IS NULL;

-- Check for students with NULL school_id (bad)
SELECT 
  'Students with NULL school_id:' as issue,
  COUNT(*) as count,
  CASE 
    WHEN COUNT(*) = 0 THEN '✅ GOOD - No NULL school_ids'
    ELSE '❌ BAD - Students missing school_id'
  END as status
FROM public.students 
WHERE school_id IS NULL AND status = 'active';

-- Check for staff with NULL school_id (bad)
SELECT 
  'Staff with NULL school_id:' as issue,
  COUNT(*) as count,
  CASE 
    WHEN COUNT(*) = 0 THEN '✅ GOOD - No NULL school_ids'
    ELSE '❌ BAD - Staff missing school_id'
  END as status
FROM public.staff 
WHERE school_id IS NULL AND status = 'active';

-- =====================================================
-- 6. RLS POLICY STATUS CHECK
-- =====================================================

SELECT 
  '🔒 ROW LEVEL SECURITY STATUS:' as info;

SELECT 
  schemaname,
  tablename,
  CASE 
    WHEN rowsecurity THEN '✅ ENABLED'
    ELSE '❌ DISABLED'
  END as rls_status,
  (SELECT COUNT(*) FROM pg_policies WHERE tablename = c.relname) as policy_count
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' 
  AND c.relname IN ('users', 'students', 'staff', 'teacher_classes', 'academic_scores', 'payments', 'fee_collections')
  AND c.relkind = 'r'
ORDER BY c.relname;

-- =====================================================
-- 7. SPECIFIC POLICY DETAILS
-- =====================================================

SELECT 
  '📋 RLS POLICIES DETAILS:' as info;

SELECT 
  tablename,
  policyname,
  cmd as command_type,
  CASE 
    WHEN roles = '{authenticated}' THEN '✅ Authenticated users'
    ELSE roles::text
  END as applies_to
FROM pg_policies 
WHERE schemaname = 'public'
  AND tablename IN ('students', 'staff', 'users', 'teacher_classes')
ORDER BY tablename, policyname;

-- =====================================================
-- 8. SAMPLE DATA ISOLATION TEST
-- =====================================================

SELECT 
  '🧪 DATA ISOLATION TEST:' as info;

-- Show sample of what each school can see
WITH school_data AS (
  SELECT 
    ss.school_name,
    ss.id as school_id,
    (SELECT COUNT(*) FROM public.students s WHERE s.school_id = ss.id AND s.status = 'active') as students,
    (SELECT COUNT(*) FROM public.staff st WHERE st.school_id = ss.id AND st.status = 'active') as staff,
    (SELECT COUNT(*) FROM public.users u WHERE u.school_id = ss.id) as users
  FROM public.school_settings ss
)
SELECT 
  school_name,
  school_id,
  students,
  staff,
  users,
  CASE 
    WHEN students > 0 AND staff > 0 AND users > 0 THEN '✅ ACTIVE SCHOOL'
    WHEN students = 0 AND staff = 0 AND users = 0 THEN '⚠️ EMPTY SCHOOL'
    ELSE '🔍 PARTIAL DATA'
  END as school_status
FROM school_data
ORDER BY school_name;

-- =====================================================
-- 9. TEACHER-STUDENT ISOLATION CHECK
-- =====================================================

SELECT 
  '👨‍🏫➡️🎓 TEACHER-STUDENT ISOLATION:' as info;

-- Check if teachers can only see students from their assigned class
SELECT 
  u.full_name as teacher_name,
  tc.class as assigned_class,
  ss.school_name,
  (
    SELECT COUNT(*) 
    FROM public.students s 
    WHERE s.school_id = u.school_id 
      AND s.class = tc.class 
      AND s.status = 'active'
  ) as students_in_assigned_class,
  (
    SELECT COUNT(*) 
    FROM public.students s 
    WHERE s.school_id = u.school_id 
      AND s.status = 'active'
  ) as total_students_in_school
FROM public.users u
JOIN public.teacher_classes tc ON tc.teacher_id = u.id
JOIN public.school_settings ss ON ss.id = u.school_id
WHERE u.role = 'teacher'
ORDER BY ss.school_name, u.full_name;

-- =====================================================
-- 10. MULTI-TENANCY HEALTH SCORE
-- =====================================================

SELECT 
  '📊 MULTI-TENANCY HEALTH SCORE:' as final_assessment;

WITH health_metrics AS (
  SELECT 
    -- Check 1: All users have school_id
    CASE WHEN (SELECT COUNT(*) FROM public.users WHERE school_id IS NULL) = 0 THEN 20 ELSE 0 END as users_score,
    
    -- Check 2: All students have school_id  
    CASE WHEN (SELECT COUNT(*) FROM public.students WHERE school_id IS NULL AND status = 'active') = 0 THEN 20 ELSE 0 END as students_score,
    
    -- Check 3: All staff have school_id
    CASE WHEN (SELECT COUNT(*) FROM public.staff WHERE school_id IS NULL AND status = 'active') = 0 THEN 20 ELSE 0 END as staff_score,
    
    -- Check 4: RLS is enabled on key tables
    CASE WHEN (
      SELECT COUNT(*) 
      FROM pg_class c 
      JOIN pg_namespace n ON n.oid = c.relnamespace 
      WHERE n.nspname = 'public' 
        AND c.relname IN ('students', 'staff', 'users') 
        AND c.rowsecurity = true
    ) = 3 THEN 20 ELSE 0 END as rls_score,
    
    -- Check 5: Multiple schools exist
    CASE WHEN (SELECT COUNT(*) FROM public.school_settings) > 1 THEN 20 ELSE 10 END as schools_score
)
SELECT 
  users_score + students_score + staff_score + rls_score + schools_score as total_score,
  CASE 
    WHEN users_score + students_score + staff_score + rls_score + schools_score >= 90 THEN '🟢 EXCELLENT - Multi-tenancy fully working'
    WHEN users_score + students_score + staff_score + rls_score + schools_score >= 70 THEN '🟡 GOOD - Minor issues to fix'
    WHEN users_score + students_score + staff_score + rls_score + schools_score >= 50 THEN '🟠 FAIR - Some problems exist'
    ELSE '🔴 POOR - Major multi-tenancy issues'
  END as health_status,
  users_score as users_health,
  students_score as students_health,
  staff_score as staff_health,
  rls_score as rls_health,
  schools_score as schools_health
FROM health_metrics;

-- =====================================================
-- 11. RECOMMENDATIONS
-- =====================================================

SELECT 
  '💡 RECOMMENDATIONS:' as recommendations;

-- Check what needs fixing
SELECT 
  CASE 
    WHEN (SELECT COUNT(*) FROM public.users WHERE school_id IS NULL) > 0 
    THEN '1. Fix NULL school_id in users table - run UPDATE users SET school_id = (SELECT id FROM school_settings LIMIT 1) WHERE school_id IS NULL;'
    ELSE '1. ✅ Users table school_id is clean'
  END as user_fix;

SELECT 
  CASE 
    WHEN (SELECT COUNT(*) FROM public.students WHERE school_id IS NULL AND status = 'active') > 0 
    THEN '2. Fix NULL school_id in students table - run UPDATE students SET school_id = (SELECT id FROM school_settings LIMIT 1) WHERE school_id IS NULL;'
    ELSE '2. ✅ Students table school_id is clean'
  END as student_fix;

SELECT 
  CASE 
    WHEN (SELECT COUNT(*) FROM public.staff WHERE school_id IS NULL AND status = 'active') > 0 
    THEN '3. Fix NULL school_id in staff table - run UPDATE staff SET school_id = (SELECT id FROM school_settings LIMIT 1) WHERE school_id IS NULL;'
    ELSE '3. ✅ Staff table school_id is clean'
  END as staff_fix;

SELECT 
  CASE 
    WHEN (
      SELECT COUNT(*) 
      FROM pg_class c 
      JOIN pg_namespace n ON n.oid = c.relnamespace 
      WHERE n.nspname = 'public' 
        AND c.relname IN ('students', 'staff', 'users') 
        AND c.rowsecurity = false
    ) > 0 
    THEN '4. Enable RLS on tables - run ALTER TABLE students ENABLE ROW LEVEL SECURITY; etc.'
    ELSE '4. ✅ RLS is properly enabled'
  END as rls_fix;

-- =====================================================
-- FINAL STATUS
-- =====================================================

SELECT 
  '🎯 MULTI-TENANCY VERIFICATION COMPLETE' as status,
  'Check the health score above for overall status' as next_action,
  'Each school should only see their own data' as expected_behavior;