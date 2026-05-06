-- =====================================================
-- TEST TEACHER CREATION WITH CLASS ASSIGNMENT
-- =====================================================
-- Simple test to verify the system works

-- =====================================================
-- 1. CHECK CURRENT SETUP
-- =====================================================

-- Check if we have the required tables
SELECT 
  'Required Tables Check:' as test,
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'teacher_classes')
    THEN 'teacher_classes EXISTS ✅'
    ELSE 'teacher_classes MISSING ❌'
  END as teacher_classes_status,
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users')
    THEN 'users EXISTS ✅'
    ELSE 'users MISSING ❌'
  END as users_status,
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'staff')
    THEN 'staff EXISTS ✅'
    ELSE 'staff MISSING ❌'
  END as staff_status;

-- =====================================================
-- 2. CHECK SCHOOL_ID SETUP
-- =====================================================

-- Check if school_id columns exist where needed
SELECT 
  'School ID Columns:' as test,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'teacher_classes' AND column_name = 'school_id'
    ) THEN 'teacher_classes.school_id EXISTS ✅'
    ELSE 'teacher_classes.school_id MISSING ❌'
  END as teacher_classes_school_id,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'users' AND column_name = 'school_id'
    ) THEN 'users.school_id EXISTS ✅'
    ELSE 'users.school_id MISSING ❌'
  END as users_school_id;

-- =====================================================
-- 3. CHECK CURRENT DATA
-- =====================================================

-- Count existing records
SELECT 
  'Current Data:' as info,
  (SELECT COUNT(*) FROM public.users WHERE role = 'teacher') as teacher_count,
  (SELECT COUNT(*) FROM public.teacher_classes) as class_assignments,
  (SELECT COUNT(*) FROM public.school_settings) as schools;

-- =====================================================
-- 4. CHECK RLS POLICIES
-- =====================================================

-- List RLS policies for teacher_classes
SELECT 
  'RLS Policies for teacher_classes:' as info,
  policyname,
  cmd,
  permissive
FROM pg_policies 
WHERE tablename = 'teacher_classes';

-- =====================================================
-- 5. SIMULATE CLASS ASSIGNMENT
-- =====================================================

-- Show what a teacher class assignment would look like
-- (This is just a SELECT, not an INSERT)
SELECT 
  'Sample Teacher Class Assignment:' as info,
  'teacher-uuid-here' as teacher_id,
  'Primary 3' as class,
  '2024/2025' as academic_year,
  'school-uuid-here' as school_id,
  NOW() as created_at;

-- =====================================================
-- 6. VALIDATION CHECKS
-- =====================================================

-- Check if we can identify potential issues
SELECT 
  'Validation Results:' as test_type,
  CASE 
    WHEN (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'teacher_classes' AND column_name = 'school_id') > 0
    AND (SELECT relrowsecurity FROM pg_class WHERE relname = 'teacher_classes')
    AND (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'teacher_classes') > 0
    THEN 'ALL CHECKS PASS ✅'
    ELSE 'SOME CHECKS FAILED ❌'
  END as overall_status;

-- =====================================================
-- 7. NEXT STEPS
-- =====================================================

SELECT 
  'Next Steps:' as action,
  '1. Test teacher creation in frontend' as step_1,
  '2. Verify class assignment works' as step_2,
  '3. Check teacher can only see assigned class students' as step_3;