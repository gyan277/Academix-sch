-- =====================================================
-- FINANCE SYSTEM: QUICK START SCRIPT
-- =====================================================
-- Run this after running add-finance-system.sql
-- This script helps you verify everything is set up correctly

-- =====================================================
-- 1. VERIFY TABLES EXIST
-- =====================================================

SELECT 
  table_name,
  CASE 
    WHEN table_name IN ('class_fees', 'student_fees', 'payments') THEN '✓ EXISTS'
    ELSE '✗ MISSING'
  END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('class_fees', 'student_fees', 'payments')
ORDER BY table_name;

-- Expected: 3 rows showing all tables exist

-- =====================================================
-- 2. VERIFY TRIGGERS EXIST
-- =====================================================

SELECT 
  trigger_name,
  event_object_table,
  action_timing,
  event_manipulation
FROM information_schema.triggers
WHERE event_object_schema = 'public'
  AND event_object_table IN ('class_fees', 'student_fees', 'payments')
ORDER BY event_object_table, trigger_name;

-- Expected: Multiple triggers for auto-billing and payment updates

-- =====================================================
-- 3. CHECK CURRENT STUDENTS BY CLASS
-- =====================================================

SELECT 
  class,
  COUNT(*) as student_count,
  school_id
FROM public.students
WHERE status = 'active'
GROUP BY class, school_id
ORDER BY class;

-- This shows how many students are in each class
-- These students will be auto-billed when you set class fees

-- =====================================================
-- 4. GET CURRENT ACADEMIC YEAR
-- =====================================================

SELECT 
  school_name,
  current_academic_year,
  id as school_id
FROM public.school_settings
ORDER BY created_at DESC;

-- Note the current_academic_year - this will be used for fees

-- =====================================================
-- 5. EXAMPLE: SET A CLASS FEE (OPTIONAL - FOR TESTING)
-- =====================================================

-- Uncomment and modify this to test setting a class fee:

/*
INSERT INTO public.class_fees (
  school_id,
  class,
  academic_year,
  term,
  fee_amount,
  description,
  created_by
) VALUES (
  'YOUR_SCHOOL_ID_HERE',  -- Replace with your school_id from step 4
  'Class 1A',              -- Replace with actual class name
  '2024/2025',             -- Replace with current academic year
  'Term 1',                -- Optional: can be NULL for full year
  500.00,                  -- Fee amount
  'School fees for Term 1', -- Optional description
  'YOUR_USER_ID_HERE'      -- Replace with your user id
);
*/

-- After running this, check if students were auto-billed:

/*
SELECT 
  sf.id,
  s.full_name,
  s.student_number,
  sf.class,
  sf.total_fee_amount,
  sf.total_paid,
  sf.balance,
  sf.payment_status
FROM public.student_fees sf
JOIN public.students s ON s.id = sf.student_id
WHERE sf.class = 'Class 1A'  -- Replace with your class
ORDER BY s.full_name;
*/

-- =====================================================
-- 6. EXAMPLE: RECORD A PAYMENT (OPTIONAL - FOR TESTING)
-- =====================================================

-- First, get a student_fee_id from the query above, then:

/*
INSERT INTO public.payments (
  school_id,
  student_fee_id,
  student_id,
  amount,
  payment_date,
  payment_method,
  reference_number,
  recorded_by
) VALUES (
  'YOUR_SCHOOL_ID_HERE',      -- Replace with your school_id
  'STUDENT_FEE_ID_HERE',      -- Replace with student_fee_id from above
  'STUDENT_ID_HERE',          -- Replace with student_id
  200.00,                     -- Payment amount
  CURRENT_DATE,               -- Today's date
  'cash',                     -- Payment method
  'REC-001',                  -- Optional receipt number
  'YOUR_USER_ID_HERE'         -- Replace with your user id
);
*/

-- After recording payment, check if balance was updated:

/*
SELECT 
  s.full_name,
  sf.total_fee_amount,
  sf.total_paid,
  sf.balance,
  sf.payment_status
FROM public.student_fees sf
JOIN public.students s ON s.id = sf.student_id
WHERE sf.id = 'STUDENT_FEE_ID_HERE';  -- Replace with student_fee_id
*/

-- =====================================================
-- 7. VIEW ALL PAYMENTS FOR A STUDENT
-- =====================================================

/*
SELECT 
  p.payment_date,
  p.amount,
  p.payment_method,
  p.reference_number,
  u.full_name as recorded_by
FROM public.payments p
LEFT JOIN public.users u ON u.id = p.recorded_by
WHERE p.student_id = 'STUDENT_ID_HERE'  -- Replace with student_id
ORDER BY p.payment_date DESC;
*/

-- =====================================================
-- 8. FINANCIAL SUMMARY
-- =====================================================

-- Total revenue by class
SELECT 
  sf.class,
  COUNT(DISTINCT sf.student_id) as total_students,
  SUM(sf.total_fee_amount) as total_expected,
  SUM(sf.total_paid) as total_collected,
  SUM(sf.balance) as total_outstanding,
  ROUND((SUM(sf.total_paid) / NULLIF(SUM(sf.total_fee_amount), 0) * 100), 2) as collection_rate_percent
FROM public.student_fees sf
WHERE sf.school_id = 'YOUR_SCHOOL_ID_HERE'  -- Replace with your school_id
GROUP BY sf.class
ORDER BY sf.class;

-- Overall financial summary
SELECT 
  COUNT(DISTINCT student_id) as total_students_billed,
  SUM(total_fee_amount) as total_expected,
  SUM(total_paid) as total_collected,
  SUM(balance) as total_outstanding,
  ROUND((SUM(total_paid) / NULLIF(SUM(total_fee_amount), 0) * 100), 2) as collection_rate_percent,
  COUNT(CASE WHEN payment_status = 'paid' THEN 1 END) as students_fully_paid,
  COUNT(CASE WHEN payment_status = 'partial' THEN 1 END) as students_partial_paid,
  COUNT(CASE WHEN payment_status = 'unpaid' THEN 1 END) as students_unpaid
FROM public.student_fees
WHERE school_id = 'YOUR_SCHOOL_ID_HERE';  -- Replace with your school_id

-- =====================================================
-- 9. TROUBLESHOOTING: MANUALLY BILL STUDENTS
-- =====================================================

-- If students weren't auto-billed, run this to manually bill them:

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
JOIN public.students s ON s.class = cf.class AND s.school_id = cf.school_id
WHERE s.status = 'active'
  AND cf.school_id = 'YOUR_SCHOOL_ID_HERE'  -- Replace with your school_id
  AND NOT EXISTS (
    SELECT 1 FROM public.student_fees sf 
    WHERE sf.student_id = s.id AND sf.class_fee_id = cf.id
  );
*/

-- =====================================================
-- 10. TROUBLESHOOTING: RECALCULATE TOTALS
-- =====================================================

-- If payment totals are incorrect, recalculate them:

/*
UPDATE public.student_fees sf
SET total_paid = (
  SELECT COALESCE(SUM(amount), 0)
  FROM public.payments p
  WHERE p.student_fee_id = sf.id
),
updated_at = NOW()
WHERE sf.school_id = 'YOUR_SCHOOL_ID_HERE';  -- Replace with your school_id
*/

-- =====================================================
-- SETUP COMPLETE!
-- =====================================================
-- 
-- Next steps:
-- 1. Login to the application as admin
-- 2. Go to Finance page
-- 3. Click "Set Class Fee" to set fees for your classes
-- 4. Students will be automatically billed
-- 5. Record payments as they come in
-- 
-- The system will automatically:
-- - Calculate balances
-- - Update payment status
-- - Track all transactions
-- 
-- =====================================================
