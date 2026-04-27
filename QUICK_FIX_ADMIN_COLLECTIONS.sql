-- QUICK FIX: Make admin see teacher collections
-- Run this in Supabase SQL Editor

-- ============================================
-- FIX 1: Create/Recreate the RPC function
-- ============================================
CREATE OR REPLACE FUNCTION get_all_teacher_collections(
  p_school_id UUID,
  p_academic_year TEXT,
  p_term TEXT
)
RETURNS TABLE (
  collection_id UUID,
  teacher_id UUID,
  teacher_name TEXT,
  student_id UUID,
  student_name TEXT,
  collection_type TEXT,
  amount DECIMAL,
  collection_date DATE,
  status TEXT,
  notes TEXT,
  rejection_reason TEXT,
  confirmed_by UUID,
  confirmed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    tfc.id as collection_id,
    tfc.teacher_id,
    t.full_name as teacher_name,
    tfc.student_id,
    s.full_name as student_name,
    tfc.collection_type,
    tfc.amount,
    tfc.collection_date,
    tfc.status,
    tfc.notes,
    tfc.rejection_reason,
    tfc.confirmed_by,
    tfc.confirmed_at,
    tfc.created_at
  FROM teacher_fee_collections tfc
  JOIN teachers t ON t.id = tfc.teacher_id
  JOIN students s ON s.id = tfc.student_id
  WHERE tfc.school_id = p_school_id
    AND tfc.academic_year = p_academic_year
    AND tfc.term = p_term
  ORDER BY 
    CASE tfc.status
      WHEN 'pending' THEN 1
      WHEN 'confirmed' THEN 2
      WHEN 'rejected' THEN 3
      ELSE 4
    END,
    tfc.collection_date DESC;
END;
$$;

-- Grant permission
GRANT EXECUTE ON FUNCTION get_all_teacher_collections(UUID, TEXT, TEXT) TO authenticated;

SELECT '✅ Step 1: RPC function created/updated' as status;

-- ============================================
-- FIX 2: Check if collections exist
-- ============================================
SELECT 
  '✅ Step 2: Collections Check' as status,
  COUNT(*) as total_collections,
  COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending,
  CASE 
    WHEN COUNT(*) = 0 THEN '❌ No collections - Teacher needs to collect fees first'
    ELSE '✅ Found ' || COUNT(*)::text || ' collections'
  END as result
FROM teacher_fee_collections;

-- ============================================
-- FIX 3: Show what the RPC function will return
-- ============================================
SELECT 
  '✅ Step 3: Testing RPC Function' as status,
  'Running get_all_teacher_collections...' as action;

SELECT 
  collection_id,
  teacher_name,
  student_name,
  collection_type,
  amount,
  collection_date,
  status,
  academic_year,
  term
FROM get_all_teacher_collections(
  (SELECT id FROM schools LIMIT 1),
  (SELECT current_academic_year FROM school_settings LIMIT 1),
  (SELECT current_term FROM school_settings LIMIT 1)
);

-- ============================================
-- FIX 4: Check for year/term mismatch
-- ============================================
WITH current_settings AS (
  SELECT current_academic_year, current_term
  FROM school_settings
  LIMIT 1
),
collection_periods AS (
  SELECT DISTINCT academic_year, term
  FROM teacher_fee_collections
)
SELECT 
  '⚠️ Step 4: Year/Term Mismatch Check' as status,
  cp.academic_year as collection_year,
  cp.term as collection_term,
  cs.current_academic_year as system_year,
  cs.current_term as system_term,
  CASE 
    WHEN cp.academic_year = cs.current_academic_year AND cp.term = cs.current_term
    THEN '✅ MATCH - Admin should see these'
    ELSE '❌ MISMATCH - Admin is filtering by ' || cs.current_academic_year || ' ' || cs.current_term || 
         ' but collections are for ' || cp.academic_year || ' ' || cp.term
  END as diagnosis
FROM collection_periods cp
CROSS JOIN current_settings cs;

-- ============================================
-- FIX 5: If mismatch, show how to fix
-- ============================================
DO $$
DECLARE
  v_collection_year TEXT;
  v_collection_term TEXT;
  v_system_year TEXT;
  v_system_term TEXT;
  v_mismatch BOOLEAN;
BEGIN
  -- Get first collection's year/term
  SELECT academic_year, term
  INTO v_collection_year, v_collection_term
  FROM teacher_fee_collections
  LIMIT 1;
  
  -- Get system year/term
  SELECT current_academic_year, current_term
  INTO v_system_year, v_system_term
  FROM school_settings
  LIMIT 1;
  
  -- Check for mismatch
  v_mismatch := (v_collection_year != v_system_year OR v_collection_term != v_system_term);
  
  IF v_mismatch THEN
    RAISE NOTICE '❌ MISMATCH DETECTED!';
    RAISE NOTICE 'Collections are for: % %', v_collection_year, v_collection_term;
    RAISE NOTICE 'System is set to: % %', v_system_year, v_system_term;
    RAISE NOTICE '';
    RAISE NOTICE '🔧 TO FIX: Run this command to update system settings:';
    RAISE NOTICE 'UPDATE school_settings SET current_academic_year = ''%'', current_term = ''%'';', 
      v_collection_year, v_collection_term;
  ELSE
    RAISE NOTICE '✅ No year/term mismatch';
  END IF;
END $$;

-- ============================================
-- FINAL SUMMARY
-- ============================================
SELECT 
  '📊 FINAL STATUS' as summary,
  (SELECT COUNT(*) FROM teacher_fee_collections) as collections_in_database,
  (SELECT COUNT(*) FROM get_all_teacher_collections(
    (SELECT id FROM schools LIMIT 1),
    (SELECT current_academic_year FROM school_settings LIMIT 1),
    (SELECT current_term FROM school_settings LIMIT 1)
  )) as collections_rpc_returns,
  CASE 
    WHEN (SELECT COUNT(*) FROM teacher_fee_collections) = 0 
    THEN '❌ No collections - Teacher needs to collect fees'
    WHEN (SELECT COUNT(*) FROM get_all_teacher_collections(
      (SELECT id FROM schools LIMIT 1),
      (SELECT current_academic_year FROM school_settings LIMIT 1),
      (SELECT current_term FROM school_settings LIMIT 1)
    )) = 0
    THEN '❌ Year/term mismatch - Update school_settings or have teacher collect again'
    ELSE '✅ Should work now - Refresh admin page (Ctrl+R)'
  END as action_needed;
