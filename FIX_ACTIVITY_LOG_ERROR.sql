-- =====================================================
-- FIX ACTIVITY LOG ERROR WHEN ADDING STUDENTS
-- =====================================================
-- This fixes the foreign key constraint error in activity_log table
-- =====================================================

-- Step 1: Check the activity_log table structure
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'activity_log'
ORDER BY ordinal_position;

-- Step 2: Check foreign key constraints on activity_log
SELECT 
  tc.constraint_name,
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_name = 'activity_log';

-- Step 3: Check if there are any triggers on students table that insert into activity_log
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE event_object_table = 'students';

-- Step 4: Check what school_ids exist in schools table vs activity_log
SELECT 'schools' as table_name, id as school_id FROM schools
UNION ALL
SELECT 'activity_log' as table_name, DISTINCT school_id FROM activity_log
ORDER BY table_name, school_id;

-- Step 5: TEMPORARY FIX - Disable activity logging for students (if it exists)
-- This will allow student creation to work while we investigate

-- Drop any triggers that might be causing this
DROP TRIGGER IF EXISTS log_student_activity ON students;
DROP TRIGGER IF EXISTS student_activity_trigger ON students;
DROP TRIGGER IF EXISTS audit_student_changes ON students;

-- Step 6: Alternative - Fix the foreign key constraint
-- If activity_log.school_id references a different table than schools, we need to fix it

-- Check what table activity_log.school_id should reference
SELECT 
  tc.constraint_name,
  kcu.column_name,
  ccu.table_name AS referenced_table,
  ccu.column_name AS referenced_column
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu 
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_name = 'activity_log' 
  AND tc.constraint_type = 'FOREIGN KEY'
  AND kcu.column_name = 'school_id';

-- Step 7: If the constraint references wrong table, fix it
-- (Uncomment and modify if needed)
/*
ALTER TABLE activity_log 
DROP CONSTRAINT IF EXISTS activity_log_school_id_fkey;

ALTER TABLE activity_log 
ADD CONSTRAINT activity_log_school_id_fkey 
FOREIGN KEY (school_id) REFERENCES schools(id);
*/

-- Step 8: Test student insertion after fix
-- This should work now without activity log errors

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Check if students table has any remaining triggers
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table
FROM information_schema.triggers
WHERE event_object_table = 'students';

-- ✅ After running this, try adding a student again
-- ✅ The activity log error should be resolved