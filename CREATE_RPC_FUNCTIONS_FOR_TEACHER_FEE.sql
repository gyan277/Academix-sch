-- Create RPC functions to bypass PostgREST schema cache
-- Run this in Supabase SQL Editor

-- Function 1: Get teacher's class assignment
CREATE OR REPLACE FUNCTION get_teacher_class(p_user_id UUID)
RETURNS TABLE (
  class_assigned TEXT,
  teacher_id UUID,
  full_name TEXT
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    t.class_assigned,
    t.id as teacher_id,
    t.full_name
  FROM teachers t
  WHERE t.user_id = p_user_id
  LIMIT 1;
END;
$$;

-- Function 2: Check if feature is enabled
CREATE OR REPLACE FUNCTION is_teacher_fee_collection_enabled(p_school_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_enabled BOOLEAN;
BEGIN
  SELECT COALESCE(enable_teacher_fee_collection, false)
  INTO v_enabled
  FROM school_settings
  WHERE id = p_school_id;
  
  RETURN COALESCE(v_enabled, false);
END;
$$;

-- Function 3: Get students in teacher's class with fees
CREATE OR REPLACE FUNCTION get_teacher_students_with_fees(
  p_school_id UUID,
  p_class TEXT,
  p_academic_year TEXT,
  p_term TEXT
)
RETURNS TABLE (
  student_id UUID,
  student_number TEXT,
  full_name TEXT,
  bus_fee DECIMAL,
  canteen_fee DECIMAL,
  uses_bus BOOLEAN,
  uses_canteen BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    s.id as student_id,
    s.student_number,
    s.full_name,
    CASE 
      WHEN sfo.uses_bus THEN COALESCE(sfo.bus_fee_override, cf.bus_fee, 0)
      ELSE 0
    END as bus_fee,
    CASE 
      WHEN sfo.uses_canteen THEN COALESCE(sfo.canteen_fee_override, cf.canteen_fee, 0)
      ELSE 0
    END as canteen_fee,
    COALESCE(sfo.uses_bus, false) as uses_bus,
    COALESCE(sfo.uses_canteen, false) as uses_canteen
  FROM students s
  LEFT JOIN class_fees cf ON 
    cf.school_id = s.school_id AND 
    cf.class = s.class AND
    cf.academic_year = p_academic_year AND
    cf.term = p_term
  LEFT JOIN student_fee_overrides sfo ON 
    sfo.student_id = s.id AND
    sfo.academic_year = p_academic_year AND
    sfo.term = p_term
  WHERE s.school_id = p_school_id
    AND s.class = p_class
    AND s.status = 'active'
  ORDER BY s.full_name;
END;
$$;

-- Function 4: Record fee collection
CREATE OR REPLACE FUNCTION record_teacher_fee_collection(
  p_school_id UUID,
  p_teacher_id UUID,
  p_student_id UUID,
  p_collection_type TEXT,
  p_amount DECIMAL,
  p_collection_date DATE,
  p_notes TEXT,
  p_academic_year TEXT,
  p_term TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_collection_id UUID;
BEGIN
  INSERT INTO teacher_fee_collections (
    school_id,
    teacher_id,
    student_id,
    collection_type,
    amount,
    collection_date,
    notes,
    academic_year,
    term,
    status
  ) VALUES (
    p_school_id,
    p_teacher_id,
    p_student_id,
    p_collection_type,
    p_amount,
    p_collection_date,
    p_notes,
    p_academic_year,
    p_term,
    'pending'
  )
  RETURNING id INTO v_collection_id;
  
  RETURN v_collection_id;
END;
$$;

-- Function 5: Get teacher's collections
CREATE OR REPLACE FUNCTION get_teacher_collections(
  p_school_id UUID,
  p_teacher_id UUID,
  p_academic_year TEXT,
  p_term TEXT
)
RETURNS TABLE (
  collection_id UUID,
  student_id UUID,
  student_name TEXT,
  collection_type TEXT,
  amount DECIMAL,
  collection_date DATE,
  status TEXT,
  notes TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    tfc.id as collection_id,
    tfc.student_id,
    s.full_name as student_name,
    tfc.collection_type,
    tfc.amount,
    tfc.collection_date,
    tfc.status,
    tfc.notes
  FROM teacher_fee_collections tfc
  JOIN students s ON s.id = tfc.student_id
  WHERE tfc.school_id = p_school_id
    AND tfc.teacher_id = p_teacher_id
    AND tfc.academic_year = p_academic_year
    AND tfc.term = p_term
  ORDER BY tfc.collection_date DESC;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_teacher_class(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION is_teacher_fee_collection_enabled(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_teacher_students_with_fees(UUID, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION record_teacher_fee_collection(UUID, UUID, UUID, TEXT, DECIMAL, DATE, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_teacher_collections(UUID, UUID, TEXT, TEXT) TO authenticated;

-- Verify functions created
SELECT 
  '✅ RPC Functions Created!' as status,
  'These functions bypass the schema cache' as info,
  'Now update the frontend to use these functions' as next_step;

SELECT 
  routine_name as function_name,
  '✅ Created' as status
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name LIKE '%teacher%'
ORDER BY routine_name;
