-- =====================================================
-- FIX STUDENT INSERT ERROR
-- =====================================================
-- This makes student_number and student_id nullable
-- so the trigger can generate them automatically
-- =====================================================

-- Make student_number nullable (so trigger can set it)
ALTER TABLE public.students 
ALTER COLUMN student_number DROP NOT NULL;

-- Make student_id nullable (so trigger can set it)
ALTER TABLE public.students 
ALTER COLUMN student_id DROP NOT NULL;

-- Verify the changes
SELECT 
  column_name,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'students'
  AND column_name IN ('student_number', 'student_id', 'full_name', 'school_id');

-- Test insert
DO $$
DECLARE
  test_school_id UUID;
  new_student_id UUID;
BEGIN
  -- Get school_id
  SELECT id INTO test_school_id FROM public.school_settings LIMIT 1;
  
  -- Try insert
  INSERT INTO public.students (
    school_id,
    full_name,
    date_of_birth,
    gender,
    class,
    parent_name,
    parent_phone,
    admission_date,
    status
  ) VALUES (
    test_school_id,
    'Test Student',
    '2010-01-01',
    'Female',
    'P2',
    'Test Parent',
    '0599999386',
    CURRENT_DATE,
    'active'
  )
  RETURNING id INTO new_student_id;
  
  RAISE NOTICE 'Insert successful! Student ID: %', new_student_id;
  
  -- Show the generated student_number
  RAISE NOTICE 'Generated student_number: %', (
    SELECT student_number FROM public.students WHERE id = new_student_id
  );
  
  -- Clean up
  DELETE FROM public.students WHERE id = new_student_id;
  RAISE NOTICE 'Test student deleted';
  
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Error: %', SQLERRM;
END $$;

-- =====================================================
-- COMPLETE!
-- =====================================================
-- 
-- Now try adding a student again from the UI.
-- The student_number should be generated automatically!
-- 
-- =====================================================
