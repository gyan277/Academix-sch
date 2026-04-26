-- FIX ATTENDANCE CLASS CONSTRAINT
-- Allow class to be NULL for staff attendance

-- Step 1: Drop the NOT NULL constraint on class
ALTER TABLE attendance 
ALTER COLUMN class DROP NOT NULL;

-- Step 2: Verify the change
SELECT 
  'After Fix' as info,
  column_name,
  is_nullable,
  data_type
FROM information_schema.columns
WHERE table_name = 'attendance'
  AND column_name = 'class';

-- Step 3: Update the check constraint to be more flexible
ALTER TABLE attendance
DROP CONSTRAINT IF EXISTS attendance_student_or_staff_check;

ALTER TABLE attendance
ADD CONSTRAINT attendance_student_or_staff_check
CHECK (
  -- Student attendance: has student_id and class, no staff_id
  (student_id IS NOT NULL AND staff_id IS NULL AND class IS NOT NULL) OR
  -- Staff attendance: has staff_id, no student_id, no class
  (staff_id IS NOT NULL AND student_id IS NULL AND class IS NULL)
);

-- Step 4: Test inserting staff attendance
DO $$
DECLARE
  test_school_id UUID := (SELECT id FROM schools LIMIT 1);
  test_staff_id UUID := (SELECT id FROM staff LIMIT 1);
  test_admin_id UUID := (SELECT id FROM users WHERE role = 'admin' LIMIT 1);
BEGIN
  IF test_staff_id IS NOT NULL THEN
    -- Try inserting a staff attendance record
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
      NULL, -- This should now work
      test_admin_id
    );
    
    RAISE NOTICE 'Staff attendance insert test: SUCCESS';
    
    -- Clean up test record
    DELETE FROM attendance 
    WHERE staff_id = test_staff_id 
      AND date = CURRENT_DATE;
  ELSE
    RAISE NOTICE 'No staff found to test with';
  END IF;
    
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Staff attendance insert test: FAILED - %', SQLERRM;
END $$;

COMMENT ON CONSTRAINT attendance_student_or_staff_check ON attendance IS
'Ensures proper attendance records: student attendance has student_id and class; staff attendance has staff_id only.';
