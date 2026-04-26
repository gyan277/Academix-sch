-- =====================================================
-- FINAL FIX: Make Student Fees Appear
-- =====================================================

-- =====================================================
-- STEP 1: Check if data exists
-- =====================================================

SELECT COUNT(*) as student_fees_count FROM public.student_fees;
SELECT COUNT(*) as class_fees_count FROM public.class_fees;
SELECT COUNT(*) as students_count FROM public.students WHERE status = 'active';

-- =====================================================
-- STEP 2: Check your user's school_id
-- =====================================================

SELECT 
  id as user_id,
  email,
  school_id,
  CASE 
    WHEN school_id IS NULL THEN '❌ NO SCHOOL_ID - THIS IS THE PROBLEM!'
    ELSE '✅ Has school_id: ' || school_id::text
  END as diagnosis
FROM public.users
WHERE role = 'admin'
ORDER BY created_at DESC
LIMIT 1;

-- =====================================================
-- STEP 3: If student_fees is empty, bill students now
-- =====================================================

-- This will bill ALL active students for their class fees
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
-- STEP 4: Verify student_fees were created
-- =====================================================

SELECT 
  s.full_name as student,
  s.student_number,
  s.class,
  sf.total_fee_amount as fee,
  sf.total_paid as paid,
  sf.balance,
  sf.payment_status as status,
  sf.school_id,
  s.school_id as student_school_id,
  CASE 
    WHEN sf.school_id = s.school_id THEN '✅ School IDs match'
    ELSE '❌ School IDs DO NOT match'
  END as school_id_check
FROM public.student_fees sf
JOIN public.students s ON s.id = sf.student_id
ORDER BY s.class, s.full_name;

-- =====================================================
-- STEP 5: Check if user school_id matches data
-- =====================================================

WITH user_school AS (
  SELECT school_id FROM public.users WHERE role = 'admin' LIMIT 1
),
data_school AS (
  SELECT DISTINCT school_id FROM public.student_fees LIMIT 1
)
SELECT 
  u.school_id as user_school_id,
  d.school_id as data_school_id,
  CASE 
    WHEN u.school_id = d.school_id THEN '✅ MATCH - Frontend should work!'
    WHEN u.school_id IS NULL THEN '❌ User has no school_id - UPDATE NEEDED'
    WHEN d.school_id IS NULL THEN '❌ No data exists'
    ELSE '❌ MISMATCH - User and data have different school_ids'
  END as diagnosis
FROM user_school u, data_school d;

-- =====================================================
-- STEP 6: FIX - If school_ids don't match
-- =====================================================

-- Option A: Update user's school_id to match the data
/*
UPDATE public.users
SET school_id = (SELECT school_id FROM public.student_fees LIMIT 1)
WHERE role = 'admin' AND email = 'admin@moma.com';
*/

-- Option B: Update all student_fees to match user's school_id
/*
UPDATE public.student_fees
SET school_id = (SELECT school_id FROM public.users WHERE role = 'admin' LIMIT 1);

UPDATE public.class_fees
SET school_id = (SELECT school_id FROM public.users WHERE role = 'admin' LIMIT 1);

UPDATE public.students
SET school_id = (SELECT school_id FROM public.users WHERE role = 'admin' LIMIT 1);
*/

-- =====================================================
-- STEP 7: Final verification
-- =====================================================

-- This is the EXACT query the frontend uses
SELECT 
  sf.*,
  s.full_name,
  s.student_number
FROM public.student_fees sf
LEFT JOIN public.students s ON s.id = sf.student_id
WHERE sf.school_id = (SELECT school_id FROM public.users WHERE role = 'admin' LIMIT 1)
ORDER BY sf.class ASC;

-- If this returns rows, the frontend SHOULD work after refresh!

-- =====================================================
-- INSTRUCTIONS
-- =====================================================
-- 
-- 1. Run this entire script
-- 2. Look at the results of each step
-- 3. If Step 5 shows "MISMATCH", uncomment and run Option A or B in Step 6
-- 4. Run Step 7 to verify
-- 5. Refresh your browser (F5)
-- 6. Check Finance page
-- 
-- =====================================================
