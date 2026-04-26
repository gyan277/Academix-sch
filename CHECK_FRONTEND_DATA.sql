-- =====================================================
-- CHECK FRONTEND DATA
-- =====================================================
-- This checks if data exists and why frontend might not see it

-- =====================================================
-- 1. Check if student_fees exist in database
-- =====================================================

SELECT 
  COUNT(*) as total_student_fees,
  'Records exist in database' as status
FROM public.student_fees;

-- If this shows 0, the data isn't in the database
-- If this shows > 0, the data exists but frontend can't see it

-- =====================================================
-- 2. Check detailed student_fees data
-- =====================================================

SELECT 
  sf.id,
  sf.school_id,
  sf.student_id,
  sf.class,
  sf.total_fee_amount,
  sf.total_paid,
  sf.balance,
  sf.payment_status,
  s.full_name as student_name,
  s.student_number
FROM public.student_fees sf
LEFT JOIN public.students s ON s.id = sf.student_id
ORDER BY sf.created_at DESC;

-- This shows ALL student_fees records with student details

-- =====================================================
-- 3. Check what school_id the frontend is using
-- =====================================================

-- Check your logged-in user's school_id
SELECT 
  id as user_id,
  email,
  full_name,
  role,
  school_id,
  CASE 
    WHEN school_id IS NULL THEN '⚠️ NO SCHOOL_ID (Problem!)'
    ELSE '✓ Has school_id'
  END as school_id_status
FROM public.users
WHERE email = 'admin@moma.com';  -- Change to your email

-- =====================================================
-- 4. Compare school_ids
-- =====================================================

-- Student fees school_ids
SELECT DISTINCT 
  'student_fees' as table_name,
  school_id
FROM public.student_fees

UNION ALL

-- User school_id
SELECT 
  'logged_in_user' as table_name,
  school_id
FROM public.users
WHERE email = 'admin@moma.com';  -- Change to your email

-- These should MATCH!

-- =====================================================
-- 5. Check if RLS is blocking the query
-- =====================================================

-- Check RLS policies on student_fees
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  cmd
FROM pg_policies 
WHERE tablename = 'student_fees';

-- =====================================================
-- 6. Test the exact query the frontend uses
-- =====================================================

-- This is what the Finance page queries
-- Replace YOUR_SCHOOL_ID with your actual school_id from step 3

/*
SELECT 
  sf.*,
  s.full_name,
  s.student_number
FROM public.student_fees sf
LEFT JOIN public.students s ON s.id = sf.student_id
WHERE sf.school_id = 'YOUR_SCHOOL_ID'
ORDER BY sf.class ASC;
*/

-- =====================================================
-- DIAGNOSIS
-- =====================================================

-- SCENARIO A: Step 1 shows 0 records
-- → Data not in database, auto-billing didn't work
-- → Solution: Run manual billing script

-- SCENARIO B: Step 1 shows records, but Step 4 shows different school_ids
-- → User and student_fees have different school_ids
-- → Solution: Update user's school_id or student_fees school_id

-- SCENARIO C: Step 1 shows records, Step 4 matches, but frontend shows nothing
-- → RLS policy or frontend query issue
-- → Solution: Check browser console for errors

-- =====================================================
