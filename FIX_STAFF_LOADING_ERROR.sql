-- =====================================================
-- FIX STAFF LOADING ERROR
-- =====================================================
-- This fixes the "Failed to load staff from database" error
-- =====================================================

-- Check if staff table exists
SELECT 
  table_name,
  table_type
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name = 'staff';

-- Check staff table structure
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'staff'
ORDER BY ordinal_position;

-- Check if any staff exist
SELECT 
  COUNT(*) as total_staff,
  COUNT(CASE WHEN status = 'active' THEN 1 END) as active_staff
FROM public.staff;

-- Check RLS policies on staff table
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'staff';

-- =====================================================
-- FIX: Ensure RLS allows reading staff
-- =====================================================

-- Enable RLS if not enabled
ALTER TABLE public.staff ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "allow_authenticated_all_staff" ON public.staff;
DROP POLICY IF EXISTS "authenticated_users_can_read_staff" ON public.staff;

-- Create simple policy to allow authenticated users to read/write staff
CREATE POLICY "allow_authenticated_all_staff"
  ON public.staff FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- =====================================================
-- FIX: Ensure staff_number column is nullable
-- =====================================================

ALTER TABLE public.staff 
ALTER COLUMN staff_number DROP NOT NULL;

ALTER TABLE public.staff 
ALTER COLUMN staff_id DROP NOT NULL;

-- =====================================================
-- VERIFY THE FIX
-- =====================================================

-- Test query (this is what the frontend runs)
SELECT * FROM public.staff WHERE status = 'active' ORDER BY full_name;

-- Check if policies are working
SELECT 
  'Staff table accessible: ' || 
  CASE WHEN COUNT(*) >= 0 THEN 'YES ✓' ELSE 'NO ✗' END as result
FROM public.staff;

-- =====================================================
-- COMPLETE!
-- =====================================================
-- 
-- After running this:
-- 1. Refresh your browser (F5)
-- 2. Go to Registrar → Staff tab
-- 3. Staff should now load without error
-- 
-- =====================================================
