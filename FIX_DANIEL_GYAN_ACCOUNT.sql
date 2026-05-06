-- =====================================================
-- FIX DANIEL GYAN'S ACCOUNT MANUALLY
-- =====================================================
-- Since the API failed, let's create his login account manually

-- Step 1: Check Daniel's staff record
SELECT 
  'Daniel Gyan Staff Record:' as info;

SELECT 
  id,
  staff_id,
  full_name,
  email,
  position,
  school_id,
  specialization
FROM public.staff 
WHERE full_name ILIKE '%daniel%gyan%';

-- Step 2: Get school information
SELECT 
  'School Information:' as info;

SELECT 
  ss.id,
  ss.school_name,
  ss.email as school_email
FROM public.school_settings ss
JOIN public.staff s ON s.school_id = ss.id
WHERE s.full_name ILIKE '%daniel%gyan%';

-- Step 3: Check if he already has a user account
SELECT 
  'Existing User Account Check:' as info;

SELECT 
  u.id,
  u.email,
  u.role,
  u.full_name,
  u.school_id
FROM public.users u
WHERE u.full_name ILIKE '%daniel%gyan%'
   OR u.email ILIKE '%daniel%';

-- =====================================================
-- MANUAL ACCOUNT CREATION INSTRUCTIONS
-- =====================================================

SELECT 
  '📋 MANUAL FIX INSTRUCTIONS:' as instructions,
  '1. Go to Supabase Auth Dashboard' as step1,
  '2. Create user with email from staff record' as step2,
  '3. Copy the User ID' as step3,
  '4. Run the INSERT query below with that User ID' as step4;

-- Step 4: Manual user creation query (run after creating in Auth dashboard)
-- REPLACE 'PASTE_USER_ID_HERE' with actual UUID from Supabase Auth

/*
-- Run this after creating user in Supabase Auth dashboard:

INSERT INTO public.users (
    id,
    email,
    role,
    full_name,
    school_id
) 
SELECT 
    'PASTE_USER_ID_HERE'::UUID,  -- Replace with actual User ID from Auth
    s.email,
    'teacher',
    s.full_name,
    s.school_id
FROM public.staff s
WHERE s.full_name ILIKE '%daniel%gyan%'
LIMIT 1;

-- If Daniel is assigned to a class, also run:
INSERT INTO public.teacher_classes (
    teacher_id,
    class,
    academic_year,
    school_id
)
SELECT 
    'PASTE_USER_ID_HERE'::UUID,  -- Same User ID
    'Primary 3',  -- Or whatever class he should teach
    '2024/2025',
    s.school_id
FROM public.staff s
WHERE s.full_name ILIKE '%daniel%gyan%'
LIMIT 1;
*/

-- =====================================================
-- ALTERNATIVE: DELETE AND RECREATE
-- =====================================================

SELECT 
  '🔄 ALTERNATIVE: Start Fresh' as alternative,
  'Delete Daniel from staff table and recreate through UI' as option1,
  'This time, make sure server is running properly' as option2;

-- Uncomment to delete Daniel's staff record and start over:
-- DELETE FROM public.staff WHERE full_name ILIKE '%daniel%gyan%';