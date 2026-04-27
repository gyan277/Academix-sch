-- Check what the frontend should be seeing
-- This simulates exactly what the frontend is calling

-- ============================================
-- 1. Get the school_id that admin is using
-- ============================================
SELECT 
  '1️⃣ School Info' as step,
  id as school_id,
  name as school_name
FROM schools;

-- ============================================
-- 2. Get current academic year/term
-- ============================================
SELECT 
  '2️⃣ Academic Settings' as step,
  current_academic_year,
  current_term
FROM school_settings;

-- ============================================
-- 3. Call RPC exactly as frontend does
-- ============================================
SELECT 
  '3️⃣ RPC Call (What Frontend Calls)' as step,
  *
FROM get_all_teacher_collections(
  (SELECT id FROM schools LIMIT 1),
  (SELECT current_academic_year FROM school_settings LIMIT 1),
  (SELECT current_term FROM school_settings LIMIT 1)
);

-- ============================================
-- 4. Check if collections exist for this exact combo
-- ============================================
SELECT 
  '4️⃣ Collections Match Check' as step,
  tfc.id,
  tfc.academic_year,
  tfc.term,
  tfc.school_id,
  ss.current_academic_year as system_year,
  ss.current_term as system_term,
  sc.id as school_id_from_schools,
  CASE 
    WHEN tfc.school_id = sc.id 
     AND tfc.academic_year = ss.current_academic_year
     AND tfc.term = ss.current_term
    THEN '✅ PERFECT MATCH'
    ELSE '❌ MISMATCH'
  END as match_status
FROM teacher_fee_collections tfc
CROSS JOIN school_settings ss
CROSS JOIN schools sc;

-- ============================================
-- 5. Check RLS policies on teacher_fee_collections
-- ============================================
SELECT 
  '5️⃣ RLS Policies' as step,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'teacher_fee_collections';
