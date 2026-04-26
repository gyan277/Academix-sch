-- Fix Class Fees RLS Policies
-- This ensures admins can insert, update, and delete class fees

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Admins can view class fees from their school" ON class_fees;
DROP POLICY IF EXISTS "Admins can insert class fees" ON class_fees;
DROP POLICY IF EXISTS "Admins can update class fees" ON class_fees;
DROP POLICY IF EXISTS "Admins can delete class fees" ON class_fees;
DROP POLICY IF EXISTS "Admins can manage class fees" ON class_fees;

-- Enable RLS
ALTER TABLE class_fees ENABLE ROW LEVEL SECURITY;

-- Create comprehensive policies for admins
CREATE POLICY "Admins can view class fees from their school"
  ON class_fees FOR SELECT
  USING (
    school_id IN (
      SELECT school_id FROM users WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can insert class fees"
  ON class_fees FOR INSERT
  WITH CHECK (
    school_id IN (
      SELECT school_id FROM users WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can update class fees"
  ON class_fees FOR UPDATE
  USING (
    school_id IN (
      SELECT school_id FROM users WHERE id = auth.uid() AND role = 'admin'
    )
  )
  WITH CHECK (
    school_id IN (
      SELECT school_id FROM users WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can delete class fees"
  ON class_fees FOR DELETE
  USING (
    school_id IN (
      SELECT school_id FROM users WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Verify policies were created
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'class_fees';

-- Test if current user can insert (this will show if RLS is working)
DO $$
DECLARE
  v_school_id UUID;
  v_user_role TEXT;
BEGIN
  -- Get current user's school_id and role
  SELECT school_id, role INTO v_school_id, v_user_role
  FROM users
  WHERE id = auth.uid();
  
  RAISE NOTICE 'Current user school_id: %, role: %', v_school_id, v_user_role;
  
  IF v_user_role = 'admin' THEN
    RAISE NOTICE '✓ User is an admin - should be able to insert class fees';
  ELSE
    RAISE NOTICE '✗ User is NOT an admin (role: %) - will not be able to insert class fees', v_user_role;
  END IF;
END $$;
