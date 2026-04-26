-- =====================================================
-- FIX: Student Number Column Issue
-- =====================================================

-- =====================================================
-- STEP 1: Check what columns students table has
-- =====================================================

SELECT 
  column_name,
  data_type
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'students'
ORDER BY ordinal_position;

-- =====================================================
-- STEP 2: Check if student_number exists
-- =====================================================

SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'students' 
      AND column_name = 'student_number'
    ) THEN '✅ student_number column exists'
    ELSE '❌ student_number column DOES NOT exist - need to add it'
  END as status;

-- =====================================================
-- STEP 3: Add student_number column if missing
-- =====================================================

ALTER TABLE public.students 
ADD COLUMN IF NOT EXISTS student_number TEXT;

-- =====================================================
-- STEP 4: Generate student numbers for existing students
-- =====================================================

-- Generate student numbers like: STU-001, STU-002, etc.
UPDATE public.students
SET student_number = 'STU-' || LPAD(ROW_NUMBER() OVER (ORDER BY created_at)::TEXT, 4, '0')
WHERE student_number IS NULL;

-- =====================================================
-- STEP 5: Verify it worked
-- =====================================================

SELECT 
  id,
  full_name,
  student_number,
  class,
  status
FROM public.students
ORDER BY created_at;

-- =====================================================
-- STEP 6: Now bill the students
-- =====================================================

INSERT INTO public.student_fees (
  school_id,
  student_id,
  class_fee_id,
  class,
  academic_year,
  term,
  total_fee_amount
)
SELECT 
  cf.school_id,
  s.id,
  cf.id,
  cf.class,
  cf.academic_year,
  cf.term,
  cf.fee_amount
FROM public.class_fees cf
JOIN public.students s ON s.class = cf.class AND s.school_id = cf.school_id
WHERE s.status = 'active'
  AND NOT EXISTS (
    SELECT 1 FROM public.student_fees sf 
    WHERE sf.student_id = s.id AND sf.class_fee_id = cf.id
  );

-- =====================================================
-- STEP 7: Verify student_fees with student details
-- =====================================================

SELECT 
  s.full_name as student,
  s.student_number,
  s.class,
  sf.total_fee_amount as fee,
  sf.total_paid as paid,
  sf.balance,
  sf.payment_status as status
FROM public.student_fees sf
JOIN public.students s ON s.id = sf.student_id
ORDER BY s.class, s.full_name;

-- =====================================================
-- STEP 8: Check user school_id
-- =====================================================

SELECT 
  email,
  school_id,
  CASE 
    WHEN school_id IS NULL THEN '❌ NO SCHOOL_ID - Run fix below'
    ELSE '✅ Has school_id'
  END as status
FROM public.users
WHERE role = 'admin';

-- =====================================================
-- STEP 9: Fix user school_id if needed
-- =====================================================

-- If Step 8 shows NO SCHOOL_ID, uncomment and run this:
/*
UPDATE public.users
SET school_id = (SELECT id FROM public.school_settings LIMIT 1)
WHERE role = 'admin' AND school_id IS NULL;
*/

-- =====================================================
-- STEP 10: Final test - This is what frontend queries
-- =====================================================

SELECT 
  sf.id,
  sf.class,
  sf.total_fee_amount,
  sf.total_paid,
  sf.balance,
  sf.payment_status,
  s.full_name,
  s.student_number
FROM public.student_fees sf
LEFT JOIN public.students s ON s.id = sf.student_id
WHERE sf.school_id = (SELECT school_id FROM public.users WHERE role = 'admin' LIMIT 1)
ORDER BY sf.class ASC;

-- If this returns rows, refresh your browser and it should work!

-- =====================================================
-- SUCCESS!
-- =====================================================
-- After running this:
-- 1. Refresh browser (F5)
-- 2. Go to Finance page
-- 3. Check Student Payments tab
-- 4. Your students should appear!
-- =====================================================
