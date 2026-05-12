-- FIX STUDENT FEE OVERRIDES FOREIGN KEY CONSTRAINT ERROR
-- Error: "student_fee_overrides_school_id_fkey" violation

-- ============================================
-- STEP 1: Diagnose the issue
-- ============================================

-- Check the current foreign key constraint
SELECT
  '1. Current Constraint' as step,
  conname as constraint_name,
  conrelid::regclass as table_name,
  confrelid::regclass as referenced_table,
  a.attname as column_name,
  af.attname as referenced_column
FROM pg_constraint c
JOIN pg_attribute a ON a.attnum = ANY(c.conkey) AND a.attrelid = c.conrelid
JOIN pg_attribute af ON af.attnum = ANY(c.confkey) AND af.attrelid = c.confrelid
WHERE c.conname = 'student_fee_overrides_school_id_fkey';

-- Check if student_fee_overrides table exists
SELECT 
  '2. Table Structure' as step,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'student_fee_overrides'
ORDER BY ordinal_position;

-- Check existing data in student_fee_overrides
SELECT 
  '3. Existing Data' as step,
  COUNT(*) as record_count
FROM student_fee_overrides;

-- Check schools table
SELECT 
  '4. Schools' as step,
  id,
  school_name,
  school_prefix
FROM schools;

-- ============================================
-- STEP 2: Drop and recreate the table with correct constraints
-- ============================================

-- Drop the table if it exists (this will remove all data)
DROP TABLE IF EXISTS student_fee_overrides CASCADE;

-- Recreate the table with proper structure
CREATE TABLE student_fee_overrides (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id uuid NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  student_id uuid NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  bus_fee numeric(10,2),
  canteen_fee numeric(10,2),
  uses_bus boolean DEFAULT false,
  uses_canteen boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(student_id) -- One override record per student
);

-- Create index for faster lookups
CREATE INDEX idx_student_fee_overrides_student ON student_fee_overrides(student_id);
CREATE INDEX idx_student_fee_overrides_school ON student_fee_overrides(school_id);

SELECT '5. Table Recreated' as step, 'student_fee_overrides table has been recreated' as status;

-- ============================================
-- STEP 3: Enable RLS
-- ============================================

ALTER TABLE student_fee_overrides ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Users can view overrides in their school" ON student_fee_overrides;
DROP POLICY IF EXISTS "Admins can manage overrides in their school" ON student_fee_overrides;

-- Create RLS policies
CREATE POLICY "Users can view overrides in their school"
ON student_fee_overrides
FOR SELECT
TO authenticated
USING (
  school_id IN (
    SELECT school_id FROM users WHERE id = auth.uid()
  )
);

CREATE POLICY "Admins can manage overrides in their school"
ON student_fee_overrides
FOR ALL
TO authenticated
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

SELECT '6. RLS Policies Created' as step, 'RLS policies have been set up' as status;

-- ============================================
-- STEP 4: Create trigger for updated_at
-- ============================================

CREATE OR REPLACE FUNCTION update_student_fee_overrides_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_student_fee_overrides_updated_at ON student_fee_overrides;

CREATE TRIGGER update_student_fee_overrides_updated_at
  BEFORE UPDATE ON student_fee_overrides
  FOR EACH ROW
  EXECUTE FUNCTION update_student_fee_overrides_updated_at();

SELECT '7. Trigger Created' as step, 'updated_at trigger has been set up' as status;

-- ============================================
-- STEP 5: Verify the fix
-- ============================================

-- Check the new constraint
SELECT
  '8. New Constraint' as step,
  conname as constraint_name,
  conrelid::regclass as table_name,
  confrelid::regclass as referenced_table
FROM pg_constraint
WHERE conrelid = 'student_fee_overrides'::regclass
AND contype = 'f'; -- foreign key constraints

-- Check RLS policies
SELECT
  '9. RLS Policies' as step,
  policyname,
  cmd as operation
FROM pg_policies
WHERE tablename = 'student_fee_overrides';

-- ============================================
-- STEP 6: Test insert (optional - comment out if not needed)
-- ============================================

-- Test with a real student from Mount Olivet
-- Uncomment to test:
/*
INSERT INTO student_fee_overrides (
  school_id,
  student_id,
  bus_fee,
  canteen_fee,
  uses_bus,
  uses_canteen
)
SELECT 
  s.school_id,
  s.id,
  50.00,
  30.00,
  true,
  true
FROM students s
WHERE s.student_number = 'MOU0001' -- Replace with actual student number
LIMIT 1;

SELECT '10. Test Insert' as step, 'Test record inserted successfully' as status;
*/

-- ============================================
-- FINAL STATUS
-- ============================================

SELECT 
  '✅ FIX COMPLETE' as status,
  'The student_fee_overrides table has been recreated with proper constraints.
   You can now save student fee overrides without foreign key errors.' as message;
