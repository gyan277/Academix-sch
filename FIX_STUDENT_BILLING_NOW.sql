-- =====================================================
-- ONE-STEP FIX: Bill All Students for Their Class Fees
-- =====================================================
-- This will automatically bill all students for their class fees

-- =====================================================
-- STEP 1: Check what we have
-- =====================================================

-- Your students:
SELECT 
  id,
  full_name,
  class,
  status,
  school_id
FROM public.students
WHERE status = 'active'
ORDER BY class, full_name;

-- Your class fees:
SELECT 
  id,
  class,
  fee_amount,
  academic_year,
  term,
  school_id
FROM public.class_fees
ORDER BY class;

-- =====================================================
-- STEP 2: Bill all students (RUN THIS!)
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
-- STEP 3: Verify it worked
-- =====================================================

SELECT 
  s.full_name as student_name,
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
-- SUCCESS!
-- =====================================================
-- If you see your students listed above with their fees,
-- go back to the Finance page and refresh (F5 or Ctrl+R)
-- Your students should now appear in the Student Payments tab!
-- =====================================================
