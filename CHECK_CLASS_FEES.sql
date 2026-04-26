-- Check Class Fees
-- This script checks if class fees were saved and diagnoses display issues

-- 1. Check if any class fees exist
SELECT 
  'Total class fees' as check_name,
  COUNT(*) as count
FROM class_fees;

-- 2. Show all class fees with details
SELECT 
  id,
  school_id,
  class,
  academic_year,
  term,
  fee_amount,
  bus_fee,
  canteen_fee,
  created_at
FROM class_fees
ORDER BY created_at DESC;

-- 3. Check current academic year and term from settings
SELECT 
  school_id,
  current_academic_year,
  current_term
FROM school_settings;

-- 4. Check if there's a mismatch between saved fees and current academic year/term
SELECT 
  cf.class,
  cf.academic_year as fee_academic_year,
  cf.term as fee_term,
  ss.current_academic_year,
  ss.current_term,
  CASE 
    WHEN cf.academic_year = ss.current_academic_year AND cf.term = ss.current_term 
    THEN 'MATCH ✓' 
    ELSE 'MISMATCH ✗' 
  END as status
FROM class_fees cf
CROSS JOIN school_settings ss
WHERE cf.school_id = ss.school_id;

-- 5. Show what the frontend should be querying
SELECT 
  'Expected query parameters' as info,
  current_academic_year,
  current_term
FROM school_settings
LIMIT 1;
