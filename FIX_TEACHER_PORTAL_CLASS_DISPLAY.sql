-- Fix teacher portal to show assigned class correctly
-- The RPC function was looking at wrong table structure

-- Drop old function
DROP FUNCTION IF EXISTS get_teacher_class(UUID);

-- Create corrected function that uses teacher_classes table
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
    tc.class as class_assigned,
    tc.teacher_id,
    u.full_name
  FROM teacher_classes tc
  JOIN users u ON u.id = tc.teacher_id
  WHERE tc.teacher_id = p_user_id
  LIMIT 1;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_teacher_class(UUID) TO authenticated;

-- Test the function
SELECT 
  '✅ Function updated!' as status,
  'Testing with all teachers...' as info;

-- Show all teachers and their classes
SELECT 
  u.email,
  u.full_name,
  tc.class as assigned_class,
  ss.school_name,
  tc.academic_year
FROM users u
LEFT JOIN teacher_classes tc ON u.id = tc.teacher_id
LEFT JOIN school_settings ss ON u.school_id = ss.id
WHERE u.role = 'teacher'
ORDER BY u.created_at DESC;

-- Test the RPC function for each teacher
DO $$
DECLARE
  teacher_record RECORD;
  result RECORD;
BEGIN
  FOR teacher_record IN 
    SELECT id, email, full_name 
    FROM users 
    WHERE role = 'teacher'
  LOOP
    -- Test the function
    SELECT * INTO result
    FROM get_teacher_class(teacher_record.id);
    
    RAISE NOTICE 'Teacher: % (%) - Class: %', 
      teacher_record.full_name, 
      teacher_record.email, 
      COALESCE(result.class_assigned, 'NO CLASS ASSIGNED');
  END LOOP;
END $$;
