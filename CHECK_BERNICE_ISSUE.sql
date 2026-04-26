-- =====================================================
-- CHECK WHY BERNICE IS NOT DISPLAYING
-- =====================================================

-- Check if Bernice exists in database
SELECT 
  id,
  student_number,
  full_name,
  class,
  status,
  school_id,
  created_at
FROM public.students
WHERE full_name LIKE '%Bernice%'
ORDER BY created_at DESC;

-- Check all students with their status
SELECT 
  student_number,
  full_name,
  class,
  status,
  school_id
FROM public.students
ORDER BY created_at DESC;

-- Check if status is 'active'
SELECT 
  COUNT(*) as total_students,
  COUNT(CASE WHEN status = 'active' THEN 1 END) as active_students,
  COUNT(CASE WHEN status IS NULL THEN 1 END) as null_status,
  COUNT(CASE WHEN status != 'active' THEN 1 END) as inactive_students
FROM public.students;

-- Check school_id matches
SELECT 
  s.full_name,
  s.school_id as student_school_id,
  ss.name as school_name,
  ss.id as school_settings_id
FROM public.students s
LEFT JOIN public.school_settings ss ON s.school_id = ss.id
WHERE s.full_name LIKE '%Bernice%';

-- =====================================================
-- FIX: Ensure Bernice has status = 'active'
-- =====================================================

UPDATE public.students
SET status = 'active'
WHERE full_name LIKE '%Bernice%'
  AND (status IS NULL OR status != 'active');

-- =====================================================
-- FIX: Ensure Bernice has correct school_id
-- =====================================================

-- Get the school_id from other students
DO $$
DECLARE
  correct_school_id UUID;
BEGIN
  -- Get school_id from an existing student
  SELECT school_id INTO correct_school_id
  FROM public.students
  WHERE status = 'active'
    AND school_id IS NOT NULL
  LIMIT 1;
  
  -- Update Bernice if school_id is wrong or NULL
  UPDATE public.students
  SET school_id = correct_school_id
  WHERE full_name LIKE '%Bernice%'
    AND (school_id IS NULL OR school_id != correct_school_id);
    
  RAISE NOTICE 'Updated Bernice with school_id: %', correct_school_id;
END $$;

-- =====================================================
-- VERIFY THE FIX
-- =====================================================

SELECT 
  student_number,
  full_name,
  class,
  status,
  school_id,
  CASE 
    WHEN status = 'active' THEN '✓ Active'
    WHEN status IS NULL THEN '✗ NULL status'
    ELSE '✗ ' || status
  END as status_check,
  CASE 
    WHEN school_id IS NOT NULL THEN '✓ Has school_id'
    ELSE '✗ NULL school_id'
  END as school_check
FROM public.students
WHERE full_name LIKE '%Bernice%';

-- =====================================================
-- CHECK RLS POLICIES
-- =====================================================

-- Check if RLS is enabled
SELECT 
  tablename,
  rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename = 'students';

-- Check RLS policies on students table
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'students';

-- =====================================================
-- COMPLETE!
-- =====================================================
-- 
-- After running this:
-- 1. Bernice should have status = 'active'
-- 2. Bernice should have correct school_id
-- 3. Refresh your browser (F5)
-- 4. Bernice should now appear in the list
-- 
-- =====================================================
