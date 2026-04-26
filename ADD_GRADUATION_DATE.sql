-- =====================================================
-- ADD GRADUATION DATE COLUMN
-- =====================================================
-- This adds a graduation_date column to track when
-- students graduate from JHS3
-- =====================================================

-- Add graduation_date column if it doesn't exist
ALTER TABLE public.students 
ADD COLUMN IF NOT EXISTS graduation_date DATE;

-- Verify the column was added
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'students'
  AND column_name = 'graduation_date';

-- Check current status values
SELECT 
  status,
  COUNT(*) as count
FROM public.students
GROUP BY status;

-- =====================================================
-- COMPLETE!
-- =====================================================
-- 
-- Now when you graduate JHS3 students:
-- - status changes to 'graduated'
-- - graduation_date is set to today's date
-- - They disappear from active student list
-- 
-- =====================================================
