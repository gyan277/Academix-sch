-- =====================================================
-- INSTANT FIX FOR TEACHER VISIBILITY ISSUE
-- =====================================================
-- This will immediately make the teacher visible in admin interface
-- =====================================================

-- Step 1: Check what teachers exist in auth but not in staff table
SELECT 
  'TEACHERS IN AUTH BUT NOT VISIBLE TO ADMIN:' as issue,
  au.email,
  au.raw_user_meta_data->>'full_name' as name,
  au.created_at
FROM auth.users au
LEFT JOIN staff s ON au.id = s.id
WHERE au.raw_user_meta_data->>'role' = 'teacher'
  AND s.id IS NULL;

-- Step 2: Get the school_id from admin user
DO $$
DECLARE
  admin_school_id UUID;
BEGIN
  SELECT school_id INTO admin_school_id 
  FROM users 
  WHERE role = 'admin' 
  LIMIT 1;
  
  RAISE NOTICE 'Admin school_id: %', admin_school_id;
END $$;

-- Step 3: Create staff records for all teachers missing from staff table
INSERT INTO staff (
  id,
  staff_number,
  full_name,
  email,
  position,
  specialization,
  employment_date,
  status,
  school_id
)
SELECT 
  au.id,
  NULL, -- Will be auto-generated
  COALESCE(au.raw_user_meta_data->>'full_name', 'Teacher'),
  au.email,
  'Teacher',
  COALESCE(au.raw_user_meta_data->>'specialization', 'General'),
  au.created_at::date,
  'active',
  (SELECT school_id FROM users WHERE role = 'admin' LIMIT 1)
FROM auth.users au
WHERE au.raw_user_meta_data->>'role' = 'teacher'
  AND NOT EXISTS (
    SELECT 1 FROM staff s WHERE s.id = au.id
  )
ON CONFLICT (id) DO UPDATE SET
  full_name = EXCLUDED.full_name,
  email = EXCLUDED.email,
  position = 'Teacher',
  status = 'active';

-- Step 4: Ensure users table has teacher records
INSERT INTO users (
  id,
  email,
  role,
  full_name,
  school_id
)
SELECT 
  au.id,
  au.email,
  'teacher',
  COALESCE(au.raw_user_meta_data->>'full_name', 'Teacher'),
  (SELECT school_id FROM users WHERE role = 'admin' LIMIT 1)
FROM auth.users au
WHERE au.raw_user_meta_data->>'role' = 'teacher'
  AND NOT EXISTS (
    SELECT 1 FROM users u WHERE u.id = au.id
  )
ON CONFLICT (id) DO UPDATE SET
  role = 'teacher',
  full_name = EXCLUDED.full_name,
  school_id = EXCLUDED.school_id;

-- Step 5: Verify the fix worked
SELECT 
  '✅ TEACHERS NOW VISIBLE TO ADMIN:' as success,
  s.staff_number,
  s.full_name,
  s.email,
  s.position,
  s.status,
  sc.school_name
FROM staff s
LEFT JOIN schools sc ON s.school_id = sc.id
WHERE s.position = 'Teacher'
ORDER BY s.created_at DESC;

-- Step 6: Show count
SELECT 
  'SUMMARY:' as info,
  COUNT(*) as total_teachers_now_visible
FROM staff 
WHERE position = 'Teacher' AND status = 'active';

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
SELECT 
  '🎉 INSTANT FIX COMPLETE!' as status,
  'Refresh the Settings → Teachers page' as instruction,
  'Teachers should now be visible to admin' as result;