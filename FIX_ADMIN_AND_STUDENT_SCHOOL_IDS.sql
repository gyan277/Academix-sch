-- COMPREHENSIVE FIX FOR SCHOOL_ID ISSUES
-- Fixes both admin users and students to have valid school_ids

-- ============================================
-- STEP 1: Show current state
-- ============================================

SELECT '=== CURRENT STATE ===' as section;

-- Show all schools
SELECT 
  '1. Schools' as step,
  id,
  school_name,
  school_prefix
FROM schools
ORDER BY school_name;

-- Show admin users and their school_ids
SELECT 
  '2. Admin Users' as step,
  id,
  email,
  full_name,
  school_id,
  CASE 
    WHEN school_id IS NULL THEN '❌ NULL'
    WHEN school_id NOT IN (SELECT id FROM schools) THEN '❌ INVALID'
    ELSE '✅ VALID'
  END as status
FROM users
WHERE role = 'admin';

-- Show students and their school_ids (sample)
SELECT 
  '3. Students (sample)' as step,
  student_number,
  full_name,
  school_id,
  CASE 
    WHEN school_id IS NULL THEN '❌ NULL'
    WHEN school_id NOT IN (SELECT id FROM schools) THEN '❌ INVALID'
    ELSE '✅ VALID'
  END as status
FROM students
ORDER BY student_number
LIMIT 10;

-- ============================================
-- STEP 2: Fix admin users' school_ids
-- ============================================

SELECT '=== FIXING ADMIN USERS ===' as section;

-- Fix Mount Olivet admin (if email contains mount or olivet)
UPDATE users
SET school_id = (SELECT id FROM schools WHERE school_prefix = 'MOU' LIMIT 1)
WHERE role = 'admin'
AND (
  LOWER(email) LIKE '%mount%'
  OR LOWER(email) LIKE '%olivet%'
  OR LOWER(full_name) LIKE '%mount%'
  OR LOWER(full_name) LIKE '%olivet%'
)
AND (
  school_id IS NULL
  OR school_id NOT IN (SELECT id FROM schools)
);

-- Fix Nhyiaeso admin (if email contains nhyiaeso)
UPDATE users
SET school_id = (SELECT id FROM schools WHERE school_prefix = 'NHY' LIMIT 1)
WHERE role = 'admin'
AND (
  LOWER(email) LIKE '%nhyiaeso%'
  OR LOWER(full_name) LIKE '%nhyiaeso%'
)
AND (
  school_id IS NULL
  OR school_id NOT IN (SELECT id FROM schools)
);

-- Fix any remaining admins without school_id (assign to first school)
UPDATE users
SET school_id = (SELECT id FROM schools ORDER BY created_at LIMIT 1)
WHERE role = 'admin'
AND (
  school_id IS NULL
  OR school_id NOT IN (SELECT id FROM schools)
);

SELECT 
  '4. Fixed Admin Users' as step,
  COUNT(*) as admins_with_valid_school_id
FROM users
WHERE role = 'admin'
AND school_id IN (SELECT id FROM schools);

-- ============================================
-- STEP 3: Fix students' school_ids
-- ============================================

SELECT '=== FIXING STUDENTS ===' as section;

-- Fix MOU students
UPDATE students
SET school_id = (SELECT id FROM schools WHERE school_prefix = 'MOU' LIMIT 1)
WHERE student_number LIKE 'MOU%'
AND (
  school_id IS NULL
  OR school_id NOT IN (SELECT id FROM schools)
);

-- Fix NHY students
UPDATE students
SET school_id = (SELECT id FROM schools WHERE school_prefix = 'NHY' LIMIT 1)
WHERE student_number LIKE 'NHY%'
AND (
  school_id IS NULL
  OR school_id NOT IN (SELECT id FROM schools)
);

-- Fix any remaining students (assign to first school)
UPDATE students
SET school_id = (SELECT id FROM schools ORDER BY created_at LIMIT 1)
WHERE school_id IS NULL
OR school_id NOT IN (SELECT id FROM schools);

SELECT 
  '5. Fixed Students' as step,
  COUNT(*) as students_with_valid_school_id
FROM students
WHERE school_id IN (SELECT id FROM schools);

-- ============================================
-- STEP 4: Verify the fix
-- ============================================

SELECT '=== VERIFICATION ===' as section;

-- Check admin users
SELECT 
  '6. Admin Users After Fix' as step,
  u.email,
  u.full_name,
  s.school_name,
  CASE 
    WHEN u.school_id IS NOT NULL AND s.id IS NOT NULL THEN '✅ VALID'
    ELSE '❌ STILL INVALID'
  END as status
FROM users u
LEFT JOIN schools s ON s.id = u.school_id
WHERE u.role = 'admin';

-- Check students (sample)
SELECT 
  '7. Students After Fix (sample)' as step,
  st.student_number,
  st.full_name,
  s.school_name,
  CASE 
    WHEN st.school_id IS NOT NULL AND s.id IS NOT NULL THEN '✅ VALID'
    ELSE '❌ STILL INVALID'
  END as status
FROM students st
LEFT JOIN schools s ON s.id = st.school_id
ORDER BY st.student_number
LIMIT 10;

-- Count any remaining issues
SELECT 
  '8. Remaining Issues' as step,
  (SELECT COUNT(*) FROM users WHERE role = 'admin' AND (school_id IS NULL OR school_id NOT IN (SELECT id FROM schools))) as invalid_admins,
  (SELECT COUNT(*) FROM students WHERE school_id IS NULL OR school_id NOT IN (SELECT id FROM schools)) as invalid_students;

-- ============================================
-- FINAL STATUS
-- ============================================

SELECT 
  '✅ FIX COMPLETE' as status,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM users 
      WHERE role = 'admin' 
      AND (school_id IS NULL OR school_id NOT IN (SELECT id FROM schools))
    ) THEN '⚠️ Some admins still have invalid school_id'
    WHEN EXISTS (
      SELECT 1 FROM students 
      WHERE school_id IS NULL OR school_id NOT IN (SELECT id FROM schools)
    ) THEN '⚠️ Some students still have invalid school_id'
    ELSE '✅ All users and students now have valid school_ids!
    
    You can now save fee overrides without foreign key errors.'
  END as message;
