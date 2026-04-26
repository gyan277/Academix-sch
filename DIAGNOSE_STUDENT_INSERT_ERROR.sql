-- =====================================================
-- DIAGNOSE STUDENT INSERT ERROR
-- =====================================================

-- Check the students table structure
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'students'
ORDER BY ordinal_position;

-- Check if student_number column exists and is nullable
SELECT 
  column_name,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'students'
  AND column_name = 'student_number';

-- Check if student_id column exists
SELECT 
  column_name,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'students'
  AND column_name = 'student_id';

-- Check constraints on students table
SELECT
  tc.constraint_name,
  tc.constraint_type,
  kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_schema = 'public'
  AND tc.table_name = 'students'
ORDER BY tc.constraint_type, kcu.column_name;

-- Check if trigger exists
SELECT 
  trigger_name,
  event_manipulation,
  action_statement
FROM information_schema.triggers
WHERE event_object_table = 'students';

-- Try a test insert to see the exact error
-- This will show us what's failing
DO $$
DECLARE
  test_school_id UUID;
BEGIN
  -- Get a school_id
  SELECT id INTO test_school_id FROM public.school_settings LIMIT 1;
  
  -- Try to insert
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
  );
  
  RAISE NOTICE 'Insert successful!';
  
  -- Clean up
  DELETE FROM public.students WHERE full_name = 'Test Student';
  
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Insert failed with error: %', SQLERRM;
END $$;

-- =====================================================
-- POTENTIAL FIX: Make student_number nullable
-- =====================================================

-- If student_number is NOT NULL, make it nullable
ALTER TABLE public.students 
ALTER COLUMN student_number DROP NOT NULL;

-- If student_id is NOT NULL and not needed, make it nullable
ALTER TABLE public.students 
ALTER COLUMN student_id DROP NOT NULL;

-- =====================================================
-- VERIFY THE FIX
-- =====================================================

SELECT 
  column_name,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'students'
  AND column_name IN ('student_number', 'student_id');

-- =====================================================
-- COMPLETE!
-- =====================================================
