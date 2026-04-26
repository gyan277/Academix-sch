-- =====================================================
-- TEST FINANCE SYSTEM
-- =====================================================
-- Run this after CLEAN_FINANCE_SETUP.sql to test the system

-- =====================================================
-- TEST 1: Check your students
-- =====================================================

SELECT 
  id,
  full_name,
  student_number,
  class,
  status,
  school_id
FROM public.students
WHERE status = 'active'
ORDER BY class, full_name;

-- Note: Make sure you have at least one active student

-- =====================================================
-- TEST 2: Set a class fee (EXAMPLE - modify as needed)
-- =====================================================

-- Get your school_id first
SELECT 
  id as school_id,
  school_name,
  current_academic_year
FROM public.school_settings
ORDER BY created_at DESC
LIMIT 1;

-- Get your user id
SELECT 
  id as user_id,
  email,
  full_name
FROM public.users
WHERE email = 'admin@moma.com';  -- Change to your email

-- Now set a class fee (UNCOMMENT AND MODIFY THIS):
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
  'YOUR_SCHOOL_ID_HERE',  -- Replace with school_id from above
  'P1',                    -- Replace with your class name
  '2024/2025',            -- Replace with current academic year
  'Term 1',               -- Optional: can be NULL
  500.00,                 -- Fee amount
  'School fees for Term 1',  -- Optional description
  'YOUR_USER_ID_HERE'     -- Replace with your user_id from above
);
*/

-- =====================================================
-- TEST 3: Check if students were auto-billed
-- =====================================================

SELECT 
  s.full_name as student_name,
  s.student_number,
  s.class,
  sf.total_fee_amount as fee,
  sf.total_paid as paid,
  sf.balance,
  sf.payment_status as status,
  sf.created_at as billed_at
FROM public.student_fees sf
JOIN public.students s ON s.id = sf.student_id
ORDER BY s.class, s.full_name;

-- Expected: Should show all students in the class with their fees

-- =====================================================
-- TEST 4: Record a test payment (EXAMPLE)
-- =====================================================

-- Get a student_fee_id to test with
SELECT 
  sf.id as student_fee_id,
  s.full_name,
  s.class,
  sf.balance
FROM public.student_fees sf
JOIN public.students s ON s.id = sf.student_id
LIMIT 1;

-- Record a payment (UNCOMMENT AND MODIFY THIS):
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
  CURRENT_DATE,               -- Today
  'cash',                     -- Payment method
  'REC-001',                  -- Optional receipt number
  'YOUR_USER_ID_HERE'         -- Replace with your user_id
);
*/

-- =====================================================
-- TEST 5: Verify payment updated the balance
-- =====================================================

SELECT 
  s.full_name,
  sf.total_fee_amount as total_fee,
  sf.total_paid as paid,
  sf.balance,
  sf.payment_status as status
FROM public.student_fees sf
JOIN public.students s ON s.id = sf.student_id
ORDER BY s.class, s.full_name;

-- Expected: Should show updated total_paid and balance

-- =====================================================
-- TEST 6: View payment history
-- =====================================================

SELECT 
  s.full_name as student,
  p.payment_date,
  p.amount,
  p.payment_method,
  p.reference_number,
  u.full_name as recorded_by
FROM public.payments p
JOIN public.students s ON s.id = p.student_id
LEFT JOIN public.users u ON u.id = p.recorded_by
ORDER BY p.payment_date DESC;

-- =====================================================
-- SUCCESS INDICATORS
-- =====================================================
-- 
-- ✓ TEST 1: Shows your students
-- ✓ TEST 2: Class fee created
-- ✓ TEST 3: Students automatically billed
-- ✓ TEST 4: Payment recorded
-- ✓ TEST 5: Balance automatically updated
-- ✓ TEST 6: Payment history visible
-- 
-- If all tests pass, the system is working correctly!
-- =====================================================
