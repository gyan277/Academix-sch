-- =====================================================
-- CLASS SUBJECTS MANAGEMENT
-- =====================================================
-- This allows admins to configure which subjects are taught in each class

-- =====================================================
-- 1. CREATE CLASS SUBJECTS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS public.class_subjects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  class TEXT NOT NULL,
  subject_id UUID NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
  academic_year TEXT NOT NULL DEFAULT '2024/2025',
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(class, subject_id, academic_year)
);

-- =====================================================
-- 2. CREATE INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_class_subjects_class ON public.class_subjects(class);
CREATE INDEX IF NOT EXISTS idx_class_subjects_subject_id ON public.class_subjects(subject_id);
CREATE INDEX IF NOT EXISTS idx_class_subjects_academic_year ON public.class_subjects(academic_year);
CREATE INDEX IF NOT EXISTS idx_class_subjects_is_active ON public.class_subjects(is_active);

-- =====================================================
-- 3. CREATE TRIGGER FOR UPDATED_AT
-- =====================================================

DROP TRIGGER IF EXISTS set_updated_at_class_subjects ON public.class_subjects;
CREATE TRIGGER set_updated_at_class_subjects
  BEFORE UPDATE ON public.class_subjects
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- =====================================================
-- 4. ENABLE ROW LEVEL SECURITY
-- =====================================================

ALTER TABLE public.class_subjects ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 5. CREATE RLS POLICIES
-- =====================================================

DROP POLICY IF EXISTS "authenticated_users_can_view_class_subjects" ON public.class_subjects;
CREATE POLICY "authenticated_users_can_view_class_subjects"
  ON public.class_subjects FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "authenticated_users_can_manage_class_subjects" ON public.class_subjects;
CREATE POLICY "authenticated_users_can_manage_class_subjects"
  ON public.class_subjects FOR ALL
  TO authenticated
  USING (true);

-- =====================================================
-- 6. GRANT PERMISSIONS
-- =====================================================

GRANT ALL ON public.class_subjects TO authenticated;
GRANT SELECT ON public.class_subjects TO anon;

-- =====================================================
-- 7. INSERT DEFAULT CLASS-SUBJECT MAPPINGS
-- =====================================================

-- Get subject IDs (we'll use these in the inserts)
-- Note: Run this after ensuring subjects exist in the subjects table

-- KG1 and KG2 - Basic subjects
INSERT INTO public.class_subjects (class, subject_id, academic_year)
SELECT 'KG1', id, '2024/2025'
FROM public.subjects
WHERE subject_code IN ('ENG', 'MATH', 'ART', 'PHE')
ON CONFLICT (class, subject_id, academic_year) DO NOTHING;

INSERT INTO public.class_subjects (class, subject_id, academic_year)
SELECT 'KG2', id, '2024/2025'
FROM public.subjects
WHERE subject_code IN ('ENG', 'MATH', 'ART', 'PHE')
ON CONFLICT (class, subject_id, academic_year) DO NOTHING;

-- P1 to P3 - Primary lower
INSERT INTO public.class_subjects (class, subject_id, academic_year)
SELECT class_level, id, '2024/2025'
FROM public.subjects
CROSS JOIN (VALUES ('P1'), ('P2'), ('P3')) AS classes(class_level)
WHERE subject_code IN ('ENG', 'MATH', 'SCI', 'SST', 'OWOP', 'ART', 'PHE', 'RME')
ON CONFLICT (class, subject_id, academic_year) DO NOTHING;

-- P4 to P6 - Primary upper (all subjects)
INSERT INTO public.class_subjects (class, subject_id, academic_year)
SELECT class_level, id, '2024/2025'
FROM public.subjects
CROSS JOIN (VALUES ('P4'), ('P5'), ('P6')) AS classes(class_level)
WHERE subject_code IN ('ENG', 'MATH', 'SCI', 'SST', 'OWOP', 'ART', 'PHE', 'COMP', 'RME')
ON CONFLICT (class, subject_id, academic_year) DO NOTHING;

-- JHS1 to JHS3 - Junior High (all subjects including Career Technology)
INSERT INTO public.class_subjects (class, subject_id, academic_year)
SELECT class_level, id, '2024/2025'
FROM public.subjects
CROSS JOIN (VALUES ('JHS1'), ('JHS2'), ('JHS3')) AS classes(class_level)
WHERE subject_code IN ('ENG', 'MATH', 'SCI', 'SST', 'OWOP', 'ART', 'PHE', 'COMP', 'CT', 'RME')
ON CONFLICT (class, subject_id, academic_year) DO NOTHING;

-- =====================================================
-- 8. VERIFICATION QUERIES
-- =====================================================

-- Check that table was created
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name = 'class_subjects';

-- Check that triggers were created
SELECT trigger_name, event_object_table 
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
  AND event_object_table = 'class_subjects';

-- Check that RLS policies were created
SELECT tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public'
  AND tablename = 'class_subjects';

-- View class-subject mappings
SELECT 
  cs.class,
  s.subject_name,
  s.subject_code,
  cs.academic_year,
  cs.is_active
FROM public.class_subjects cs
JOIN public.subjects s ON cs.subject_id = s.id
ORDER BY cs.class, s.subject_name;

-- Count subjects per class
SELECT 
  class,
  COUNT(*) as subject_count
FROM public.class_subjects
WHERE is_active = true
GROUP BY class
ORDER BY class;

-- =====================================================
-- SETUP COMPLETE!
-- =====================================================
-- 
-- The class_subjects table is now ready.
-- 
-- Features:
-- - Admins can assign subjects to specific classes
-- - Each class can have different subjects
-- - Supports multiple academic years
-- - Can activate/deactivate subjects per class
-- - Default mappings created for all classes
-- 
-- Next steps:
-- 1. Admin can manage class subjects in Settings page
-- 2. Teachers will only see subjects for their selected class
-- 3. Academic page will load subjects dynamically per class
-- 
-- =====================================================
