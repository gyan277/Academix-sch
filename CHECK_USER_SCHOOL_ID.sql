-- Check your user's school_id and verify it exists in schools table

-- 1. Get your current user info
SELECT 
  id as user_id,
  email,
  school_id,
  role
FROM users 
WHERE id = auth.uid();

-- 2. Check if this school_id exists in schools table
SELECT 
  s.id as school_id,
  s.name as school_name,
  s.created_at
FROM schools s
WHERE s.id IN (
  SELECT school_id FROM users WHERE id = auth.uid()
);

-- 3. Check if school_settings record already exists
SELECT 
  id,
  school_id,
  school_name,
  current_academic_year,
  current_term
FROM school_settings
WHERE school_id IN (
  SELECT school_id FROM users WHERE id = auth.uid()
);

-- 4. If school_settings doesn't exist, we need to INSERT instead of UPDATE
-- Check what the issue is
SELECT 
  'User school_id' as check_type,
  u.school_id,
  CASE 
    WHEN s.id IS NOT NULL THEN 'EXISTS in schools table'
    ELSE 'MISSING from schools table'
  END as status
FROM users u
LEFT JOIN schools s ON s.id = u.school_id
WHERE u.id = auth.uid();
