-- FIX NEW ADMIN SCHOOL_ID ISSUE
-- Ensures all admins have a valid school_id

-- Step 1: Check which admins have NULL school_id
SELECT 
  '1. Admins with NULL school_id' as step,
  id,
  email,
  full_name,
  role,
  school_id,
  created_at
FROM users
WHERE role = 'admin' AND school_id IS NULL
ORDER BY created_at DESC;

-- Step 2: Get the default school_id (first school in the system)
SELECT 
  '2. Default School' as step,
  id as school_id,
  school_name,
  school_code
FROM schools
LIMIT 1;

-- Step 3: FIX - Assign school_id to all admins with NULL school_id
UPDATE users
SET school_id = (SELECT id FROM schools LIMIT 1)
WHERE role = 'admin' AND school_id IS NULL;

-- Step 4: Verify all admins now have school_id
SELECT 
  '4. Verification - All Admins' as step,
  id,
  email,
  full_name,
  role,
  school_id,
  CASE 
    WHEN school_id IS NULL THEN '❌ NULL'
    ELSE '✅ HAS SCHOOL_ID'
  END as status
FROM users
WHERE role = 'admin'
ORDER BY created_at DESC;

-- Step 5: Check if there are any users without school_id
SELECT 
  '5. All Users Without School ID' as step,
  role,
  COUNT(*) as count,
  STRING_AGG(email, ', ') as emails
FROM users
WHERE school_id IS NULL
GROUP BY role;
