-- =====================================================
-- CLEAN STEP BY STEP FIX
-- =====================================================
-- This script fixes everything step by step without errors

-- =====================================================
-- STEP 1: SHOW CURRENT STATE
-- =====================================================

SELECT 'STEP 1: Current State' as step;

-- Show schools
SELECT 'Schools:' as info, COUNT(*) as count FROM public.school_settings;

-- Show teachers  
SELECT 'Teachers:' as info, COUNT(*) as count FROM public.users WHERE role = 'teacher';

-- =====================================================
-- STEP 2: CLEAN REMOVAL
-- =====================================================

SELECT 'STEP 2: Cleaning up' as step;

-- Drop view if exists
DROP VIEW IF EXISTS teacher_class_assignments CASCADE;

-- Drop table if exists
DROP TABLE IF EXISTS public.teacher_classes CASCADE;

SELECT 'Cleanup complete' as status;

-- =====================================================
-- STEP 3: CREATE SIMPLE TABLE
-- =====================================================

SELECT 'STEP 3: Creating table' as step;

-- Create simple teacher_classes table
CREATE TABLE public.teacher_classes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  teacher_id UUID NOT NULL,
  class TEXT NOT NULL,
  academic_year TEXT NOT NULL DEFAULT '2024/2025',
  school_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

SELECT 'Table created' as status;

-- =====================================================
-- STEP 4: ADD BASIC INDEXES
-- =====================================================

SELECT 'STEP 4: Adding indexes' as step;

CREATE INDEX idx_teacher_classes_teacher_id ON public.teacher_classes(teacher_id);
CREATE INDEX idx_teacher_classes_class ON public.teacher_classes(class);

SELECT 'Indexes created' as status;

-- =====================================================
-- STEP 5: TEST INSERTION
-- =====================================================

SELECT 'STEP 5: Testing insertion' as step;

-- Get one teacher ID and one school ID for testing
DO $$
DECLARE
    test_teacher_id UUID;
    test_school_id UUID;
BEGIN
    -- Get first teacher
    SELECT id INTO test_teacher_id FROM public.users WHERE role = 'teacher' ORDER BY created_at LIMIT 1;
    
    -- Get first school
    SELECT id INTO test_school_id FROM public.school_settings ORDER BY created_at LIMIT 1;
    
    -- Insert test record
    IF test_teacher_id IS NOT NULL AND test_school_id IS NOT NULL THEN
        INSERT INTO public.teacher_classes (teacher_id, class, academic_year, school_id)
        VALUES (test_teacher_id, 'Primary 3', '2024/2025', test_school_id);
        
        RAISE NOTICE 'Test insertion successful';
    ELSE
        RAISE NOTICE 'No teacher or school found for testing';
    END IF;
END $$;

SELECT 'Test insertion complete' as status;

-- =====================================================
-- STEP 6: VERIFY TEST
-- =====================================================

SELECT 'STEP 6: Verifying test' as step;

-- Check if record was inserted
SELECT 
  'Test record:' as info,
  COUNT(*) as records_inserted
FROM public.teacher_classes;

-- Show the actual record
SELECT 
  tc.id,
  tc.teacher_id,
  tc.class,
  tc.academic_year,
  tc.school_id
FROM public.teacher_classes tc
LIMIT 1;

-- =====================================================
-- STEP 7: SHOW TABLE STRUCTURE
-- =====================================================

SELECT 'STEP 7: Final table structure' as step;

SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'teacher_classes'
ORDER BY ordinal_position;

-- =====================================================
-- STEP 8: FINAL STATUS
-- =====================================================

SELECT 'STEP 8: Final status' as step;

SELECT 
  '✅ SUCCESS: Teacher class assignment table ready' as result,
  'No RLS, no constraints, no validation' as features,
  'Ready for frontend testing' as next_action;

-- Show what's available for testing
SELECT 'Available for testing:' as info;

SELECT 'Teachers available:' as type, COUNT(*) as count FROM public.users WHERE role = 'teacher';
SELECT 'Classes available:' as type, COUNT(DISTINCT class) as count FROM public.students WHERE status = 'active';
SELECT 'Schools available:' as type, COUNT(*) as count FROM public.school_settings;