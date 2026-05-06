-- =====================================================
-- SIMPLE MULTI-TENANCY VERIFICATION
-- =====================================================
-- This script checks if multi-tenancy is working properly

-- =====================================================
-- 1. SCHOOL DISTRIBUTION CHECK
-- =====================================================

SELECT '🏫 SCHOOLS IN SYSTEM:' as info;

SELECT 
  id as school_id,
  school_name,
  current_academic_year,
  created_at
FROM public.school_settings
ORDER BY school_name;

-- =====================================================
-- 2. USER DISTRIBUTION BY SCHOOL
-- =====================================================

SELECT '👥 USERS BY SCHOOL:' as info;

SELECT 
  ss.school_name,
  u.role,
  COUNT(*) as user_count
FROM public.school_settings ss
LEFT JOIN public.users u ON u.school_id = ss.id
WHERE u.id IS NOT NULL
GROUP BY ss.school_name, u.role
ORDER BY ss.school_name, u.role;

-- =====================================================
-- 3. STUDENT DISTRIBUTION BY SCHOOL
-- =====================================================

SELECT '🎓 STUDENTS BY SCHOOL:' as info;

SELECT 
  ss.school_name,
  COUNT(s.id) as student_count,
  COUNT(DISTINCT s.class) as unique_classes
FROM public.school_settings ss
LEFT JOIN public.students s ON s.school_id = ss.id AND s.status = 'active'
GROUP BY ss.school_name
ORDER BY ss.school_name;

-- =====================================================
-- 4. STAFF DISTRIBUTION BY SCHOOL
-- =====================================================

SELECT '👨‍🏫 STAFF BY SCHOOL:' as info;

SELECT 
  ss.school_name,
  COUNT(st.id) as staff_count,
  COUNT(CASE WHEN st.position ILIKE '%teacher%' THEN 1 END) as teacher_count
FROM public.school_settings ss
LEFT JOIN public.staff st ON st.school_id = ss.id AND st.status = 'active'
GROUP BY ss.school_name
ORDER BY ss.school_name;

-- =====================================================
-- 5. TEACHER CLASS ASSIGNMENTS
-- =====================================================

SELECT '📚 TEACHER CLASS ASSIGNMENTS:' as info;

SELECT 
  ss.school_name,
  u.full_name as teacher_name,
  tc.class as assigned_class,
  tc.academic_year
FROM public.school_settings ss
JOIN public.teacher_classes tc ON tc.school_id = ss.id
JOIN public.users u ON u.id = tc.teacher_id
ORDER BY ss.school_name, tc.class;

-- =====================================================
-- 6. DATA ISOLATION CHECK
-- =====================================================

SELECT '🔍 DATA ISOLATION CHECK:' as info;

-- Check for NULL school_ids (bad for multi-tenancy)
SELECT 
  'Users with NULL school_id' as table_name,
  COUNT(*) as null_count,
  CASE 
    WHEN COUNT(*) = 0 THEN '✅ GOOD'
    ELSE '❌ NEEDS FIX'
  END as status
FROM public.users 
WHERE school_id IS NULL

UNION ALL

SELECT 
  'Students with NULL school_id' as table_name,
  COUNT(*) as null_count,
  CASE 
    WHEN COUNT(*) = 0 THEN '✅ GOOD'
    ELSE '❌ NEEDS FIX'
  END as status
FROM public.students 
WHERE school_id IS NULL AND status = 'active'

UNION ALL

SELECT 
  'Staff with NULL school_id' as table_name,
  COUNT(*) as null_count,
  CASE 
    WHEN COUNT(*) = 0 THEN '✅ GOOD'
    ELSE '❌ NEEDS FIX'
  END as status
FROM public.staff 
WHERE school_id IS NULL AND status = 'active';

-- =====================================================
-- 7. RLS STATUS CHECK
-- =====================================================

SELECT '🔒 ROW LEVEL SECURITY STATUS:' as info;

SELECT 
  c.relname as table_name,
  CASE 
    WHEN c.rowsecurity THEN '✅ ENABLED'
    ELSE '❌ DISABLED'
  END as rls_status
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' 
  AND c.relname IN ('users', 'students', 'staff', 'teacher_classes')
  AND c.relkind = 'r'
ORDER BY c.relname;

-- =====================================================
-- 8. SAMPLE CROSS-SCHOOL TEST
-- =====================================================

SELECT '🧪 CROSS-SCHOOL VISIBILITY TEST:' as info;

-- Show what each school should see (their own data only)
SELECT 
  ss.school_name,
  (SELECT COUNT(*) FROM public.students s WHERE s.school_id = ss.id AND s.status = 'active') as students_visible,
  (SELECT COUNT(*) FROM public.staff st WHERE st.school_id = ss.id AND st.status = 'active') as staff_visible,
  (SELECT COUNT(*) FROM public.users u WHERE u.school_id = ss.id) as users_visible
FROM public.school_settings ss
ORDER BY ss.school_name;

-- =====================================================
-- 9. MULTI-TENANCY HEALTH SUMMARY
-- =====================================================

SELECT '📊 MULTI-TENANCY HEALTH SUMMARY:' as summary;

WITH health_check AS (
  SELECT 
    (SELECT COUNT(*) FROM public.school_settings) as total_schools,
    (SELECT COUNT(*) FROM public.users WHERE school_id IS NULL) as users_without_school,
    (SELECT COUNT(*) FROM public.students WHERE school_id IS NULL AND status = 'active') as students_without_school,
    (SELECT COUNT(*) FROM public.staff WHERE school_id IS NULL AND status = 'active') as staff_without_school,
    (SELECT COUNT(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace 
     WHERE n.nspname = 'public' AND c.relname IN ('students', 'staff', 'users') AND c.rowsecurity = true) as tables_with_rls
)
SELECT 
  total_schools,
  users_without_school,
  students_without_school,
  staff_without_school,
  tables_with_rls,
  CASE 
    WHEN total_schools > 1 
         AND users_without_school = 0 
         AND students_without_school = 0 
         AND staff_without_school = 0 
         AND tables_with_rls >= 3 
    THEN '🟢 EXCELLENT - Multi-tenancy is working properly'
    WHEN users_without_school = 0 
         AND students_without_school = 0 
         AND staff_without_school = 0 
    THEN '🟡 GOOD - Data isolation is working'
    ELSE '🔴 ISSUES - Multi-tenancy needs attention'
  END as overall_status
FROM health_check;

-- =====================================================
-- 10. SPECIFIC ISSUES TO FIX
-- =====================================================

SELECT '🔧 ISSUES TO FIX:' as fixes_needed;

-- Show specific problems if any exist
SELECT 
  'Fix users without school_id' as issue,
  COUNT(*) as affected_records,
  'UPDATE users SET school_id = (SELECT id FROM school_settings LIMIT 1) WHERE school_id IS NULL;' as fix_command
FROM public.users 
WHERE school_id IS NULL
HAVING COUNT(*) > 0

UNION ALL

SELECT 
  'Fix students without school_id' as issue,
  COUNT(*) as affected_records,
  'UPDATE students SET school_id = (SELECT id FROM school_settings LIMIT 1) WHERE school_id IS NULL;' as fix_command
FROM public.students 
WHERE school_id IS NULL AND status = 'active'
HAVING COUNT(*) > 0

UNION ALL

SELECT 
  'Fix staff without school_id' as issue,
  COUNT(*) as affected_records,
  'UPDATE staff SET school_id = (SELECT id FROM school_settings LIMIT 1) WHERE school_id IS NULL;' as fix_command
FROM public.staff 
WHERE school_id IS NULL AND status = 'active'
HAVING COUNT(*) > 0;

-- =====================================================
-- FINAL RESULT
-- =====================================================

SELECT '✅ MULTI-TENANCY VERIFICATION COMPLETE' as result;