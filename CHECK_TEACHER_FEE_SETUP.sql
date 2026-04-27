-- Comprehensive Check: Teacher Fee Collection Setup
-- Run this in Supabase SQL Editor to diagnose issues

-- 1. Check if teacher_fee_collections table exists
SELECT 
  '1. Table Exists?' as check_name,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ YES - teacher_fee_collections table exists'
    ELSE '❌ NO - Table missing! Run COMPLETE_FIX_WITH_SCHEMA_REFRESH.sql'
  END as result
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'teacher_fee_collections';

-- 2. Check if enable_teacher_fee_collection column exists
SELECT 
  '2. Settings Column?' as check_name,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ YES - enable_teacher_fee_collection column exists'
    ELSE '❌ NO - Column missing! Run COMPLETE_FIX_WITH_SCHEMA_REFRESH.sql'
  END as result
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'school_settings' 
AND column_name = 'enable_teacher_fee_collection';

-- 3. Check if feature is enabled
SELECT 
  '3. Feature Enabled?' as check_name,
  CASE 
    WHEN enable_teacher_fee_collection = true THEN '✅ YES - Feature is enabled'
    WHEN enable_teacher_fee_collection = false THEN '⚠️ NO - Feature is disabled. Enable in Settings → Profile'
    ELSE '❌ NULL - Not set. Enable in Settings → Profile'
  END as result,
  school_name
FROM school_settings
LIMIT 1;

-- 4. Check teachers table exists
SELECT 
  '4. Teachers Table?' as check_name,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ YES - teachers table exists'
    ELSE '❌ NO - Teachers table missing!'
  END as result
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'teachers';

-- 5. List all teachers and their class assignments
SELECT 
  '5. Teachers & Classes' as check_name,
  t.full_name,
  t.class_assigned,
  CASE 
    WHEN t.class_assigned IS NULL OR t.class_assigned = '' 
    THEN '❌ NO CLASS - Assign in Settings → Teachers'
    ELSE '✅ Has class: ' || t.class_assigned
  END as status,
  u.email as teacher_email
FROM teachers t
LEFT JOIN users u ON t.user_id = u.id
ORDER BY t.full_name;

-- 6. Check RLS policies on teacher_fee_collections
SELECT 
  '6. RLS Policies?' as check_name,
  COUNT(*) as policy_count,
  CASE 
    WHEN COUNT(*) >= 3 THEN '✅ Policies exist'
    ELSE '⚠️ Missing policies'
  END as result
FROM pg_policies 
WHERE tablename = 'teacher_fee_collections';

-- 7. List the policies
SELECT 
  '7. Policy Details' as info,
  policyname,
  cmd as command,
  qual as using_expression
FROM pg_policies 
WHERE tablename = 'teacher_fee_collections';

-- 8. Check if current user can access teachers table
SELECT 
  '8. Can Access Teachers?' as check_name,
  COUNT(*) as teacher_count,
  '✅ Access granted' as result
FROM teachers
LIMIT 1;

-- 9. Summary
SELECT 
  '9. SUMMARY' as section,
  'If all checks pass, the issue is likely:' as message,
  '1. Teacher needs class assigned (Settings → Teachers → Edit)' as step1,
  '2. Feature needs to be enabled (Settings → Profile → Check box)' as step2,
  '3. App needs refresh after changes (F5)' as step3;
