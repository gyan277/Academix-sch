-- FIX RLS POLICIES FOR TEACHER_CLASSES TABLE
-- This ensures teachers can read their own class assignments

-- First, check current RLS status
SELECT 
  tablename,
  rowsecurity
FROM pg_tables
WHERE tablename = 'teacher_classes';

-- Drop existing policies if any
DROP POLICY IF EXISTS "Teachers can view their own classes" ON teacher_classes;
DROP POLICY IF EXISTS "Admins can view all teacher classes" ON teacher_classes;
DROP POLICY IF EXISTS "Users can view teacher classes in their school" ON teacher_classes;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON teacher_classes;

-- Enable RLS if not already enabled
ALTER TABLE teacher_classes ENABLE ROW LEVEL SECURITY;

-- Create comprehensive RLS policies

-- 1. Teachers can view their own class assignments
CREATE POLICY "Teachers can view their own classes"
ON teacher_classes
FOR SELECT
TO authenticated
USING (
  auth.uid() = teacher_id
);

-- 2. Admins can view all teacher classes in their school
CREATE POLICY "Admins can view all teacher classes"
ON teacher_classes
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role = 'admin'
    AND users.school_id = teacher_classes.school_id
  )
);

-- 3. Admins can insert/update/delete teacher classes in their school
CREATE POLICY "Admins can manage teacher classes"
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
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role = 'admin'
    AND users.school_id = teacher_classes.school_id
  )
);

-- Verify policies were created
SELECT 
  policyname,
  cmd,
  roles,
  qual
FROM pg_policies
WHERE tablename = 'teacher_classes';

-- Test query as teacher
SELECT 
  'Test: Teacher can see their classes' as test,
  COUNT(*) as class_count
FROM teacher_classes
WHERE teacher_id = '3d40ae98-73c1-438c-840a-e058a87a0af9';
