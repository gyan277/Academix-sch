-- =====================================================
-- UPDATE SUBJECTS TO CORRECT NAMES
-- =====================================================
-- Run this to update existing subjects or add new ones

-- Update ICT to Computing
UPDATE public.subjects
SET subject_name = 'Computing',
    description = 'Computing and digital literacy'
WHERE subject_code = 'ICT';

-- If ICT doesn't exist, insert Computing
INSERT INTO public.subjects (subject_code, subject_name, description)
VALUES ('COMP', 'Computing', 'Computing and digital literacy')
ON CONFLICT (subject_code) DO NOTHING;

-- Add Our World Our People
INSERT INTO public.subjects (subject_code, subject_name, description)
VALUES ('OWOP', 'Our World Our People', 'Our World Our People')
ON CONFLICT (subject_code) DO NOTHING;

-- Add Career Technology
INSERT INTO public.subjects (subject_code, subject_name, description)
VALUES ('CT', 'Career Technology', 'Career and technical education')
ON CONFLICT (subject_code) DO NOTHING;

-- Verify the subjects
SELECT subject_code, subject_name, description
FROM public.subjects
ORDER BY subject_name;

-- =====================================================
-- COMPLETE LIST OF SUBJECTS
-- =====================================================
-- After running this, you should have:
-- 1. English Language (ENG)
-- 2. Mathematics (MATH)
-- 3. Science (SCI)
-- 4. Social Studies (SST)
-- 5. Our World Our People (OWOP)
-- 6. Creative Arts (ART)
-- 7. Physical Education (PHE)
-- 8. Computing (COMP)
-- 9. Career Technology (CT)
-- 10. Religious & Moral Education (RME)
-- =====================================================
