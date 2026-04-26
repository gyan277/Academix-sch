-- =====================================================
-- QUICK FIX: Bill P1 Student
-- =====================================================
-- This script will manually bill your P1 student

-- =====================================================
-- STEP 1: Verify the data
-- =====================================================

-- Check your student
SELECT 
  id as student_id,
  full_name,
  student_number,
  class,
  status,
  school_id
FROM public.students
WHERE class = 'P1';

-- Check your class fee
SELECT 
  id as class_fee_id,
  class,
  fee_amount,
  academic_year,
  term,
  school_id
FROM public.class_fees
WHERE class = 'P1';

-- =====================================================
-- STEP 2: Manual billing (if needed)
-- =====================================================

-- This will create the student_fees record manually
-- Uncomment and run this if the student isn't showing up:

/*
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
CROSS JOIN public.students s
WHERE cf.class = 'P1'
  AND s.class = 'P1'
  AND s.status = 'active'
  AND cf.school_id = s.school_id
  AND NOT EXISTS (
    SELECT 1 FROM public.student_fees sf 
    WHERE sf.student_id = s.id AND sf.class_fee_id = cf.id
  );
*/

-- =====================================================
-- STEP 3: Verify the billing worked
-- =====================================================

SELECT 
  sf.id,
  s.full_name as student_name,
  s.student_number,
  sf.class,
  sf.total_fee_amount,
  sf.total_paid,
  sf.balance,
  sf.payment_status,
  sf.created_at
FROM public.student_fees sf
JOIN public.students s ON s.id = sf.student_id
WHERE sf.class = 'P1'
ORDER BY s.full_name;

-- Expected: Should show your P1 student with:
-- - total_fee_amount = the fee you set
-- - total_paid = 0.00
-- - balance = same as total_fee_amount
-- - payment_status = 'unpaid'

-- =====================================================
-- STEP 4: If still not working, check for issues
-- =====================================================

-- Check if school_ids match
SELECT 
  'Student school_id' as type,
  school_id
FROM public.students
WHERE class = 'P1'
UNION ALL
SELECT 
  'Class fee school_id' as type,
  school_id
FROM public.class_fees
WHERE class = 'P1';

-- Both should be the same!

-- Check if student is active
SELECT 
  full_name,
  status,
  CASE 
    WHEN status = 'active' THEN '✓ Active (Good)'
    ELSE '✗ Not active (Problem!)'
  END as status_check
FROM public.students
WHERE class = 'P1';

-- =====================================================
-- COMMON FIXES
-- =====================================================

-- FIX 1: If student is not active
/*
UPDATE public.students
SET status = 'active'
WHERE class = 'P1';
*/

-- FIX 2: If school_ids don't match, update student
/*
UPDATE public.students
SET school_id = (SELECT school_id FROM public.class_fees WHERE class = 'P1' LIMIT 1)
WHERE class = 'P1';
*/

-- FIX 3: If class names don't match exactly (case sensitive)
-- First check exact names:
SELECT 
  'Student class: "' || class || '"' as info,
  LENGTH(class) as length
FROM public.students
WHERE class ILIKE '%p1%';

SELECT 
  'Class fee: "' || class || '"' as info,
  LENGTH(class) as length
FROM public.class_fees
WHERE class ILIKE '%p1%';

-- If they don't match, update one to match the other:
/*
UPDATE public.students
SET class = 'P1'  -- Use exact name from class_fees
WHERE class ILIKE '%p1%';
*/

-- =====================================================
-- After running fixes, refresh your browser!
-- =====================================================
