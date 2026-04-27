-- Create RPC function for admin to view all teacher collections
-- Run this in Supabase SQL Editor

-- Function: Get all teacher collections for admin
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

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_all_teacher_collections(UUID, TEXT, TEXT) TO authenticated;

-- Verify function created
SELECT 
  '✅ Admin RPC Function Created!' as status,
  'Function: get_all_teacher_collections' as function_name,
  'This bypasses the schema cache for admin viewing collections' as info;

-- Test the function (adjust parameters as needed)
SELECT 
  'Testing function...' as test,
  COUNT(*) as total_collections
FROM get_all_teacher_collections(
  (SELECT id FROM schools LIMIT 1),
  '2024/2025',
  'Term 1'
);