-- Check Jessica's fee configuration
-- Run this to see what's configured

-- 1. Find Jessica
SELECT 
  '1. Jessica Student Record' as info,
  id,
  student_number,
  full_name,
  class,
  school_id
FROM students
WHERE full_name LIKE '%Jessica%'
  OR student_number = 'MOU2008';

-- 2. Check if Jessica has student_fees (bills)
SELECT 
  '2. Jessica Bills/Fees' as info,
  sf.fee_type,
  sf.amount,
  sf.status,
  sf.academic_year,
  sf.term
FROM student_fees sf
JOIN students s ON s.id = sf.student_id
WHERE s.student_number = 'MOU2008'
  OR s.full_name LIKE '%Jessica%';

-- 3. Check if Jessica has fee overrides (service enrollment)
SELECT 
  '3. Jessica Service Enrollment' as info,
  sfo.uses_bus,
  sfo.uses_canteen,
  sfo.bus_fee_override,
  sfo.canteen_fee_override,
  sfo.academic_year,
  sfo.term
FROM student_fee_overrides sfo
JOIN students s ON s.id = sfo.student_id
WHERE s.student_number = 'MOU2008'
  OR s.full_name LIKE '%Jessica%';

-- 4. Check class fees for Primary 4
SELECT 
  '4. Primary 4 Class Fees' as info,
  bus_fee,
  canteen_fee,
  academic_year,
  term
FROM class_fees
WHERE class = 'Primary 4';

-- If #3 returns no rows, that's the problem!
-- Jessica needs a student_fee_override record with uses_bus=true or uses_canteen=true
