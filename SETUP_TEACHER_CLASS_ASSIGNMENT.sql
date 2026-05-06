-- =====================================================
-- TEACHER CLASS ASSIGNMENT SETUP
-- =====================================================
-- This script ensures teacher class assignment works
-- with proper multi-tenancy and data validation

-- =====================================================
-- 1. VERIFY TEACHER_CLASSES TABLE STRUCTURE
-- =====================================================

-- Check if teacher_classes table has all required columns
SELECT 
  '1. Teacher Classes Table Structure' as step,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'teacher_classes'
ORDER BY ordinal_position;

-- =====================================================
-- 2. ENSURE PROPER RLS POLICIES FOR TEACHER_CLASSES
-- =====================================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "teacher_classes_select_own_school" ON public.teacher_classes;
DROP POLICY IF EXISTS "teacher_classes_insert_own_school" ON public.teacher_classes;
DROP POLICY IF EXISTS "teacher_classes_update_own_school" ON public.teacher_classes;
DROP POLICY IF EXISTS "teacher_classes_delete_own_school" ON public.teacher_classes;

-- Create RLS policies for teacher_classes table
CREATE POLICY "teacher_classes_select_own_school"
  ON public.teacher_classes FOR SELECT
  TO authenticated
  USING (school_id = (SELECT school_id FROM public.users WHERE id = auth.uid()));

CREATE POLICY "teacher_classes_insert_own_school"
  ON public.teacher_classes FOR INSERT
  TO authenticated
  WITH CHECK (school_id = (SELECT school_id FROM public.users WHERE id = auth.uid()));

CREATE POLICY "teacher_classes_update_own_school"
  ON public.teacher_classes FOR UPDATE
  TO authenticated
  USING (school_id = (SELECT school_id FROM public.users WHERE id = auth.uid()));

CREATE POLICY "teacher_classes_delete_own_school"
  ON public.teacher_classes FOR DELETE
  TO authenticated
  USING (school_id = (SELECT school_id FROM public.users WHERE id = auth.uid()));

-- Enable RLS on teacher_classes table
ALTER TABLE public.teacher_classes ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 3. CREATE FUNCTION TO GET TEACHER'S ASSIGNED CLASS
-- =====================================================

-- Function to get teacher's assigned class(es)
CREATE OR REPLACE FUNCTION public.get_teacher_assigned_classes(teacher_user_id UUID)
RETURNS TABLE(
  class_name TEXT,
  academic_year TEXT,
  subject_name TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    tc.class,
    tc.academic_year,
    COALESCE(s.name, 'General') as subject_name
  FROM public.teacher_classes tc
  LEFT JOIN public.subjects s ON tc.subject_id = s.id
  WHERE tc.teacher_id = teacher_user_id
    AND tc.academic_year = '2024/2025'
  ORDER BY tc.class;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.get_teacher_assigned_classes TO authenticated;

-- =====================================================
-- 4. CREATE FUNCTION TO GET STUDENTS FOR TEACHER
-- =====================================================

-- Function to get students that a teacher can see (only from assigned classes)
CREATE OR REPLACE FUNCTION public.get_students_for_teacher(teacher_user_id UUID)
RETURNS TABLE(
  student_id UUID,
  student_number TEXT,
  full_name TEXT,
  class TEXT,
  gender TEXT,
  status TEXT
) AS $$
DECLARE
  teacher_school_id UUID;
BEGIN
  -- Get teacher's school_id
  SELECT school_id INTO teacher_school_id
  FROM public.users
  WHERE id = teacher_user_id;
  
  -- If teacher has no school_id, return empty result
  IF teacher_school_id IS NULL THEN
    RETURN;
  END IF;
  
  -- Return students from teacher's assigned classes only
  RETURN QUERY
  SELECT 
    s.id,
    s.student_number,
    s.full_name,
    s.class,
    s.gender,
    s.status
  FROM public.students s
  WHERE s.school_id = teacher_school_id
    AND s.status = 'active'
    AND s.class IN (
      SELECT tc.class 
      FROM public.teacher_classes tc 
      WHERE tc.teacher_id = teacher_user_id 
        AND tc.academic_year = '2024/2025'
    )
  ORDER BY s.class, s.full_name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.get_students_for_teacher TO authenticated;

-- =====================================================
-- 5. UPDATE EXISTING TEACHER CLASS ASSIGNMENTS
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
-- 6. VALIDATION FUNCTIONS
-- =====================================================

-- Function to validate teacher-class assignment before creation
CREATE OR REPLACE FUNCTION public.validate_teacher_class_assignment_safe(
  p_teacher_id UUID,
  p_class TEXT,
  p_school_id UUID
)
RETURNS JSON AS $$
DECLARE
  teacher_school_id UUID;
  student_count INTEGER;
  mismatched_students INTEGER;
  result JSON;
BEGIN
  -- Get teacher's school_id
  SELECT school_id INTO teacher_school_id
  FROM public.users
  WHERE id = p_teacher_id;
  
  -- Validate teacher belongs to the same school
  IF teacher_school_id != p_school_id THEN
    RETURN json_build_object(
      'valid', false,
      'error', 'Teacher does not belong to the specified school'
    );
  END IF;
  
  -- Count students in the class
  SELECT COUNT(*) INTO student_count
  FROM public.students
  WHERE class = p_class AND status = 'active';
  
  -- Count students with mismatched school_id
  SELECT COUNT(*) INTO mismatched_students
  FROM public.students
  WHERE class = p_class 
    AND status = 'active'
    AND (school_id IS NULL OR school_id != p_school_id);
  
  -- Return validation result
  IF mismatched_students > 0 THEN
    RETURN json_build_object(
      'valid', false,
      'error', format('Class %s has %s students from different schools', p_class, mismatched_students),
      'student_count', student_count,
      'mismatched_count', mismatched_students
    );
  ELSE
    RETURN json_build_object(
      'valid', true,
      'message', format('Teacher can be assigned to class %s (%s students)', p_class, student_count),
      'student_count', student_count
    );
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.validate_teacher_class_assignment_safe TO authenticated;

-- =====================================================
-- 7. TEST THE SETUP
-- =====================================================

-- Test function to verify everything is working
CREATE OR REPLACE FUNCTION public.test_teacher_class_system()
RETURNS TABLE(
  test_name TEXT,
  status TEXT,
  details TEXT
) AS $$
BEGIN
  -- Test 1: Check if RLS is enabled
  RETURN QUERY
  SELECT 
    'RLS Enabled on teacher_classes'::TEXT,
    CASE 
      WHEN (SELECT relrowsecurity FROM pg_class WHERE relname = 'teacher_classes') 
      THEN '✅ PASS'::TEXT
      ELSE '❌ FAIL'::TEXT
    END,
    'Row Level Security must be enabled for multi-tenancy'::TEXT;
  
  -- Test 2: Check if policies exist
  RETURN QUERY
  SELECT 
    'Teacher Classes RLS Policies'::TEXT,
    CASE 
      WHEN (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'teacher_classes') >= 4
      THEN '✅ PASS'::TEXT
      ELSE '❌ FAIL'::TEXT
    END,
    format('Found %s policies (need at least 4)', (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'teacher_classes'))::TEXT;
    
  -- Test 3: Check school_id column exists
  RETURN QUERY
  SELECT 
    'School ID Column Exists'::TEXT,
    CASE 
      WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'teacher_classes' AND column_name = 'school_id'
      )
      THEN '✅ PASS'::TEXT
      ELSE '❌ FAIL'::TEXT
    END,
    'teacher_classes table must have school_id column'::TEXT;
    
  -- Test 4: Check functions exist
  RETURN QUERY
  SELECT 
    'Helper Functions Created'::TEXT,
    CASE 
      WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_teacher_assigned_classes')
        AND EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_students_for_teacher')
      THEN '✅ PASS'::TEXT
      ELSE '❌ FAIL'::TEXT
    END,
    'Teacher helper functions must exist'::TEXT;
END;
$$ LANGUAGE plpgsql;

-- Run the test
SELECT * FROM public.test_teacher_class_system();

-- =====================================================
-- 8. SUMMARY
-- =====================================================

SELECT 
  '🎯 TEACHER CLASS ASSIGNMENT SETUP COMPLETE' as summary,
  'Teachers can now be assigned to classes during creation' as details;

SELECT 
  '📋 FEATURES ENABLED' as feature_type,
  'Multi-tenant class assignment with proper validation' as feature_1,
  'Teacher can only see students from assigned classes' as feature_2,
  'Automatic school_id validation and enforcement' as feature_3,
  'Helper functions for frontend integration' as feature_4;