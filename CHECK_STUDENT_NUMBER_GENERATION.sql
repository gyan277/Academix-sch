-- Check student number generation system
-- Run this in Supabase SQL Editor

-- 1. Check current student numbers
SELECT 
  full_name,
  student_number,
  school_id,
  created_at
FROM students
ORDER BY created_at DESC
LIMIT 10;

-- 2. Check if the trigger function exists
SELECT 
  routine_name,
  routine_type
FROM information_schema.routines
WHERE routine_name LIKE '%student_number%';

-- 3. Check if the trigger exists
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table
FROM information_schema.triggers
WHERE event_object_table = 'students';

-- 4. Check school abbreviations
SELECT 
  id,
  school_name,
  UPPER(LEFT(school_name, 3)) as abbreviation
FROM schools;

-- 5. Check the current sequence for student numbers
SELECT 
  schemaname,
  sequencename,
  last_value
FROM pg_sequences
WHERE sequencename LIKE '%student%';