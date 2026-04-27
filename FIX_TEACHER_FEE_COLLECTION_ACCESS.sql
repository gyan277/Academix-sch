-- Fix Teacher Fee Collection Access Issues
-- Run sections based on diagnostic results

-- ============================================
-- FIX 1: Create missing teacher record
-- ============================================
-- If Step 3 shows "NO TEACHER RECORD", run this:
-- Replace values with actual data

/*
INSERT INTO teachers (
  user_id,
  full_name,
  email,
  phone,
  class_assigned,
  school_id,
  status
) VALUES (
  'USER_ID_FROM_AUTH_USERS',  -- Get from diagnostic Step 2
  'Teacher Full Name',
  'teacher@email.com',
  '',
  'Primary 1',  -- Assign a class
  'SCHOOL_ID_HERE',  -- Get from school_settings
  'active'
);
*/

-- ============================================
-- FIX 2: Fix RLS policy for teachers table
-- ============================================
-- If teacher can't read their own record, fix RLS:

-- Drop existing policy if it's too restrictive
DROP POLICY IF EXISTS "Users can view teachers from their school" ON teachers;

-- Create proper policy
CREATE POLICY "Users can view teachers from their school"
  ON teachers FOR SELECT
  USING (
    school_id IN (
      SELECT school_id FROM users WHERE id = auth.uid()
    )
  );

-- ============================================
-- FIX 3: Fix empty class assignments
-- ============================================
-- Convert empty strings to NULL
UPDATE teachers
SET class_assigned = NULL
WHERE class_assigned = '' OR TRIM(class_assigned) = '';

-- ============================================
-- FIX 4: Assign class to specific teacher
-- ============================================
-- Replace with actual teacher email and class name

/*
UPDATE teachers
SET class_assigned = 'Primary 1'
WHERE user_id IN (
  SELECT id FROM users WHERE email = 'teacher@email.com'
);
*/

-- ============================================
-- FIX 5: Enable feature in school_settings
-- ============================================
UPDATE school_settings
SET enable_teacher_fee_collection = true
WHERE id IN (SELECT school_id FROM users WHERE role = 'admin' LIMIT 1);

-- ============================================
-- FIX 6: Verify fixes
-- ============================================
SELECT 
  'Verification' as step,
  u.email,
  u.role,
  t.full_name,
  t.class_assigned,
  t.school_id,
  ss.enable_teacher_fee_collection
FROM users u
LEFT JOIN teachers t ON t.user_id = u.id
LEFT JOIN school_settings ss ON ss.id = t.school_id
WHERE u.role = 'teacher'
ORDER BY u.email;

SELECT '✅ Fix complete! Have teacher logout and login again.' as result;
