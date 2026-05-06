-- =====================================================
-- SIMPLE TEACHER CLASS ASSIGNMENT SETUP
-- =====================================================
-- This script sets up teacher class assignment with
-- minimal complexity to avoid SQL errors

-- =====================================================
-- 1. CHECK CURRENT TABLE STRUCTURE
-- =====================================================

-- Check if teacher_classes table exists and has school_id
SELECT 
  'teacher_classes table structure:' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'teacher_classes'
ORDER BY ordinal_position;

-- =====================================================
-- 2. ENSURE SCHOOL_ID COLUMN EXISTS
-- =====================================================

-- Add school_id column if it doesn't exist (safe operation)
ALTER TABLE public.teacher_classes 
ADD COLUMN IF NOT EXISTS school_id UUID REFERENCES public.school_settings(id) ON DELETE CASCADE;

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_teacher_classes_school_id ON public.teacher_classes(school_id);

-- =====================================================
-- 3. ENABLE RLS ON TEACHER_CLASSES
-- =====================================================

-- Enable Row Level Security
ALTER TABLE public.teacher_classes ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 4. CREATE BASIC RLS POLICIES
-- =====================================================

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "teacher_classes_policy" ON public.teacher_classes;

-- Create a single comprehensive policy for teacher_classes
CREATE POLICY "teacher_classes_policy"
  ON public.teacher_classes
  FOR ALL
  TO authenticated
  USING (
    school_id = (SELECT school_id FROM public.users WHERE id = auth.uid())
  )
  WITH CHECK (
    school_id = (SELECT school_id FROM public.users WHERE id = auth.uid())
  );

-- =====================================================
-- 5. UPDATE EXISTING RECORDS
-- =====================================================

-- Add school_id to existing teacher_classes records that don't have it
UPDATE public.teacher_classes 
SET school_id = (
  SELECT u.school_id 
  FROM public.users u 
  WHERE u.id = teacher_classes.teacher_id
)
WHERE school_id IS NULL;

-- =====================================================
-- 6. VERIFY SETUP
-- =====================================================

-- Check RLS is enabled
SELECT 
  'RLS Status:' as check_type,
  CASE 
    WHEN relrowsecurity THEN 'ENABLED ✅'
    ELSE 'DISABLED ❌'
  END as status
FROM pg_class 
WHERE relname = 'teacher_classes';

-- Check policies exist
SELECT 
  'RLS Policies:' as check_type,
  COUNT(*) || ' policies found' as status
FROM pg_policies 
WHERE tablename = 'teacher_classes';

-- Check school_id column
SELECT 
  'School ID Column:' as check_type,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'teacher_classes' AND column_name = 'school_id'
    ) THEN 'EXISTS ✅'
    ELSE 'MISSING ❌'
  END as status;

-- =====================================================
-- 7. TEST DATA INTEGRITY
-- =====================================================

-- Check for teacher_classes records without school_id
SELECT 
  'Records without school_id:' as check_type,
  COUNT(*) || ' records' as status
FROM public.teacher_classes 
WHERE school_id IS NULL;

-- Check for mismatched school_ids between teacher and class assignment
SELECT 
  'School ID mismatches:' as check_type,
  COUNT(*) || ' mismatches' as status
FROM public.teacher_classes tc
JOIN public.users u ON tc.teacher_id = u.id
WHERE tc.school_id != u.school_id;

-- =====================================================
-- 8. SUMMARY
-- =====================================================

SELECT '✅ SETUP COMPLETE' as result, 'Teacher class assignment is ready' as message;