-- CHECK ATTENDANCE TABLE SCHEMA
-- Verify the current state of the attendance table

-- Check column definitions
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'attendance'
ORDER BY ordinal_position;

-- Check all constraints
SELECT 
  conname as constraint_name,
  contype as constraint_type,
  pg_get_constraintdef(oid) as definition
FROM pg_constraint
WHERE conrelid = 'attendance'::regclass;

-- Check if there are any existing staff attendance records
SELECT 
  COUNT(*) as staff_attendance_count,
  MIN(date) as earliest_date,
  MAX(date) as latest_date
FROM attendance
WHERE staff_id IS NOT NULL;

-- Check if there are any existing student attendance records
SELECT 
  COUNT(*) as student_attendance_count,
  MIN(date) as earliest_date,
  MAX(date) as latest_date
FROM attendance
WHERE student_id IS NOT NULL;
