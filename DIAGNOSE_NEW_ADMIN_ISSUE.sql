-- DIAGNOSE NEW ADMIN ISSUE
-- Check what's wrong with the new admin account

-- Step 1: List all admin accounts
SELECT 
  '1. All Admin Accounts' as step,
  id,
  email,
  full_name,
  role,
  school_id,
  status,
  created_at,
  CASE 
    WHEN school_id IS NULL THEN '❌ NULL SCHOOL_ID'
    ELSE '✅ HAS SCHOOL_ID'
  END as school_id_status
FROM users
WHERE role = 'admin'
ORDER BY created_at DESC;

-- Step 2: Check if schools exist
SELECT 
  '2. Available Schools' as step,
  id as school_id,
  school_name,
  school_code,
  created_at
FROM schools
ORDER BY created_at;

-- Step 3: Check teacher accounts
SELECT 
  '3. All Teachers' as step,
  id,
  email,
  full_name,
  school_id,
  status,
  created_at
FROM users
WHERE role = 'teacher'
ORDER BY created_at DESC;

-- Step 4: Check if new admin can see correct data
-- Replace 'new-admin@example.com' with actual new admin email
SELECT 
  '4. What New Admin Should See' as step,
  'Students' as data_type,
  COUNT(*) as count,
  school_id
FROM students
WHERE school_id = (SELECT school_id FROM users WHERE email = 'new-admin@example.com')
GROUP BY school_id

UNION ALL

SELECT 
  '4. What New Admin Should See' as step,
  'Teachers' as data_type,
  COUNT(*) as count,
  school_id
FROM users
WHERE role = 'teacher'
  AND school_id = (SELECT school_id FROM users WHERE email = 'new-admin@example.com')
GROUP BY school_id

UNION ALL

SELECT 
  '4. What New Admin Should See' as step,
  'Staff' as data_type,
  COUNT(*) as count,
  school_id
FROM staff
WHERE school_id = (SELECT school_id FROM users WHERE email = 'new-admin@example.com')
GROUP BY school_id;

-- Step 5: Check auth.users table
SELECT 
  '5. Auth Users' as step,
  id,
  email,
  created_at,
  email_confirmed_at,
  raw_user_meta_data->>'role' as metadata_role,
  raw_user_meta_data->>'school_id' as metadata_school_id
FROM auth.users
WHERE email LIKE '%admin%'
ORDER BY created_at DESC;

-- Step 6: Check for duplicate emails
SELECT 
  '6. Duplicate Emails' as step,
  email,
  COUNT(*) as count
FROM users
GROUP BY email
HAVING COUNT(*) > 1;

-- Step 7: Recommended fixes
SELECT 
  '7. RECOMMENDED FIXES' as step,
  CASE 
    WHEN (SELECT COUNT(*) FROM users WHERE role = 'admin' AND school_id IS NULL) > 0
    THEN 'Run: UPDATE users SET school_id = (SELECT id FROM schools LIMIT 1) WHERE role = ''admin'' AND school_id IS NULL;'
    WHEN (SELECT COUNT(*) FROM schools) = 0
    THEN 'ERROR: No schools exist! Create a school first.'
    ELSE 'All admins have school_id ✅'
  END as fix_needed;
