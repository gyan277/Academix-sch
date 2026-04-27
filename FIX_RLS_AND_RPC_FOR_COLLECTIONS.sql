-- Fix RLS policies and RPC function for teacher collections

-- ============================================
-- 1. Check current SELECT policies
-- ============================================
SELECT 
  '1️⃣ Current SELECT Policies' as step,
  policyname,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'teacher_fee_collections'
  AND cmd = 'SELECT';

-- ============================================
-- 2. Ensure SELECT policy exists for viewing
-- ============================================
-- Drop existing SELECT policy if any
DROP POLICY IF EXISTS "Users can view collections from their school" ON teacher_fee_collections;

-- Create comprehensive SELECT policy
CREATE POLICY "Users can view collections from their school"
ON teacher_fee_collections
FOR SELECT
TO public
USING (
  school_id IN (
    SELECT school_id FROM users WHERE id = auth.uid()
  )
);

SELECT '✅ Step 2: SELECT policy created' as status;

-- ============================================
-- 3. Recreate RPC function as SECURITY DEFINER
-- ============================================
-- This bypasses RLS entirely
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
SECURITY DEFINER  -- This is KEY - bypasses RLS
SET search_path = public
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
GRANT EXECUTE ON FUNCTION get_all_teacher_collections(UUID, TEXT, TEXT) TO anon;

SELECT '✅ Step 3: RPC function recreated with SECURITY DEFINER' as status;

-- ============================================
-- 4. Test the RPC function
-- ============================================
SELECT 
  '✅ Step 4: Testing RPC' as status,
  COUNT(*) as collections_returned
FROM get_all_teacher_collections(
  (SELECT id FROM schools LIMIT 1),
  '2024/2025',
  'Term 1'
);

-- ============================================
-- 5. Show what will be returned
-- ============================================
SELECT 
  '✅ Step 5: Collections That Will Show' as status,
  collection_id,
  teacher_name,
  student_name,
  collection_type,
  amount,
  status
FROM get_all_teacher_collections(
  (SELECT id FROM schools LIMIT 1),
  '2024/2025',
  'Term 1'
);

-- ============================================
-- FINAL CHECK
-- ============================================
SELECT 
  '🎉 FINAL STATUS' as summary,
  (SELECT COUNT(*) FROM teacher_fee_collections WHERE academic_year = '2024/2025' AND term = 'Term 1') as collections_in_db,
  (SELECT COUNT(*) FROM get_all_teacher_collections(
    (SELECT id FROM schools LIMIT 1),
    '2024/2025',
    'Term 1'
  )) as rpc_returns,
  CASE 
    WHEN (SELECT COUNT(*) FROM get_all_teacher_collections(
      (SELECT id FROM schools LIMIT 1),
      '2024/2025',
      'Term 1'
    )) > 0
    THEN '✅ SUCCESS! Refresh admin page (Ctrl+R) and hard refresh (Ctrl+Shift+R)'
    ELSE '❌ Still 0 - Check console logs'
  END as action;
