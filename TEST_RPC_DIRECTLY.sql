-- Test the RPC function directly to see what it returns

-- ============================================
-- 1. Check if collections exist with correct year/term
-- ============================================
SELECT 
  '1️⃣ Collections in Database' as step,
  COUNT(*) as total,
  academic_year,
  term,
  status
FROM teacher_fee_collections
GROUP BY academic_year, term, status;

-- ============================================
-- 2. Get school_id and settings
-- ============================================
SELECT 
  '2️⃣ School Settings' as step,
  id as school_id,
  current_academic_year,
  current_term,
  enable_teacher_fee_collection
FROM school_settings;

-- ============================================
-- 3. Test RPC function with explicit parameters
-- ============================================
SELECT 
  '3️⃣ Testing RPC Function' as step,
  *
FROM get_all_teacher_collections(
  (SELECT id FROM schools LIMIT 1),
  '2024/2025',
  'Term 1'
);

-- ============================================
-- 4. Check if RPC function exists
-- ============================================
SELECT 
  '4️⃣ RPC Function Check' as step,
  routine_name,
  routine_type,
  CASE 
    WHEN routine_name = 'get_all_teacher_collections' THEN '✅ Function exists'
    ELSE '❌ Function missing'
  END as status
FROM information_schema.routines
WHERE routine_name = 'get_all_teacher_collections';

-- ============================================
-- 5. Check if teachers and students exist
-- ============================================
SELECT 
  '5️⃣ Check Teacher/Student Records' as step,
  tfc.id as collection_id,
  tfc.teacher_id,
  t.full_name as teacher_name,
  t.id as teacher_exists,
  tfc.student_id,
  s.full_name as student_name,
  s.id as student_exists
FROM teacher_fee_collections tfc
LEFT JOIN teachers t ON t.id = tfc.teacher_id
LEFT JOIN students s ON s.id = tfc.student_id;

-- ============================================
-- 6. Manual query (what RPC should return)
-- ============================================
SELECT 
  '6️⃣ Manual Query (What RPC Should Return)' as step,
  tfc.id as collection_id,
  tfc.teacher_id,
  t.full_name as teacher_name,
  tfc.student_id,
  s.full_name as student_name,
  tfc.collection_type,
  tfc.amount,
  tfc.collection_date,
  tfc.status,
  tfc.academic_year,
  tfc.term
FROM teacher_fee_collections tfc
JOIN teachers t ON t.id = tfc.teacher_id
JOIN students s ON s.id = tfc.student_id
WHERE tfc.school_id = (SELECT id FROM schools LIMIT 1)
  AND tfc.academic_year = '2024/2025'
  AND tfc.term = 'Term 1';

-- ============================================
-- 7. Check for NULL teacher_id or student_id
-- ============================================
SELECT 
  '7️⃣ Check for NULL IDs' as step,
  COUNT(*) as total_collections,
  COUNT(CASE WHEN teacher_id IS NULL THEN 1 END) as null_teacher_id,
  COUNT(CASE WHEN student_id IS NULL THEN 1 END) as null_student_id,
  CASE 
    WHEN COUNT(CASE WHEN teacher_id IS NULL THEN 1 END) > 0 
      OR COUNT(CASE WHEN student_id IS NULL THEN 1 END) > 0
    THEN '❌ NULL IDs found - RPC JOIN will fail'
    ELSE '✅ All IDs valid'
  END as status
FROM teacher_fee_collections;
