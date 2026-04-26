-- =====================================================
-- FIX ATTENDANCE TABLE
-- =====================================================
-- Add missing columns to attendance table

-- =====================================================
-- STEP 1: Check current attendance table structure
-- =====================================================

SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'attendance'
ORDER BY ordinal_position;

-- =====================================================
-- STEP 2: Add missing columns
-- =====================================================

-- Add recorded_by column if it doesn't exist
ALTER TABLE public.attendance 
ADD COLUMN IF NOT EXISTS recorded_by UUID REFERENCES public.users(id);

-- Add updated_at column if it doesn't exist
ALTER TABLE public.attendance 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Add school_id column if it doesn't exist (for multi-tenancy)
ALTER TABLE public.attendance 
ADD COLUMN IF NOT EXISTS school_id UUID REFERENCES public.school_settings(id) ON DELETE CASCADE;

-- Add class column if it doesn't exist (for student attendance)
ALTER TABLE public.attendance 
ADD COLUMN IF NOT EXISTS class TEXT;

-- =====================================================
-- STEP 3: Create indexes for performance
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_attendance_school_id ON public.attendance(school_id);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON public.attendance(date);
CREATE INDEX IF NOT EXISTS idx_attendance_student_id ON public.attendance(student_id);
CREATE INDEX IF NOT EXISTS idx_attendance_staff_id ON public.attendance(staff_id);
CREATE INDEX IF NOT EXISTS idx_attendance_class ON public.attendance(class);

-- =====================================================
-- STEP 4: Enable RLS if not already enabled
-- =====================================================

ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "allow_authenticated_all_attendance" ON public.attendance;

-- Create simple policy (no recursion)
CREATE POLICY "allow_authenticated_all_attendance"
  ON public.attendance FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- =====================================================
-- STEP 5: Verify the table structure
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
-- - id
-- - school_id
-- - student_id
-- - staff_id
-- - date
-- - status
-- - class
-- - recorded_by
-- - created_at
-- - updated_at

-- =====================================================
-- STEP 6: Test insert
-- =====================================================

-- This is a test to verify the structure works
-- Don't actually run this, just verify the columns exist

/*
INSERT INTO public.attendance (
  school_id,
  student_id,
  date,
  status,
  class,
  recorded_by
) VALUES (
  'test-school-id',
  'test-student-id',
  CURRENT_DATE,
  'present',
  'P1',
  'test-user-id'
);
*/

-- =====================================================
-- COMPLETE!
-- =====================================================
-- 
-- The attendance table now has all required columns:
-- - recorded_by: Who recorded the attendance
-- - school_id: For multi-tenancy
-- - class: For student attendance
-- - updated_at: For tracking updates
-- 
-- Now refresh your browser and try saving attendance again!
-- =====================================================
