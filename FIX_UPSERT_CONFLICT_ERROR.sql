-- FIX: "there is no unique or exclusion constraint matching the ON CONFLICT specification"
-- The frontend uses: onConflict: "student_id,academic_year,term"
-- But the table doesn't have this unique constraint

-- ============================================
-- STEP 1: Check current table structure
-- ============================================

-- Check if table exists
SELECT 
  '1. Table Exists' as step,
  EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_name = 'student_fee_overrides'
  ) as table_exists;

-- Check current columns
SELECT 
  '2. Current Columns' as step,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'student_fee_overrides'
ORDER BY ordinal_position;

-- Check current constraints
SELECT
  '3. Current Constraints' as step,
  conname as constraint_name,
  CASE contype
    WHEN 'p' THEN 'Primary Key'
    WHEN 'f' THEN 'Foreign Key'
    WHEN 'u' THEN 'Unique'
    WHEN 'c' THEN 'Check'
  END as constraint_type,
  pg_get_constraintdef(oid) as definition
FROM pg_constraint
WHERE conrelid = 'student_fee_overrides'::regclass
ORDER BY contype;

-- ============================================
-- STEP 2: Add missing columns if needed
-- ============================================

-- Add academic_year column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'student_fee_overrides' 
    AND column_name = 'academic_year'
  ) THEN
    ALTER TABLE student_fee_overrides 
    ADD COLUMN academic_year text NOT NULL DEFAULT '2024/2025';
    
    RAISE NOTICE '4a. Added academic_year column';
  ELSE
    RAISE NOTICE '4a. academic_year column already exists';
  END IF;
END $$;

-- Add term column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'student_fee_overrides' 
    AND column_name = 'term'
  ) THEN
    ALTER TABLE student_fee_overrides 
    ADD COLUMN term text NOT NULL DEFAULT 'Term 1';
    
    RAISE NOTICE '4b. Added term column';
  ELSE
    RAISE NOTICE '4b. term column already exists';
  END IF;
END $$;

-- ============================================
-- STEP 3: Drop old unique constraint if exists
-- ============================================

-- Drop any existing unique constraint on just student_id
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conrelid = 'student_fee_overrides'::regclass 
    AND contype = 'u'
    AND conname LIKE '%student_id%'
    AND NOT conname LIKE '%academic_year%'
  ) THEN
    -- Find and drop the constraint
    EXECUTE (
      SELECT 'ALTER TABLE student_fee_overrides DROP CONSTRAINT ' || conname || ';'
      FROM pg_constraint
      WHERE conrelid = 'student_fee_overrides'::regclass 
      AND contype = 'u'
      AND conname LIKE '%student_id%'
      AND NOT conname LIKE '%academic_year%'
      LIMIT 1
    );
    
    RAISE NOTICE '5. Dropped old unique constraint';
  ELSE
    RAISE NOTICE '5. No old constraint to drop';
  END IF;
END $$;

-- ============================================
-- STEP 4: Create the composite unique constraint
-- ============================================

-- Drop the new constraint if it already exists
ALTER TABLE student_fee_overrides 
DROP CONSTRAINT IF EXISTS student_fee_overrides_unique_per_year_term;

-- Create the composite unique constraint that matches frontend onConflict
ALTER TABLE student_fee_overrides
ADD CONSTRAINT student_fee_overrides_unique_per_year_term 
UNIQUE (student_id, academic_year, term);

SELECT '6. Created Composite Unique Constraint' as step,
       'UNIQUE (student_id, academic_year, term)' as constraint;

-- ============================================
-- STEP 5: Verify the fix
-- ============================================

-- Show all columns
SELECT 
  '7. Final Table Structure' as step,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'student_fee_overrides'
ORDER BY ordinal_position;

-- Show all constraints
SELECT
  '8. Final Constraints' as step,
  conname as constraint_name,
  CASE contype
    WHEN 'p' THEN 'Primary Key'
    WHEN 'f' THEN 'Foreign Key'
    WHEN 'u' THEN 'Unique'
    WHEN 'c' THEN 'Check'
  END as constraint_type,
  pg_get_constraintdef(oid) as definition
FROM pg_constraint
WHERE conrelid = 'student_fee_overrides'::regclass
ORDER BY contype;

-- ============================================
-- STEP 6: Test the upsert (optional)
-- ============================================

-- Uncomment to test with real data
/*
DO $$
DECLARE
  v_school_id uuid;
  v_student_id uuid;
  v_academic_year text;
  v_term text;
BEGIN
  -- Get school info
  SELECT id, current_academic_year, current_term
  INTO v_school_id, v_academic_year, v_term
  FROM schools
  WHERE school_name LIKE '%Mount Olivet%'
  LIMIT 1;

  -- Get a student
  SELECT id
  INTO v_student_id
  FROM students
  WHERE school_id = v_school_id
  AND status = 'active'
  LIMIT 1;

  -- Test upsert (this is what the frontend does)
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

    RAISE NOTICE '9. Test Upsert: SUCCESS - Frontend upsert will now work!';
  ELSE
    RAISE NOTICE '9. Test Upsert: No student found for testing';
  END IF;
END $$;
*/

-- ============================================
-- FINAL STATUS
-- ============================================

SELECT 
  '✅ FIX COMPLETE' as status,
  'The student_fee_overrides table now has:
   - academic_year column (if it was missing)
   - term column (if it was missing)
   - UNIQUE constraint on (student_id, academic_year, term)
   
   The frontend upsert with onConflict will now work!' as message;

-- Show what the frontend expects
SELECT 
  '📋 Frontend Upsert' as info,
  'Frontend code:
   .upsert(data, { onConflict: "student_id,academic_year,term" })
   
   Database now has:
   UNIQUE (student_id, academic_year, term) ✅' as details;
