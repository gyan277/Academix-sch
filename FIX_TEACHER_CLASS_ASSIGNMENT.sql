-- Fix Teacher Class Assignments
-- This script helps diagnose and fix class assignment issues

-- Step 1: Check current state
SELECT 
  'Current State' as step,
  t.id,
  t.full_name,
  t.class_assigned,
  CASE 
    WHEN t.class_assigned IS NULL THEN 'NULL'
    WHEN t.class_assigned = '' THEN 'EMPTY STRING'
    ELSE 'HAS VALUE'
  END as status,
  u.email
FROM teachers t
JOIN users u ON t.user_id = u.id
ORDER BY t.full_name;

-- Step 2: Convert empty strings to NULL (for consistency)
UPDATE teachers
SET class_assigned = NULL
WHERE class_assigned = '' OR class_assigned = ' ';

-- Step 3: Show teachers that still need class assignment
SELECT 
  'Teachers Needing Class Assignment' as info,
  t.id,
  t.full_name,
  u.email,
  t.school_id
FROM teachers t
JOIN users u ON t.user_id = u.id
WHERE t.class_assigned IS NULL
ORDER BY t.full_name;

-- Step 4: Example - Assign a class to a specific teacher
-- UNCOMMENT and modify the line below to assign a class
-- UPDATE teachers SET class_assigned = 'Primary 1' WHERE id = 'teacher-uuid-here';

-- Step 5: Verify the fix
SELECT 
  'After Fix' as step,
  COUNT(*) as total_teachers,
  COUNT(class_assigned) as teachers_with_class,
  COUNT(*) - COUNT(class_assigned) as teachers_without_class
FROM teachers;

-- Step 6: Show all teachers with their classes
SELECT 
  'Final State' as step,
  t.full_name,
  t.class_assigned,
  u.email
FROM teachers t
JOIN users u ON t.user_id = u.id
ORDER BY t.class_assigned NULLS LAST, t.full_name;
