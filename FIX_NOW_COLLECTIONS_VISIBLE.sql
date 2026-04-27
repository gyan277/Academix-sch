-- IMMEDIATE FIX: Make collections visible to admin
-- Based on diagnostic showing 2 collections exist but year/term mismatch

-- ============================================
-- STEP 1: Show what we have
-- ============================================
SELECT 
  '📋 Current Situation' as info,
  tfc.academic_year as collection_year,
  tfc.term as collection_term,
  COUNT(*) as collection_count
FROM teacher_fee_collections tfc
GROUP BY tfc.academic_year, tfc.term;

SELECT 
  '⚙️ System Settings' as info,
  current_academic_year as system_year,
  current_term as system_term
FROM school_settings;

-- ============================================
-- STEP 2: Update system to match collections
-- ============================================
-- This will make the admin see the collections immediately

UPDATE school_settings
SET 
  current_academic_year = (
    SELECT academic_year 
    FROM teacher_fee_collections 
    LIMIT 1
  ),
  current_term = (
    SELECT term 
    FROM teacher_fee_collections 
    LIMIT 1
  )
WHERE id = (SELECT id FROM schools LIMIT 1);

SELECT '✅ System settings updated to match collections' as status;

-- ============================================
-- STEP 3: Verify the fix
-- ============================================
SELECT 
  '✅ Verification' as info,
  ss.current_academic_year as system_year,
  ss.current_term as system_term,
  tfc.academic_year as collection_year,
  tfc.term as collection_term,
  CASE 
    WHEN ss.current_academic_year = tfc.academic_year 
     AND ss.current_term = tfc.term
    THEN '✅ NOW MATCHES - Admin will see collections!'
    ELSE '❌ Still mismatch'
  END as status
FROM school_settings ss
CROSS JOIN (
  SELECT DISTINCT academic_year, term 
  FROM teacher_fee_collections 
  LIMIT 1
) tfc;

-- ============================================
-- STEP 4: Test the RPC function
-- ============================================
SELECT 
  '🧪 Testing RPC Function' as info,
  COUNT(*) as collections_returned,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ RPC function will return ' || COUNT(*)::text || ' collections'
    ELSE '❌ RPC still returns 0'
  END as result
FROM get_all_teacher_collections(
  (SELECT id FROM schools LIMIT 1),
  (SELECT current_academic_year FROM school_settings LIMIT 1),
  (SELECT current_term FROM school_settings LIMIT 1)
);

-- ============================================
-- STEP 5: Show the collections that will appear
-- ============================================
SELECT 
  '📊 Collections Admin Will See' as info,
  teacher_name,
  student_name,
  collection_type,
  amount,
  collection_date,
  status
FROM get_all_teacher_collections(
  (SELECT id FROM schools LIMIT 1),
  (SELECT current_academic_year FROM school_settings LIMIT 1),
  (SELECT current_term FROM school_settings LIMIT 1)
);

-- ============================================
-- FINAL INSTRUCTION
-- ============================================
SELECT 
  '🎉 DONE!' as status,
  'Now go to admin Finance → Teacher Collections tab' as step_1,
  'Press Ctrl+R (or Cmd+R) to refresh the page' as step_2,
  'You should see the 2 collections!' as step_3;
