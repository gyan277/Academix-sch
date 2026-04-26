-- ENSURE ACADEMIC YEAR SETUP
-- This script ensures the academic year system is properly configured

-- =====================================================
-- STEP 1: Ensure school_settings table has current_academic_year column
-- =====================================================
DO $$
BEGIN
  -- Check if column exists
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'school_settings'
      AND column_name = 'current_academic_year'
  ) THEN
    -- Add the column if it doesn't exist
    ALTER TABLE school_settings
    ADD COLUMN current_academic_year TEXT;
    
    RAISE NOTICE '✅ Added current_academic_year column to school_settings table';
  ELSE
    RAISE NOTICE '✅ current_academic_year column already exists';
  END IF;
END $$;

-- =====================================================
-- STEP 2: Set default academic year for schools that don't have one
-- =====================================================
UPDATE school_settings
SET current_academic_year = '2024/2025'
WHERE current_academic_year IS NULL
   OR current_academic_year = '';

-- Show results
SELECT 
  'Updated Schools' as info,
  COUNT(*) as count
FROM school_settings
WHERE current_academic_year = '2024/2025';

-- =====================================================
-- STEP 3: Verify all schools have academic year set
-- =====================================================
SELECT 
  '========================================' as verification;
SELECT 
  'VERIFICATION RESULTS' as verification;
SELECT 
  '========================================' as verification;

SELECT 
  id as school_id,
  school_name,
  current_academic_year,
  CASE 
    WHEN current_academic_year IS NOT NULL AND current_academic_year != '' 
    THEN '✅ Ready'
    ELSE '❌ Needs Setup'
  END as status
FROM school_settings
ORDER BY school_name;

-- =====================================================
-- STEP 4: Show summary
-- =====================================================
DO $$
DECLARE
  total_schools INTEGER;
  ready_schools INTEGER;
BEGIN
  SELECT COUNT(*) INTO total_schools FROM school_settings;
  
  SELECT COUNT(*) INTO ready_schools
  FROM school_settings
  WHERE current_academic_year IS NOT NULL 
    AND current_academic_year != '';
  
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'ACADEMIC YEAR SETUP SUMMARY';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Total Schools: %', total_schools;
  RAISE NOTICE 'Schools Ready: %', ready_schools;
  RAISE NOTICE 'Schools Pending: %', (total_schools - ready_schools);
  RAISE NOTICE '========================================';
  
  IF ready_schools = total_schools THEN
    RAISE NOTICE '✅ All schools are ready!';
    RAISE NOTICE '';
    RAISE NOTICE 'Next Steps:';
    RAISE NOTICE '1. Login to the application';
    RAISE NOTICE '2. Go to Settings → Profile';
    RAISE NOTICE '3. Verify the academic year is correct';
    RAISE NOTICE '4. Change it if needed and click Save';
  ELSE
    RAISE NOTICE '⚠️  Some schools need setup';
    RAISE NOTICE '';
    RAISE NOTICE 'Run this script again or set manually:';
    RAISE NOTICE 'UPDATE school_settings SET current_academic_year = ''2024/2025'' WHERE id = ''your-school-id'';';
  END IF;
  RAISE NOTICE '';
END $$;
