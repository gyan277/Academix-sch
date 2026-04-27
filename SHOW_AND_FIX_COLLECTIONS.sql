-- Show exactly what's in the database and fix it

-- ============================================
-- 1. Show ALL collections with full details
-- ============================================
SELECT 
  '1️⃣ Collections in Database' as step,
  tfc.id,
  tfc.created_at,
  tfc.collection_date,
  tfc.academic_year,
  tfc.term,
  tfc.collection_type,
  tfc.amount,
  tfc.status,
  t.full_name as teacher_name,
  s.full_name as student_name,
  tfc.school_id
FROM teacher_fee_collections tfc
LEFT JOIN teachers t ON t.id = tfc.teacher_id
LEFT JOIN students s ON s.id = tfc.student_id
ORDER BY tfc.created_at DESC;

-- ============================================
-- 2. Show current system settings
-- ============================================
SELECT 
  '2️⃣ System Settings' as step,
  current_academic_year,
  current_term,
  enable_teacher_fee_collection
FROM school_settings;

-- ============================================
-- 3. Update collections to match system year/term
-- ============================================
-- Change collections from 2029/2030 to 2024/2025 Term 1

UPDATE teacher_fee_collections
SET 
  academic_year = '2024/2025',
  term = 'Term 1'
WHERE academic_year = '2029/2030';

SELECT '3️⃣ Updated collections to 2024/2025 Term 1' as step;

-- ============================================
-- 4. Verify collections now match
-- ============================================
SELECT 
  '4️⃣ Verification' as step,
  tfc.academic_year as collection_year,
  tfc.term as collection_term,
  ss.current_academic_year as system_year,
  ss.current_term as system_term,
  CASE 
    WHEN tfc.academic_year = ss.current_academic_year 
     AND tfc.term = ss.current_term
    THEN '✅ MATCH!'
    ELSE '❌ Still mismatch'
  END as status,
  COUNT(*) as collection_count
FROM teacher_fee_collections tfc
CROSS JOIN school_settings ss
GROUP BY tfc.academic_year, tfc.term, ss.current_academic_year, ss.current_term;

-- ============================================
-- 5. Test RPC function
-- ============================================
SELECT 
  '5️⃣ RPC Function Test' as step,
  COUNT(*) as collections_returned
FROM get_all_teacher_collections(
  (SELECT id FROM schools LIMIT 1),
  '2024/2025',
  'Term 1'
);

-- ============================================
-- 6. Show what admin will see
-- ============================================
SELECT 
  '6️⃣ What Admin Will See' as step,
  teacher_name,
  student_name,
  collection_type,
  amount,
  collection_date,
  status
FROM get_all_teacher_collections(
  (SELECT id FROM schools LIMIT 1),
  '2024/2025',
  'Term 1'
);

-- ============================================
-- DONE
-- ============================================
SELECT 
  '✅ DONE!' as status,
  'Collections updated to 2024/2025 Term 1' as action,
  'Now refresh the admin page (Ctrl+R)' as next_step;
