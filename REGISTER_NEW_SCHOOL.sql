-- =====================================================
-- MANUAL SCHOOL REGISTRATION SCRIPT
-- =====================================================
-- Use this script to register a new school and their admin
-- Run this for each new school that wants to use EduManage

-- =====================================================
-- STEP 1: CREATE SCHOOL SETTINGS
-- =====================================================

-- Replace these values with the actual school information
INSERT INTO public.school_settings (
  school_name,
  school_address,
  school_phone,
  school_email,
  current_academic_year
) VALUES (
  'MOMA School',                    -- School name
  '123 School Street, Accra',       -- School address
  '+233 50 123 4567',               -- School phone
  'info@moma.edu.gh',               -- School email
  '2024/2025'                       -- Current academic year
)
RETURNING id;

-- Copy the returned ID (school_id) - you'll need it in the next steps

-- =====================================================
-- STEP 2: CREATE ADMIN USER IN SUPABASE AUTH
-- =====================================================

-- Go to Supabase Dashboard → Authentication → Users
-- Click "Add User" → "Create new user"
-- 
-- Fill in:
-- - Email: admin@moma.edu.gh
-- - Password: (choose a strong password)
-- - Check "Auto Confirm User"
-- - User Metadata (click "Add field"):
--   {
--     "full_name": "Admin Name",
--     "role": "admin",
--     "phone": "+233 50 123 4567",
--     "school_id": "PASTE_SCHOOL_ID_FROM_STEP_1_HERE"
--   }
-- 
-- Click "Create user"

-- =====================================================
-- STEP 3: VERIFY USER WAS CREATED WITH SCHOOL_ID
-- =====================================================

-- Check that the user was created and linked to the school
SELECT 
  u.id,
  u.email,
  u.full_name,
  u.role,
  u.school_id,
  s.school_name
FROM public.users u
LEFT JOIN public.school_settings s ON u.school_id = s.id
WHERE u.email = 'admin@moma.edu.gh';

-- You should see the user with their school_id and school_name

-- =====================================================
-- STEP 4: COPY DEFAULT SUBJECTS TO THIS SCHOOL
-- =====================================================

-- Get the school_id from step 1, then run:
-- Replace 'YOUR_SCHOOL_ID_HERE' with the actual school_id

-- Copy subjects for all classes
INSERT INTO public.class_subjects (class, subject_id, academic_year, school_id)
SELECT 
  cs.class,
  cs.subject_id,
  cs.academic_year,
  'YOUR_SCHOOL_ID_HERE'::UUID  -- Replace with actual school_id
FROM public.class_subjects cs
WHERE cs.school_id IS NULL  -- Copy from default/template
ON CONFLICT DO NOTHING;

-- Copy grading scale
INSERT INTO public.grading_scale (grade, min_score, max_score, sort_order, school_id)
SELECT 
  grade,
  min_score,
  max_score,
  sort_order,
  'YOUR_SCHOOL_ID_HERE'::UUID  -- Replace with actual school_id
FROM public.grading_scale
WHERE school_id IS NULL  -- Copy from default/template
ON CONFLICT DO NOTHING;

-- =====================================================
-- COMPLETE! SCHOOL IS NOW REGISTERED
-- =====================================================
-- 
-- The admin can now:
-- 1. Login with their email and password
-- 2. See only their school's data
-- 3. Add teachers, students, and staff
-- 4. Configure school settings
-- 
-- All data will be isolated to this school only!
-- =====================================================


-- =====================================================
-- QUICK REFERENCE: REGISTER ANOTHER SCHOOL
-- =====================================================

-- For the next school, just repeat the process:

-- 1. Insert school settings (get school_id)
INSERT INTO public.school_settings (school_name, school_address, school_phone, school_email, current_academic_year)
VALUES ('Another School', 'Address', 'Phone', 'Email', '2024/2025')
RETURNING id;

-- 2. Create admin in Supabase Dashboard with school_id in metadata

-- 3. Copy subjects and grading scale with the new school_id

-- Done! Each school is completely isolated.
