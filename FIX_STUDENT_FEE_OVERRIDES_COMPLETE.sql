-- COMPLETE FIX FOR STUDENT FEE OVERRIDES
-- Matches frontend expectations with academic_year and term

-- ============================================
-- STEP 1: Check current state
-- ============================================

-- Check if table exists and its structure
SELECT 
  '1. Current Table Structure' as step,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'student_fee_overrides'
ORDER BY ordinal_position;

-- Check existing constraints
SELECT
  '2. Current Constraints' as step,
  conname as constraint_name,
  contype as constraint_type
FROM pg_constraint
WHERE conrelid = 'student_fee_overrides'::regclass;

-- ============================================
-- STEP 2: Drop and recreate table
-- ============================================

DROP TABLE IF EXISTS student_fee_overrides CASCADE;

-- Create table matching frontend expectations
CREATE TABLE student_fee_overrides (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id uuid NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  student_id uuid NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  academic_year text NOT NULL,
  term text NOT NULL,
  uses_bus boolean DEFAULT false,
  uses_canteen boolean DEFAULT false,
  bus_fee_override numeric(10,2),
  canteen_fee_override numeric(10,2),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  -- Composite unique constraint matching frontend onConflict
  UNIQUE(student_id, academic_year, term)
);

-- Create indexes for performance
CREATE INDEX idx_student_fee_overrides_student ON student_fee_overrides(student_id);
CREATE INDEX idx_student_fee_overrides_school ON student_fee_overrides(school_id);
CREATE INDEX idx_student_fee_overrides_year_term ON student_fee_overrides(academic_year, term);

SELECT '3. Table Recreated' as step, 
       'student_fee_overrides table created with academic_year and term columns' as status;

-- ============================================
-- STEP 3: Enable RLS
-- ============================================

ALTER TABLE student_fee_overrides ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Users can view overrides in their school" ON student_fee_overrides;
DROP POLICY IF EXISTS "Admins can manage overrides in their school" ON student_fee_overrides;
DROP POLICY IF EXISTS "Teachers can view overrides in their school" ON student_fee_overrides;

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

SELECT '4. RLS Policies Created' as step, 'RLS policies configured' as status;

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

SELECT '5. Trigger Created' as step, 'updated_at trigger configured' as status;

-- ============================================
-- STEP 5: Verify the fix
-- ============================================

-- Check the new structure
SELECT
  '6. New Table Structure' as step,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'student_fee_overrides'
ORDER BY ordinal_position;

-- Check constraints
SELECT
  '7. New Constraints' as step,
  conname as constraint_name,
  CASE contype
    WHEN 'p' THEN 'Primary Key'
    WHEN 'f' THEN 'Foreign Key'
    WHEN 'u' THEN 'Unique'
    WHEN 'c' THEN 'Check'
  END as constraint_type
FROM pg_constraint
WHERE conrelid = 'student_fee_overrides'::regclass
ORDER BY contype;

-- Check RLS policies
SELECT
  '8. RLS Policies' as step,
  policyname,
  cmd as operation
FROM pg_policies
WHERE tablename = 'student_fee_overrides'
ORDER BY policyname;

-- ============================================
-- STEP 6: Test with sample data (optional)
-- ============================================

-- Uncomment to test with a real student
/*
-- Get a student from Mount Olivet
DO $$
DECLARE
  v_school_id uuid;
  v_student_id uuid;
  v_academic_year text;
  v_term text;
BEGIN
  -- Get Mount Olivet school info
  SELECT id, current_academic_year, current_term
  INTO v_school_id, v_academic_year, v_term
  FROM schools
  WHERE school_name LIKE '%Mount Olivet%'
  LIMIT 1;

  -- Get first student from that school
  SELECT id
  INTO v_student_id
  FROM students
  WHERE school_id = v_school_id
  AND status = 'active'
  LIMIT 1;

  -- Insert test override
  IF v_student_id IS NOT NULL THEN
    INSERT INTO student_fee_overrides (
      school_id,
      student_id,
      academic_year,
      term,
      uses_bus,
      uses_canteen,
      bus_fee_override,
      canteen_fee_override
    ) VALUES (
      v_school_id,
      v_student_id,
      v_academic_year,
      v_term,
      true,
      true,
      50.00,
      30.00
    )
    ON CONFLICT (student_id, academic_year, term)
    DO UPDATE SET
      uses_bus = EXCLUDED.uses_bus,
      uses_canteen = EXCLUDED.uses_canteen,
      bus_fee_override = EXCLUDED.bus_fee_override,
      canteen_fee_override = EXCLUDED.canteen_fee_override,
      updated_at = now();

    RAISE NOTICE '9. Test Insert: Successfully inserted/updated test override';
  ELSE
    RAISE NOTICE '9. Test Insert: No student found for testing';
  END IF;
END $$;
*/

-- ============================================
-- FINAL STATUS
-- ============================================

SELECT 
  '✅ FIX COMPLETE' as status,
  'The student_fee_overrides table has been recreated with:
   - Proper foreign key constraints
   - academic_year and term columns
   - Composite unique constraint (student_id, academic_year, term)
   - RLS policies for multi-tenancy
   - Updated_at trigger
   
   You can now save student fee overrides without errors!' as message;

-- Show what the frontend will send
SELECT 
  '📋 Frontend Data Format' as info,
  'The frontend sends:
   {
     school_id: uuid,
     student_id: uuid,
     academic_year: "2024/2025",
     term: "Term 1",
     uses_bus: boolean,
     uses_canteen: boolean,
     bus_fee_override: number or null,
     canteen_fee_override: number or null
   }' as expected_format;
