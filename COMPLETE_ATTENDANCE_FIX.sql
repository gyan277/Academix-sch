-- =====================================================
-- COMPLETE ATTENDANCE TABLE FIX
-- =====================================================
-- This will ensure ALL required columns exist

-- =====================================================
-- STEP 1: Check what columns currently exist
-- =====================================================

SELECT 
  column_name,
  data_type
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'attendance'
ORDER BY ordinal_position;

-- =====================================================
-- STEP 2: Add ALL missing columns
-- =====================================================

-- Add student_id if missing
ALTER TABLE public.attendance 
ADD COLUMN IF NOT EXISTS student_id UUID REFERENCES public.students(id) ON DELETE CASCADE;

-- Add staff_id if missing
ALTER TABLE public.attendance 
ADD COLUMN IF NOT EXISTS staff_id UUID REFERENCES public.staff(id) ON DELETE CASCADE;

-- Add school_id if missing
ALTER TABLE public.attendance 
ADD COLUMN IF NOT EXISTS school_id UUID REFERENCES public.school_settings(id) ON DELETE CASCADE;

-- Add date if missing
ALTER TABLE public.attendance 
ADD COLUMN IF NOT EXISTS date DATE NOT NULL DEFAULT CURRENT_DATE;

-- Add status if missing
ALTER TABLE public.attendance 
ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'present';

-- Add class if missing
ALTER TABLE public.attendance 
ADD COLUMN IF NOT EXISTS class TEXT;

-- Add recorded_by if missing
ALTER TABLE public.attendance 
ADD COLUMN IF NOT EXISTS recorded_by UUID REFERENCES public.users(id);

-- Add created_at if missing
ALTER TABLE public.attendance 
ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

-- Add updated_at if missing
ALTER TABLE public.attendance 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- =====================================================
-- STEP 3: Create indexes
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_attendance_school_id ON public.attendance(school_id);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON public.attendance(date);
CREATE INDEX IF NOT EXISTS idx_attendance_student_id ON public.attendance(student_id);
CREATE INDEX IF NOT EXISTS idx_attendance_staff_id ON public.attendance(staff_id);
CREATE INDEX IF NOT EXISTS idx_attendance_class ON public.attendance(class);

-- =====================================================
-- STEP 4: Enable RLS
-- =====================================================

ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies
DROP POLICY IF EXISTS "allow_authenticated_all_attendance" ON public.attendance;
DROP POLICY IF EXISTS "authenticated_users_can_read_all" ON public.attendance;
DROP POLICY IF EXISTS "authenticated_users_can_insert" ON public.attendance;
DROP POLICY IF EXISTS "authenticated_users_can_update" ON public.attendance;
DROP POLICY IF EXISTS "authenticated_users_can_delete" ON public.attendance;

-- Create simple policy
CREATE POLICY "allow_authenticated_all_attendance"
  ON public.attendance FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- =====================================================
-- STEP 5: Verify complete structure
-- =====================================================

SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'attendance'
ORDER BY ordinal_position;

-- Expected columns:
-- ✓ id (uuid)
-- ✓ student_id (uuid, nullable)
-- ✓ staff_id (uuid, nullable)
-- ✓ school_id (uuid)
-- ✓ date (date)
-- ✓ status (text)
-- ✓ class (text, nullable)
-- ✓ recorded_by (uuid, nullable)
-- ✓ created_at (timestamptz)
-- ✓ updated_at (timestamptz)

-- =====================================================
-- STEP 6: Test the structure
-- =====================================================

-- Get your school_id and user_id
SELECT 
  'School ID:' as label,
  id as value
FROM public.school_settings 
LIMIT 1

UNION ALL

SELECT 
  'User ID:' as label,
  id as value
FROM public.users 
WHERE role IN ('admin', 'teacher')
LIMIT 1

UNION ALL

SELECT 
  'Student ID:' as label,
  id as value
FROM public.students 
WHERE status = 'active'
LIMIT 1;

-- =====================================================
-- COMPLETE!
-- =====================================================
-- 
-- The attendance table now has ALL required columns.
-- 
-- Refresh your browser and try saving attendance again!
-- It should work now!
-- 
-- =====================================================
