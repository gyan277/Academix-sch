-- =====================================================
-- QUICK FIX: Replace STU with School Prefix
-- =====================================================
-- This simply replaces "STU" with your school prefix
-- STU0001 -> MOU0001
-- STU0002 -> MOU0002
-- =====================================================

-- First, check what will be changed
SELECT 
  student_number as old_number,
  REPLACE(student_number, 'STU', 
    COALESCE(
      (SELECT UPPER(SUBSTRING(name FROM 1 FOR 3)) 
       FROM public.school_settings 
       WHERE id = students.school_id),
      'STU'
    )
  ) as new_number,
  full_name,
  class
FROM public.students
WHERE student_number LIKE 'STU%';

-- =====================================================
-- APPLY THE FIX
-- =====================================================

UPDATE public.students
SET student_number = REPLACE(
  student_number, 
  'STU', 
  COALESCE(
    (SELECT UPPER(SUBSTRING(name FROM 1 FOR 3)) 
     FROM public.school_settings 
     WHERE id = students.school_id),
    'STU'
  )
)
WHERE student_number LIKE 'STU%';

-- =====================================================
-- VERIFY
-- =====================================================

-- Check if any STU numbers remain
SELECT COUNT(*) as remaining_stu_numbers
FROM public.students
WHERE student_number LIKE 'STU%';

-- Show all student numbers
SELECT 
  student_number,
  full_name,
  class
FROM public.students
ORDER BY student_number;

-- =====================================================
-- COMPLETE!
-- =====================================================
-- 
-- Result:
-- STU0001 -> MOU0001
-- STU0002 -> MOU0002
-- 
-- All done! Refresh your browser to see the changes.
-- 
-- =====================================================
