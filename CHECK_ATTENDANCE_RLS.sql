-- CHECK ATTENDANCE RLS POLICIES
-- Verify Row Level Security policies on attendance table

-- Check if RLS is enabled
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE tablename = 'attendance';

-- Check all RLS policies
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd as command,
  qual as using_expression,
  with_check as with_check_expression
FROM pg_policies
WHERE tablename = 'attendance';

-- Test staff attendance insert with detailed error
DO $$
DECLARE
  test_school_id UUID;
  test_staff_id UUID;
  test_admin_id UUID;
  v_error_message TEXT;
BEGIN
  -- Get test IDs
  SELECT id INTO test_school_id FROM schools LIMIT 1;
  SELECT id INTO test_staff_id FROM staff WHERE status = 'active' LIMIT 1;
  SELECT id INTO test_admin_id FROM users WHERE role = 'admin' LIMIT 1;
  
  RAISE NOTICE 'Test IDs:';
  RAISE NOTICE '  School ID: %', test_school_id;
  RAISE NOTICE '  Staff ID: %', test_staff_id;
  RAISE NOTICE '  Admin ID: %', test_admin_id;
  
  IF test_staff_id IS NULL THEN
    RAISE NOTICE 'ERROR: No active staff found to test with';
    RETURN;
  END IF;
  
  IF test_admin_id IS NULL THEN
    RAISE NOTICE 'ERROR: No admin user found to test with';
    RETURN;
  END IF;
  
  -- Try inserting a staff attendance record
  BEGIN
    INSERT INTO attendance (
      school_id,
      staff_id,
      student_id,
      date,
      status,
      class,
      recorded_by
    )
    VALUES (
      test_school_id,
      test_staff_id,
      NULL,
      CURRENT_DATE,
      'present',
      NULL,
      test_admin_id
    );
    
    RAISE NOTICE 'SUCCESS: Staff attendance inserted successfully';
    
    -- Clean up test record
    DELETE FROM attendance 
    WHERE staff_id = test_staff_id 
      AND date = CURRENT_DATE;
      
    RAISE NOTICE 'Test record cleaned up';
    
  EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS v_error_message = MESSAGE_TEXT;
      RAISE NOTICE 'FAILED: %', v_error_message;
      RAISE NOTICE 'SQLSTATE: %', SQLSTATE;
  END;
END $$;
