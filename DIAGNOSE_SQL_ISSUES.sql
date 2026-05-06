-- =====================================================
-- DIAGNOSE SQL ISSUES
-- =====================================================
-- This script helps identify what's causing SQL problems

-- =====================================================
-- 1. CHECK BASIC TABLE EXISTENCE
-- =====================================================

-- List all tables in the public schema
SELECT 
  'Available Tables:' as info,
  table_name,
  table_type
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- =====================================================
-- 2. CHECK TEACHER_CLASSES TABLE SPECIFICALLY
-- =====================================================

-- Check if teacher_classes table exists
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'teacher_classes')
    THEN 'teacher_classes table EXISTS'
    ELSE 'teacher_classes table DOES NOT EXIST'
  END as table_status;

-- If it exists, show its structure
SELECT 
  'teacher_classes structure:' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'teacher_classes'
ORDER BY ordinal_position;

-- =====================================================
-- 3. CHECK CONSTRAINTS AND FOREIGN KEYS
-- =====================================================

-- Check foreign key constraints on teacher_classes
SELECT 
  'Foreign Key Constraints:' as info,
  tc.constraint_name,
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_name = 'teacher_classes';

-- =====================================================
-- 4. CHECK RLS STATUS
-- =====================================================

-- Check RLS status for all tables
SELECT 
  'RLS Status:' as info,
  schemaname,
  tablename,
  rowsecurity as rls_enabled,
  (SELECT COUNT(*) FROM pg_policies WHERE tablename = c.relname) as policy_count
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' 
  AND c.relkind = 'r'
  AND c.relname IN ('teacher_classes', 'users', 'staff', 'students')
ORDER BY c.relname;

-- =====================================================
-- 5. CHECK FUNCTION EXISTENCE
-- =====================================================

-- Check if any custom functions exist that might be causing issues
SELECT 
  'Custom Functions:' as info,
  proname as function_name,
  pronargs as arg_count,
  prorettype::regtype as return_type
FROM pg_proc 
WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
  AND proname LIKE '%teacher%' OR proname LIKE '%class%'
ORDER BY proname;

-- =====================================================
-- 6. CHECK FOR COMMON ISSUES
-- =====================================================

-- Check if school_settings table exists (required for foreign keys)
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'school_settings')
    THEN 'school_settings table EXISTS ✅'
    ELSE 'school_settings table MISSING ❌ (This could cause FK constraint errors)'
  END as school_settings_status;

-- Check if users table has school_id column
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'users' AND column_name = 'school_id'
    ) THEN 'users.school_id column EXISTS ✅'
    ELSE 'users.school_id column MISSING ❌'
  END as users_school_id_status;

-- =====================================================
-- 7. SIMPLE OPERATIONS TEST
-- =====================================================

-- Test basic SELECT operations
SELECT 'Basic SELECT test:' as test, COUNT(*) as record_count FROM public.users;

-- Test if we can access teacher_classes table
SELECT 
  'teacher_classes access test:' as test,
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'teacher_classes')
    THEN (SELECT COUNT(*)::text FROM public.teacher_classes) || ' records found'
    ELSE 'Table does not exist'
  END as result;

-- =====================================================
-- 8. ERROR SUMMARY
-- =====================================================

SELECT 
  'Diagnostic Summary:' as summary,
  'Check the results above for any MISSING or ERROR indicators' as instruction;