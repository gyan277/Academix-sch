-- Simulate Logo Upload Test
-- This simulates what happens when you upload a logo in the Settings page

-- Step 1: Get your school_id
SELECT 
  id as user_id,
  school_id,
  email
FROM users 
WHERE id = auth.uid();

-- Copy the school_id from the result above

-- Step 2: Manually insert a test logo URL
-- Replace 'YOUR_SCHOOL_ID_HERE' with the actual school_id from Step 1
-- This simulates what the upload function does

UPDATE school_settings
SET 
  school_logo_url = 'https://via.placeholder.com/150/0000FF/FFFFFF?text=MOMA+Logo',
  headmaster_signature_url = 'https://via.placeholder.com/200x80/FF0000/FFFFFF?text=Signature'
WHERE school_id = 'YOUR_SCHOOL_ID_HERE';

-- Step 3: Verify the URLs were saved
SELECT 
  s.name as school_name,
  ss.school_logo_url,
  ss.headmaster_signature_url,
  ss.current_academic_year,
  ss.current_term
FROM school_settings ss
JOIN schools s ON s.id = ss.school_id
WHERE ss.school_id = 'YOUR_SCHOOL_ID_HERE';

-- Step 4: Test if these URLs work in a report card
-- Go to Academic page > Reports tab > Generate Reports > Download a report card
-- The placeholder images should appear in the PDF

-- Note: These are placeholder images from placeholder.com
-- Replace with actual Supabase storage URLs after real upload
