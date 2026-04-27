-- FINAL FIX: Make admin see collections RIGHT NOW
-- This will recreate the RPC function with LEFT JOIN instead of JOIN
-- to handle any edge cases

-- ============================================
-- 1. Drop and recreate RPC function with LEFT JOIN
-- ============================================
DROP FUNCTION IF EXISTS get_all_teacher_collections(UUID, TEXT, TEXT);

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
    COALESCE(t.full_name, 'Unknown Teacher') as teacher_name,
    tfc.student_id,
    COALESCE(s.full_name, 'Unknown Student') as student_name,
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
  LEFT JOIN teachers t ON t.id = tfc.teacher_id
  LEFT JOIN students s ON s.id = tfc.student_id
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

GRANT EXECUTE ON FUNCTION get_all_teacher_collections(UUID, TEXT, TEXT) TO authenticated;

SELECT '✅ Step 1: RPC function recreated with LEFT JOIN' as status;

-- ============================================
-- 2. Test the function
-- ============================================
SELECT 
  '✅ Step 2: Testing RPC Function' as status,
  COUNT(*) as collections_returned
FROM get_all_teacher_collections(
  (SELECT id FROM schools LIMIT 1),
  '2024/2025',
  'Term 1'
);

-- ============================================
-- 3. Show what admin will see
-- ============================================
SELECT 
  '✅ Step 3: Collections Admin Will See' as status,
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
  '2024/2025',
  'Term 1'
);

-- ============================================
-- 4. Verify all collections are for correct year/term
-- ============================================
SELECT 
  '✅ Step 4: Verify Year/Term' as status,
  academic_year,
  term,
  COUNT(*) as collection_count,
  CASE 
    WHEN academic_year = '2024/2025' AND term = 'Term 1' 
    THEN '✅ Correct'
    ELSE '❌ Wrong year/term'
  END as match_status
FROM teacher_fee_collections
GROUP BY academic_year, term;

-- ============================================
-- FINAL STATUS
-- ============================================
SELECT 
  '🎉 FINAL STATUS' as summary,
  (SELECT COUNT(*) FROM teacher_fee_collections WHERE academic_year = '2024/2025' AND term = 'Term 1') as collections_in_db,
  (SELECT COUNT(*) FROM get_all_teacher_collections(
    (SELECT id FROM schools LIMIT 1),
    '2024/2025',
    'Term 1'
  )) as collections_rpc_returns,
  CASE 
    WHEN (SELECT COUNT(*) FROM get_all_teacher_collections(
      (SELECT id FROM schools LIMIT 1),
      '2024/2025',
      'Term 1'
    )) > 0
    THEN '✅ SUCCESS! Refresh admin page now (Ctrl+R)'
    ELSE '❌ Still returning 0 - Check browser console for errors'
  END as action;
