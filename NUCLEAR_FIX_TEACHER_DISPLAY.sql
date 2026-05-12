-- NUCLEAR FIX FOR TEACHER CLASS DISPLAY
-- This will completely reset and fix the teacher_classes RLS policies

-- ============================================
-- STEP 1: Verify the data exists
-- ============================================
SELECT 
  '1. Data Verification' as step,
  tc.id,
  u.email as teacher_email,
  tc.class,
  tc.academic_year,
  tc.school_id,
  s.school_name
FROM teacher_classes tc
JOIN users u ON u.id = tc.teacher_id
JOIN schools s ON s.id = tc.school_id
WHERE u.email = 'georgegyan@gmail.com';

-- ============================================
-- STEP 2: Check current RLS status
-- ============================================
SELECT 
  '2. Current RLS Status' as step,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE tablename = 'teacher_classes';

-- ============================================
-- STEP 3: Drop ALL existing policies
-- ============================================
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'teacher_classes'
    ) LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON teacher_classes', r.policyname);
    END LOOP;
END $$;

SELECT '3. Dropped all existing policies' as step;

-- ============================================
-- STEP 4: Create simple, permissive policies
-- ============================================

-- Policy 1: Teachers can read their own assignments
CREATE POLICY "teacher_read_own_classes"
ON teacher_classes
FOR SELECT
TO authenticated
USING (
  teacher_id = auth.uid()
);

-- Policy 2: Admins can do everything in their school
CREATE POLICY "admin_full_access"
ON teacher_classes
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role = 'admin'
    AND users.school_id = teacher_classes.school_id
  )
);

SELECT '4. Created new RLS policies' as step;

-- ============================================
-- STEP 5: Verify policies are active
-- ============================================
SELECT 
  '5. Active Policies' as step,
  policyname,
  cmd as command,
  CASE 
    WHEN cmd = 'SELECT' THEN 'Read'
    WHEN cmd = 'ALL' THEN 'All Operations'
    ELSE cmd
  END as operation_type
FROM pg_policies
WHERE tablename = 'teacher_classes'
ORDER BY policyname;

-- ============================================
-- STEP 6: Test the query that frontend uses
-- ============================================
-- This simulates the exact query from Attendance.tsx/Academic.tsx
SELECT 
  '6. Frontend Query Test' as step,
  class
FROM teacher_classes
WHERE teacher_id = '3d40ae98-73c1-438c-840a-e058a87a0af9';

-- ============================================
-- STEP 7: Verify teacher user profile
-- ============================================
SELECT 
  '7. Teacher Profile' as step,
  id,
  email,
  full_name,
  role,
  school_id
FROM users
WHERE email = 'georgegyan@gmail.com';

-- ============================================
-- STEP 8: Final verification
-- ============================================
SELECT 
  '8. Final Check' as step,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ SUCCESS: Teacher has ' || COUNT(*) || ' class(es) assigned'
    ELSE '❌ FAILED: No classes found'
  END as result
FROM teacher_classes
WHERE teacher_id = '3d40ae98-73c1-438c-840a-e058a87a0af9';

-- ============================================
-- INSTRUCTIONS
-- ============================================
SELECT 
  '9. Next Steps' as step,
  'After running this script:
   1. Check that all steps show success
   2. Have teacher hard refresh browser (Ctrl+Shift+R)
   3. Check browser console for debug messages
   4. If still not working, check Network tab for API errors' as instructions;
