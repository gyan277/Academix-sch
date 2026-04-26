-- FIX ATTENDANCE STAFF CONSTRAINT
-- Allow student_id to be NULL for staff attendance

-- Step 1: Check current constraints
SELECT 
  'Current Constraints' as info,
  conname as constraint_name,
  contype as constraint_type,
  pg_get_constraintdef(oid) as definition
FROM pg_constraint
WHERE conrelid = 'attendance'::regclass;

-- Step 2: Drop the NOT NULL constraint on student_id
ALTER TABLE attendance 
ALTER COLUMN student_id DROP NOT NULL;

-- Step 3: Drop the NOT NULL constraint on staff_id (if it exists)
ALTER TABLE attendance 
ALTER COLUMN staff_id DROP NOT NULL;

-- Step 4: Add a CHECK constraint to ensure at least one is provided
ALTER TABLE attendance
DROP CONSTRAINT IF EXISTS attendance_student_or_staff_check;

ALTER TABLE attendance
ADD CONSTRAINT attendance_student_or_staff_check
CHECK (
  (student_id IS NOT NULL AND staff_id IS NULL) OR
  (staff_id IS NOT NULL AND student_id IS NULL)
);

-- Step 5: Verify the changes
SELECT 
  'After Fix' as info,
  column_name,
  is_nullable,
  data_type
FROM information_schema.columns
WHERE table_name = 'attendance'
  AND column_name IN ('student_id', 'staff_id')
ORDER BY column_name;

-- Step 6: Test inserting staff attendance
DO $$
DECLARE
  test_school_id UUID := (SELECT id FROM schools LIMIT 1);
  test_staff_id UUID := (SELECT id FROM staff LIMIT 1);
BEGIN
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
    NULL, -- This should now work
    CURRENT_DATE,
    'present',
    NULL,
    (SELECT id FROM users WHERE role = 'admin' LIMIT 1)
  );
  
  RAISE NOTICE 'Staff attendance insert test: SUCCESS';
  
  -- Clean up test record
  DELETE FROM attendance 
  WHERE staff_id = test_staff_id 
    AND date = CURRENT_DATE;
    
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Staff attendance insert test: FAILED - %', SQLERRM;
END $$;

COMMENT ON CONSTRAINT attendance_student_or_staff_check ON attendance IS
'Ensures that either student_id or staff_id is provided, but not both or neither.';
