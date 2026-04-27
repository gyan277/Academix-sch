-- Comprehensive diagnostic for admin not seeing teacher collections
-- Run this in Supabase SQL Editor

-- ============================================
-- STEP 1: Check if RPC function exists
-- ============================================
SELECT 
  '1️⃣ CHECK RPC FUNCTION' as step,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.routines 
      WHERE routine_schema = 'public' 
      AND routine_name = 'get_all_teacher_collections'
    ) THEN '✅ Function exists'
    ELSE '❌ Function NOT found - Run CREATE_RPC_FOR_ADMIN_COLLECTIONS.sql'
  END as status;

-- ============================================
-- STEP 2: Check if collections exist
-- ============================================
SELECT 
  '2️⃣ CHECK COLLECTIONS EXIST' as step,
  COUNT(*) as total_collections,
  CASE 
    WHEN COUNT(*) = 0 THEN '❌ No collections - Teacher needs to collect fees first'
    ELSE '✅ Collections found: ' || COUNT(*)::text
  END as status
FROM teacher_fee_collections;

-- ============================================
-- STEP 3: Show all collections with details
-- ============================================
SELECT 
  '3️⃣ ALL COLLECTIONS' as step,
  tfc.id,
  tfc.collection_date,
  tfc.collection_type,
  tfc.amount,
  tfc.status,
  tfc.academic_year,
  tfc.term,
  t.full_name as teacher_name,
  s.full_name as student_name,
  tfc.school_id
FROM teacher_fee_collections tfc
LEFT JOIN teachers t ON t.id = tfc.teacher_id
LEFT JOIN students s ON s.id = tfc.student_id
ORDER BY tfc.created_at DESC;

-- ============================================
-- STEP 4: Check current academic settings
-- ============================================
SELECT 
  '4️⃣ CURRENT ACADEMIC SETTINGS' as step,
  ss.id as school_id,
  ss.current_academic_year,
  ss.current_term,
  ss.enable_teacher_fee_collection,
  sc.name as school_name
FROM school_settings ss
JOIN schools sc ON sc.id = ss.id;

-- ============================================
-- STEP 5: Test RPC function directly
-- ============================================
DO $$
DECLARE
  v_school_id UUID;
  v_academic_year TEXT;
  v_term TEXT;
  v_count INTEGER;
BEGIN
  -- Get current settings
  SELECT id, current_academic_year, current_term
  INTO v_school_id, v_academic_year, v_term
  FROM school_settings
  LIMIT 1;
  
  -- Test the RPC function
  SELECT COUNT(*)
  INTO v_count
  FROM get_all_teacher_collections(v_school_id, v_academic_year, v_term);
  
  RAISE NOTICE '5️⃣ RPC FUNCTION TEST: Found % collections for school_id=%, year=%, term=%', 
    v_count, v_school_id, v_academic_year, v_term;
END $$;

-- ============================================
-- STEP 6: Check for academic year mismatch
-- ============================================
SELECT 
  '6️⃣ ACADEMIC YEAR MISMATCH CHECK' as step,
  tfc.academic_year as collection_year,
  tfc.term as collection_term,
  ss.current_academic_year as current_year,
  ss.current_term as current_term,
  CASE 
    WHEN tfc.academic_year = ss.current_academic_year AND tfc.term = ss.current_term 
    THEN '✅ Match'
    ELSE '❌ MISMATCH - Collections are for different year/term!'
  END as match_status,
  COUNT(*) as collection_count
FROM teacher_fee_collections tfc
CROSS JOIN school_settings ss
GROUP BY tfc.academic_year, tfc.term, ss.current_academic_year, ss.current_term;

-- ============================================
-- STEP 7: Check teacher and student records
-- ============================================
SELECT 
  '7️⃣ TEACHER & STUDENT RECORDS' as step,
  t.full_name as teacher_name,
  t.class_assigned,
  s.full_name as student_name,
  s.class as student_class,
  CASE 
    WHEN t.class_assigned = s.class THEN '✅ Class match'
    ELSE '⚠️ Class mismatch'
  END as class_match
FROM teacher_fee_collections tfc
JOIN teachers t ON t.id = tfc.teacher_id
JOIN students s ON s.id = tfc.student_id;

-- ============================================
-- STEP 8: Check RLS policies
-- ============================================
SELECT 
  '8️⃣ RLS POLICIES' as step,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'teacher_fee_collections'
ORDER BY policyname;

-- ============================================
-- SUMMARY
-- ============================================
SELECT 
  '📊 DIAGNOSTIC SUMMARY' as summary,
  (SELECT COUNT(*) FROM teacher_fee_collections) as total_collections,
  (SELECT COUNT(*) FROM teacher_fee_collections WHERE status = 'pending') as pending_collections,
  (SELECT current_academic_year FROM school_settings LIMIT 1) as current_year,
  (SELECT current_term FROM school_settings LIMIT 1) as current_term,
  (SELECT enable_teacher_fee_collection FROM school_settings LIMIT 1) as feature_enabled;
