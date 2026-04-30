-- Verify Account Management System Setup
-- Run this in Supabase SQL Editor to check if everything is configured

-- ============================================
-- 1. Check if users table exists and has email column
-- ============================================
SELECT 
  '1️⃣ Users Table Check' as step,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.tables 
      WHERE table_name = 'users'
    ) THEN '✅ Users table exists'
    ELSE '❌ Users table missing'
  END as table_status,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'users' AND column_name = 'email'
    ) THEN '✅ Email column exists'
    ELSE '❌ Email column missing'
  END as email_column;

-- ============================================
-- 2. Check sample users
-- ============================================
SELECT 
  '2️⃣ Sample Users' as step,
  COUNT(*) as total_users,
  COUNT(CASE WHEN email IS NOT NULL THEN 1 END) as users_with_email,
  COUNT(CASE WHEN email IS NULL THEN 1 END) as users_without_email
FROM users;

-- ============================================
-- 3. Show sample user emails (for testing)
-- ============================================
SELECT 
  '3️⃣ Sample User Emails' as step,
  full_name,
  email,
  role
FROM users
WHERE email IS NOT NULL
LIMIT 5;

-- ============================================
-- 4. Check auth.users table (Supabase Auth)
-- ============================================
SELECT 
  '4️⃣ Auth Users Check' as step,
  COUNT(*) as total_auth_users,
  COUNT(CASE WHEN email_confirmed_at IS NOT NULL THEN 1 END) as confirmed_emails,
  COUNT(CASE WHEN email_confirmed_at IS NULL THEN 1 END) as unconfirmed_emails
FROM auth.users;

-- ============================================
-- 5. Check if public.users sync with auth.users
-- ============================================
SELECT 
  '5️⃣ User Sync Check' as step,
  (SELECT COUNT(*) FROM auth.users) as auth_users,
  (SELECT COUNT(*) FROM users) as public_users,
  CASE 
    WHEN (SELECT COUNT(*) FROM auth.users) = (SELECT COUNT(*) FROM users)
    THEN '✅ Users in sync'
    ELSE '⚠️ User count mismatch - some users may not be able to log in'
  END as sync_status;

-- ============================================
-- 6. Check for users in public.users but not in auth.users
-- ============================================
SELECT 
  '6️⃣ Users Missing Auth' as step,
  u.full_name,
  u.email,
  u.role,
  '❌ No auth account - cannot log in' as status
FROM users u
LEFT JOIN auth.users au ON u.id = au.id
WHERE au.id IS NULL
LIMIT 10;

-- ============================================
-- 7. Check RLS policies on users table
-- ============================================
SELECT 
  '7️⃣ RLS Policies' as step,
  schemaname,
  tablename,
  policyname,
  cmd as command,
  CASE 
    WHEN qual IS NOT NULL THEN 'Has conditions'
    ELSE 'No conditions'
  END as policy_type
FROM pg_policies
WHERE tablename = 'users'
ORDER BY cmd;

-- ============================================
-- 8. Test email uniqueness constraint
-- ============================================
SELECT 
  '8️⃣ Email Uniqueness' as step,
  email,
  COUNT(*) as count,
  CASE 
    WHEN COUNT(*) > 1 THEN '❌ Duplicate email - will cause issues'
    ELSE '✅ Unique'
  END as status
FROM users
WHERE email IS NOT NULL
GROUP BY email
HAVING COUNT(*) > 1;

-- ============================================
-- 9. Check school_settings table for email configuration
-- ============================================
SELECT 
  '9️⃣ School Settings' as step,
  school_name,
  school_email,
  CASE 
    WHEN school_email IS NOT NULL THEN '✅ School email configured'
    ELSE '⚠️ No school email set'
  END as email_status
FROM school_settings
LIMIT 5;

-- ============================================
-- 10. Summary and Recommendations
-- ============================================
SELECT 
  '🎯 SUMMARY' as section,
  CASE 
    WHEN (SELECT COUNT(*) FROM users WHERE email IS NULL) > 0
    THEN '⚠️ Some users have no email - they cannot use forgot password'
    WHEN (SELECT COUNT(*) FROM users u LEFT JOIN auth.users au ON u.id = au.id WHERE au.id IS NULL) > 0
    THEN '❌ Some users have no auth account - they cannot log in'
    WHEN (SELECT COUNT(*) FROM (SELECT email, COUNT(*) as cnt FROM users WHERE email IS NOT NULL GROUP BY email HAVING COUNT(*) > 1) x) > 0
    THEN '❌ Duplicate emails found - will cause login issues'
    ELSE '✅ All checks passed! Account management ready to use'
  END as status,
  CASE 
    WHEN (SELECT COUNT(*) FROM users WHERE email IS NULL) > 0
    THEN 'Action: Update users without email addresses'
    WHEN (SELECT COUNT(*) FROM users u LEFT JOIN auth.users au ON u.id = au.id WHERE au.id IS NULL) > 0
    THEN 'Action: Create auth accounts for users missing them'
    WHEN (SELECT COUNT(*) FROM (SELECT email, COUNT(*) as cnt FROM users WHERE email IS NOT NULL GROUP BY email HAVING COUNT(*) > 1) x) > 0
    THEN 'Action: Fix duplicate email addresses'
    ELSE 'Action: Configure Supabase email settings (see SUPABASE_EMAIL_CONFIGURATION.md)'
  END as next_step;

-- ============================================
-- ADDITIONAL CHECKS
-- ============================================

-- Check if any users need email addresses
SELECT 
  '📧 Users Needing Email' as info,
  COUNT(*) as count,
  'These users cannot use forgot password or change email' as note
FROM users
WHERE email IS NULL OR email = '';

-- Check recent auth activity
SELECT 
  '🔐 Recent Auth Activity' as info,
  COUNT(*) as total_users,
  COUNT(CASE WHEN last_sign_in_at > NOW() - INTERVAL '7 days' THEN 1 END) as active_last_7_days,
  COUNT(CASE WHEN last_sign_in_at > NOW() - INTERVAL '30 days' THEN 1 END) as active_last_30_days
FROM auth.users;

-- ============================================
-- FINAL RECOMMENDATIONS
-- ============================================
SELECT 
  '💡 RECOMMENDATIONS' as section,
  recommendation,
  priority
FROM (
  SELECT 1 as ord, 'Ensure all users have valid email addresses' as recommendation, 'HIGH' as priority
  UNION ALL
  SELECT 2, 'Configure Supabase SMTP settings for production', 'HIGH'
  UNION ALL
  SELECT 3, 'Test forgot password flow with a test user', 'HIGH'
  UNION ALL
  SELECT 4, 'Test email change flow with a test user', 'MEDIUM'
  UNION ALL
  SELECT 5, 'Customize email templates with school branding', 'MEDIUM'
  UNION ALL
  SELECT 6, 'Set up email delivery monitoring', 'LOW'
  UNION ALL
  SELECT 7, 'Document password reset process for users', 'LOW'
) x
ORDER BY ord;

