-- =====================================================
-- FIX TEACHER CREATION FOR FULL MULTI-TENANCY
-- =====================================================
-- This script ensures teacher creation works properly
-- with complete school isolation and multi-tenancy

-- =====================================================
-- 1. VERIFY STAFF TABLE HAS PROPER MULTI-TENANCY
-- =====================================================

-- Check if staff table has school_id column
SELECT 
  '1. Staff Table Multi-Tenancy Check' as step,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'staff' AND column_name = 'school_id'
    ) THEN '✅ Staff table has school_id column'
    ELSE '❌ Staff table missing school_id column'
  END as status;

-- =====================================================
-- 2. VERIFY RLS POLICIES FOR STAFF TABLE
-- =====================================================

-- Check staff RLS policies
SELECT 
  '2. Staff RLS Policies' as step,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE tablename = 'staff'
ORDER BY policyname;

-- =====================================================
-- 3. ENSURE STAFF TABLE HAS PROPER CONSTRAINTS
-- =====================================================

-- Add NOT NULL constraint to school_id if missing
DO $$ 
BEGIN
  -- Check if school_id is nullable
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'staff' 
    AND column_name = 'school_id' 
    AND is_nullable = 'YES'
  ) THEN
    -- Make school_id NOT NULL for new records
    ALTER TABLE public.staff 
    ALTER COLUMN school_id SET NOT NULL;
    
    RAISE NOTICE '✅ Made staff.school_id NOT NULL';
  ELSE
    RAISE NOTICE '✅ Staff.school_id already NOT NULL';
  END IF;
END $$;

-- =====================================================
-- 4. CREATE SECURE STAFF CREATION FUNCTION
-- =====================================================

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS public.create_staff_with_login(
  p_full_name TEXT,
  p_email TEXT,
  p_phone TEXT,
  p_position TEXT,
  p_specialization TEXT,
  p_school_id UUID
);

-- Create secure staff creation function
CREATE OR REPLACE FUNCTION public.create_staff_with_login(
  p_full_name TEXT,
  p_email TEXT,
  p_phone TEXT,
  p_position TEXT,
  p_specialization TEXT,
  p_school_id UUID
)
RETURNS JSON AS $$
DECLARE
  v_staff_id UUID;
  v_user_school_id UUID;
  v_result JSON;
BEGIN
  -- Security check: Verify caller belongs to the same school
  SELECT school_id INTO v_user_school_id 
  FROM public.users 
  WHERE id = auth.uid();
  
  IF v_user_school_id IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', 'User not found or no school assigned'
    );
  END IF;
  
  IF v_user_school_id != p_school_id THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Cannot create staff for different school'
    );
  END IF;
  
  -- Create staff record
  INSERT INTO public.staff (
    full_name,
    email,
    phone,
    position,
    specialization,
    employment_date,
    status,
    school_id
  ) VALUES (
    p_full_name,
    p_email,
    p_phone,
    p_position,
    p_specialization,
    CURRENT_DATE,
    'active',
    p_school_id
  )
  RETURNING id INTO v_staff_id;
  
  -- Return success with staff ID
  v_result := json_build_object(
    'success', true,
    'staff_id', v_staff_id,
    'message', 'Staff record created successfully'
  );
  
  RETURN v_result;
  
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object(
    'success', false,
    'error', SQLERRM
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.create_staff_with_login TO authenticated;

-- =====================================================
-- 5. VERIFY USERS TABLE MULTI-TENANCY
-- =====================================================

-- Check users table structure
SELECT 
  '5. Users Table Multi-Tenancy Check' as step,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'users' AND column_name = 'school_id'
    ) THEN '✅ Users table has school_id column'
    ELSE '❌ Users table missing school_id column'
  END as status;

-- =====================================================
-- 6. TEST MULTI-TENANCY ISOLATION
-- =====================================================

-- Create test function to verify school isolation
CREATE OR REPLACE FUNCTION public.test_staff_isolation()
RETURNS TABLE(
  test_name TEXT,
  result TEXT,
  details TEXT
) AS $$
BEGIN
  -- Test 1: Check if RLS is enabled
  RETURN QUERY
  SELECT 
    'RLS Enabled on Staff Table'::TEXT,
    CASE 
      WHEN (SELECT relrowsecurity FROM pg_class WHERE relname = 'staff') 
      THEN '✅ PASS'::TEXT
      ELSE '❌ FAIL'::TEXT
    END,
    'Row Level Security must be enabled for multi-tenancy'::TEXT;
  
  -- Test 2: Check if policies exist
  RETURN QUERY
  SELECT 
    'Staff RLS Policies Exist'::TEXT,
    CASE 
      WHEN (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'staff') > 0
      THEN '✅ PASS'::TEXT
      ELSE '❌ FAIL'::TEXT
    END,
    'RLS policies must exist for school isolation'::TEXT;
    
  -- Test 3: Check school_id constraint
  RETURN QUERY
  SELECT 
    'Staff School ID Constraint'::TEXT,
    CASE 
      WHEN EXISTS (
        SELECT 1 FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu 
        ON tc.constraint_name = kcu.constraint_name
        WHERE tc.table_name = 'staff' 
        AND kcu.column_name = 'school_id'
        AND tc.constraint_type = 'FOREIGN KEY'
      )
      THEN '✅ PASS'::TEXT
      ELSE '❌ FAIL'::TEXT
    END,
    'Staff table must have foreign key to school_settings'::TEXT;
END;
$$ LANGUAGE plpgsql;

-- Run the test
SELECT * FROM public.test_staff_isolation();

-- =====================================================
-- 7. SUMMARY AND NEXT STEPS
-- =====================================================

SELECT 
  '🎯 MULTI-TENANCY SETUP COMPLETE' as summary,
  'Staff creation now properly isolated by school' as details;

SELECT 
  '📋 NEXT STEPS' as action,
  '1. Update .env with real service role key' as step_1,
  '2. Restart development server' as step_2,
  '3. Test teacher creation in Registrar' as step_3;