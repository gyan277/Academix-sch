-- COMPLETE STAFF ATTENDANCE FIX
-- This script ensures staff attendance can be saved properly

-- ============================================
-- STEP 1: Fix Column Constraints
-- ============================================

-- Make student_id nullable (for staff attendance)
ALTER TABLE attendance 
ALTER COLUMN student_id DROP NOT NULL;

-- Make class nullable (for staff attendance)
ALTER TABLE attendance 
ALTER COLUMN class DROP NOT NULL;

-- Make staff_id nullable (for student attendance)
ALTER TABLE attendance 
ALTER COLUMN staff_id DROP NOT NULL;

RAISE NOTICE 'Step 1: Column constraints updated';

-- ============================================
-- STEP 2: Add Proper Check Constraint
-- ============================================

-- Drop existing check constraint if it exists
ALTER TABLE attendance
DROP CONSTRAINT IF EXISTS attendance_student_or_staff_check;

-- Add new check constraint
ALTER TABLE attendance
ADD CONSTRAINT attendance_student_or_staff_check
CHECK (
  -- Student attendance: has student_id and class, no staff_id
  (student_id IS NOT NULL AND staff_id IS NULL AND class IS NOT NULL) OR
  -- Staff attendance: has staff_id, no student_id, no class
  (staff_id IS NOT NULL AND student_id IS NULL AND class IS NULL)
);

RAISE NOTICE 'Step 2: Check constraint added';

-- ============================================
-- STEP 3: Verify RLS Policies
-- ============================================

-- Check if RLS is enabled
DO $$
DECLARE
  rls_enabled BOOLEAN;
BEGIN
  SELECT rowsecurity INTO rls_enabled
  FROM pg_tables
  WHERE tablename = 'attendance';
  
  IF rls_enabled THEN
    RAISE NOTICE 'Step 3: RLS is ENABLED on attendance table';
    
    -- Show all policies
    RAISE NOTICE 'Current RLS Policies:';
    FOR rec IN 
      SELECT policyname, cmd, roles
      FROM pg_policies
      WHERE tablename = 'attendance'
    LOOP
      RAISE NOTICE '  - Policy: %, Command: %, Roles: %', rec.policyname, rec.cmd, rec.roles;
    END LOOP;
  ELSE
    RAISE NOTICE 'Step 3: RLS is DISABLED on attendance table';
  END IF;
END $$;

-- ============================================
-- STEP 4: Test Staff Attendance Insert
-- ============================================

DO $$
DECLARE
  test_school_id UUID;
  test_staff_id UUID;
  test_admin_id UUID;
  v_error_message TEXT;
  v_inserted_id UUID;
BEGIN
  -- Get test IDs
  SELECT id INTO test_school_id FROM schools LIMIT 1;
  SELECT id INTO test_staff_id FROM staff WHERE status = 'active' LIMIT 1;
  SELECT id INTO test_admin_id FROM users WHERE role = 'admin' LIMIT 1;
  
  RAISE NOTICE 'Step 4: Testing staff attendance insert';
  RAISE NOTICE '  School ID: %', test_school_id;
  RAISE NOTICE '  Staff ID: %', test_staff_id;
  RAISE NOTICE '  Admin ID: %', test_admin_id;
  
  IF test_staff_id IS NULL THEN
    RAISE NOTICE '  ERROR: No active staff found to test with';
    RETURN;
  END IF;
  
  IF test_admin_id IS NULL THEN
    RAISE NOTICE '  ERROR: No admin user found to test with';
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
    )
    RETURNING id INTO v_inserted_id;
    
    RAISE NOTICE '  ✅ SUCCESS: Staff attendance inserted with ID: %', v_inserted_id;
    
    -- Clean up test record
    DELETE FROM attendance WHERE id = v_inserted_id;
    RAISE NOTICE '  Test record cleaned up';
    
  EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS v_error_message = MESSAGE_TEXT;
      RAISE NOTICE '  ❌ FAILED: %', v_error_message;
      RAISE NOTICE '  SQLSTATE: %', SQLSTATE;
  END;
END $$;

-- ============================================
-- STEP 5: Show Final Schema
-- ============================================

SELECT 
  '=== FINAL ATTENDANCE TABLE SCHEMA ===' as info;

SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'attendance'
ORDER BY ordinal_position;

SELECT 
  '=== CONSTRAINTS ===' as info;

SELECT 
  conname as constraint_name,
  contype as constraint_type,
  pg_get_constraintdef(oid) as definition
FROM pg_constraint
WHERE conrelid = 'attendance'::regclass;

RAISE NOTICE '✅ Complete staff attendance fix applied successfully!';
