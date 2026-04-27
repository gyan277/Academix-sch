-- Check if teacher has actually collected any fees

-- 1. Check if there are ANY collections in the database
SELECT 
  '1. Total Collections' as check_name,
  COUNT(*) as count,
  CASE 
    WHEN COUNT(*) = 0 THEN '❌ No collections found - Teacher needs to collect fees first'
    ELSE '✅ Collections exist: ' || COUNT(*)::text
  END as status
FROM teacher_fee_collections;

-- 2. Show all collections (if any)
SELECT 
  '2. All Collections' as info,
  tfc.id,
  tfc.collection_date,
  tfc.collection_type,
  tfc.amount,
  tfc.status,
  tfc.academic_year,
  tfc.term,
  t.full_name as teacher_name,
  s.full_name as student_name
FROM teacher_fee_collections tfc
LEFT JOIN teachers t ON t.id = tfc.teacher_id
LEFT JOIN students s ON s.id = tfc.student_id
ORDER BY tfc.created_at DESC
LIMIT 10;

-- 3. Test the RPC function directly
SELECT 
  '3. Test RPC Function' as info,
  *
FROM get_all_teacher_collections(
  (SELECT id FROM schools LIMIT 1),
  '2024/2025',  -- Adjust if needed
  'Term 1'      -- Adjust if needed
);

-- 4. Check current academic year and term
SELECT 
  '4. Current Academic Settings' as info,
  current_academic_year,
  current_term
FROM school_settings
LIMIT 1;
