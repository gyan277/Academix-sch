-- EMERGENCY: Check if teacher collections exist and why admin can't see them
-- Run this NOW in Supabase SQL Editor

-- ============================================
-- 1. Do collections exist at all?
-- ============================================
SELECT 
  '🔍 STEP 1: Collections in Database' as check_step,
  COUNT(*) as total_collections,
  COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_count,
  COUNT(CASE WHEN status = 'confirmed' THEN 1 END) as confirmed_count,
  CASE 
    WHEN COUNT(*) = 0 THEN '❌ NO COLLECTIONS - Teacher submission failed'
    ELSE '✅ Collections exist in database'
  END as status
FROM teacher_fee_collections;

-- ============================================
-- 2. Show ALL collections with full details
-- ============================================
SELECT 
  '📋 STEP 2: All Collections Details' as check_step,
  tfc.id,
  tfc.created_at,
  tfc.collection_date,
  tfc.collection_type,
  tfc.amount,
  tfc.status,
  tfc.academic_year,
  tfc.term,
  tfc.school_id,
  t.full_name as teacher_name,
  t.id as teacher_id,
  s.full_name as student_name,
  s.id as student_id
FROM teacher_fee_collections tfc
LEFT JOIN teachers t ON t.id = tfc.teacher_id
LEFT JOIN students s ON s.id = tfc.student_id
ORDER BY tfc.created_at DESC;

-- ============================================
-- 3. What are the current academic settings?
-- ============================================
SELECT 
  '⚙️ STEP 3: Current Academic Settings' as check_step,
  ss.id as school_id,
  ss.current_academic_year,
  ss.current_term,
  ss.enable_teacher_fee_collection,
  sc.name as school_name
FROM school_settings ss
JOIN schools sc ON sc.id = ss.id;

-- ============================================
-- 4. Check for MISMATCH between collections and current settings
-- ============================================
SELECT 
  '⚠️ STEP 4: Academic Year/Term Mismatch Check' as check_step,
  tfc.academic_year as collection_year,
  tfc.term as collection_term,
  ss.current_academic_year as system_current_year,
  ss.current_term as system_current_term,
  CASE 
    WHEN tfc.academic_year = ss.current_academic_year AND tfc.term = ss.current_term 
    THEN '✅ MATCH - Admin should see this'
    ELSE '❌ MISMATCH - Admin filtering by different year/term!'
  END as match_status,
  COUNT(*) as collection_count
FROM teacher_fee_collections tfc
CROSS JOIN school_settings ss
GROUP BY tfc.academic_year, tfc.term, ss.current_academic_year, ss.current_term;

-- ============================================
-- 5. Does the RPC function exist?
-- ============================================
SELECT 
  '🔧 STEP 5: RPC Function Check' as check_step,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.routines 
      WHERE routine_schema = 'public' 
      AND routine_name = 'get_all_teacher_collections'
    ) THEN '✅ Function exists'
    ELSE '❌ FUNCTION MISSING - Run CREATE_RPC_FOR_ADMIN_COLLECTIONS.sql NOW!'
  END as function_status;

-- ============================================
-- 6. Test the RPC function (if it exists)
-- ============================================
DO $$
DECLARE
  v_school_id UUID;
  v_academic_year TEXT;
  v_term TEXT;
  v_count INTEGER;
  v_function_exists BOOLEAN;
BEGIN
  -- Check if function exists
  SELECT EXISTS (
    SELECT 1 FROM information_schema.routines 
    WHERE routine_schema = 'public' 
    AND routine_name = 'get_all_teacher_collections'
  ) INTO v_function_exists;

  IF NOT v_function_exists THEN
    RAISE NOTICE '❌ STEP 6: RPC function does not exist - Cannot test';
    RETURN;
  END IF;

  -- Get current settings
  SELECT id, current_academic_year, current_term
  INTO v_school_id, v_academic_year, v_term
  FROM school_settings
  LIMIT 1;
  
  -- Test the RPC function
  EXECUTE format('SELECT COUNT(*) FROM get_all_teacher_collections($1, $2, $3)')
  INTO v_count
  USING v_school_id, v_academic_year, v_term;
  
  RAISE NOTICE '✅ STEP 6: RPC function returned % collections for school_id=%, year=%, term=%', 
    v_count, v_school_id, v_academic_year, v_term;
    
  IF v_count = 0 THEN
    RAISE NOTICE '⚠️ RPC returned 0 collections - Check for year/term mismatch above';
  END IF;
END $$;

-- ============================================
-- 7. Check browser console error
-- ============================================
SELECT 
  '🌐 STEP 7: Frontend Debugging' as check_step,
  'Open browser DevTools (F12) → Console tab' as instruction,
  'Look for red error messages when loading Teacher Collections tab' as what_to_check,
  'Share the exact error message if you see one' as next_action;

-- ============================================
-- 📊 FINAL DIAGNOSIS
-- ============================================
SELECT 
  '📊 DIAGNOSIS SUMMARY' as summary,
  (SELECT COUNT(*) FROM teacher_fee_collections) as total_collections_in_db,
  (SELECT COUNT(*) FROM teacher_fee_collections WHERE status = 'pending') as pending_collections,
  (SELECT current_academic_year FROM school_settings LIMIT 1) as system_year,
  (SELECT current_term FROM school_settings LIMIT 1) as system_term,
  (SELECT enable_teacher_fee_collection FROM school_settings LIMIT 1) as feature_enabled,
  CASE 
    WHEN (SELECT COUNT(*) FROM teacher_fee_collections) = 0 
    THEN '❌ NO COLLECTIONS - Teacher needs to collect fees'
    WHEN NOT EXISTS (
      SELECT 1 FROM information_schema.routines 
      WHERE routine_name = 'get_all_teacher_collections'
    )
    THEN '❌ RPC FUNCTION MISSING - Run CREATE_RPC_FOR_ADMIN_COLLECTIONS.sql'
    WHEN EXISTS (
      SELECT 1 FROM teacher_fee_collections tfc
      CROSS JOIN school_settings ss
      WHERE tfc.academic_year != ss.current_academic_year 
         OR tfc.term != ss.current_term
    )
    THEN '❌ YEAR/TERM MISMATCH - Collections are for different period'
    ELSE '✅ Should work - Check browser console for errors'
  END as likely_issue;
