-- =====================================================
-- DIAGNOSE FINANCE ISSUE
-- =====================================================
-- This script helps diagnose why students aren't being billed

-- =====================================================
-- 1. CHECK IF FINANCE TABLES EXIST
-- =====================================================

SELECT 
  table_name,
  'EXISTS' as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('class_fees', 'student_fees', 'payments')
ORDER BY table_name;

-- Expected: 3 rows (class_fees, payments, student_fees)

-- =====================================================
-- 2. CHECK YOUR STUDENT
-- =====================================================

SELECT 
  id,
  full_name,
  student_number,
  class,
  status,
  school_id,
  created_at
FROM public.students
WHERE class = 'P1'  -- Change to your class name if different
ORDER BY created_at DESC;

-- Expected: Should show your student in P1
-- IMPORTANT: Note the school_id and class name

-- =====================================================
-- 3. CHECK CLASS FEES
-- =====================================================

SELECT 
  id,
  class,
  academic_year,
  term,
  fee_amount,
  school_id,
  created_at
FROM public.class_fees
ORDER BY created_at DESC;

-- Expected: Should show the class fee you just set
-- Check if class name matches EXACTLY with student's class

-- =====================================================
-- 4. CHECK IF STUDENT WAS AUTO-BILLED
-- =====================================================

SELECT 
  sf.id,
  sf.class,
  sf.total_fee_amount,
  sf.total_paid,
  sf.balance,
  sf.payment_status,
  sf.school_id,
  s.full_name as student_name,
  s.student_number
FROM public.student_fees sf
LEFT JOIN public.students s ON s.id = sf.student_id
WHERE sf.class = 'P1'  -- Change to your class name
ORDER BY sf.created_at DESC;

-- Expected: Should show student_fees record for your student
-- If empty, the auto-billing didn't work

-- =====================================================
-- 5. CHECK TRIGGERS
-- =====================================================

SELECT 
  trigger_name,
  event_object_table,
  action_timing,
  event_manipulation
FROM information_schema.triggers
WHERE event_object_schema = 'public'
  AND trigger_name IN ('trigger_auto_bill_students', 'trigger_auto_bill_new_student')
ORDER BY trigger_name;

-- Expected: Should show 2 triggers
-- If missing, triggers weren't created

-- =====================================================
-- 6. DETAILED DIAGNOSIS
-- =====================================================

-- Check if student and class fee have matching school_id
SELECT 
  'Student' as type,
  s.full_name as name,
  s.class,
  s.school_id,
  s.status
FROM public.students s
WHERE s.class = 'P1'

UNION ALL

SELECT 
  'Class Fee' as type,
  cf.class as name,
  cf.class,
  cf.school_id,
  'active' as status
FROM public.class_fees cf
WHERE cf.class = 'P1';

-- Expected: Both should have the SAME school_id
-- If school_ids don't match, that's the problem!

-- =====================================================
-- 7. CHECK FOR CASE SENSITIVITY ISSUES
-- =====================================================

-- Check exact class names
SELECT DISTINCT 
  class,
  LENGTH(class) as length,
  school_id
FROM public.students
ORDER BY class;

-- Compare with class fees
SELECT DISTINCT 
  class,
  LENGTH(class) as length,
  school_id
FROM public.class_fees
ORDER BY class;

-- Expected: Class names should match EXACTLY (including case and spaces)

-- =====================================================
-- COMMON ISSUES & SOLUTIONS
-- =====================================================

-- ISSUE 1: Class names don't match exactly
-- Student has "P1" but class fee has "p1" or "P 1" (with space)
-- SOLUTION: Update class fee or student to match exactly

-- ISSUE 2: Different school_ids
-- Student has school_id A but class fee has school_id B
-- SOLUTION: Update to use same school_id

-- ISSUE 3: Student status is not 'active'
-- Student status is 'inactive' or something else
-- SOLUTION: Update student status to 'active'

-- ISSUE 4: Triggers not created
-- Auto-billing triggers are missing
-- SOLUTION: Re-run add-finance-system.sql migration

-- =====================================================
-- MANUAL FIX: BILL THE STUDENT MANUALLY
-- =====================================================

-- If auto-billing didn't work, run this to manually bill the student:

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
WHERE s.class = 'P1'  -- Change to your class name
  AND s.status = 'active'
  AND NOT EXISTS (
    SELECT 1 FROM public.student_fees sf 
    WHERE sf.student_id = s.id AND sf.class_fee_id = cf.id
  );
*/

-- After running the INSERT, check again:
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
WHERE sf.class = 'P1';  -- Change to your class name
*/

-- =====================================================
-- REFRESH THE FINANCE PAGE
-- =====================================================
-- After fixing the issue:
-- 1. Go back to the Finance page in your browser
-- 2. Refresh the page (F5 or Ctrl+R)
-- 3. Check the "Student Payments" tab
-- 4. Your student should now appear!
-- =====================================================
