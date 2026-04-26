-- Simple fix for user school_id without using auth.uid()

-- 1. List all users to find yours
SELECT id, email, school_id, role FROM users ORDER BY email;

-- 2. List all schools
SELECT id, name FROM schools ORDER BY name;

-- 3. Update your user with the correct school_id
-- IMPORTANT: Replace 'your-email@example.com' with YOUR actual email
-- IMPORTANT: Copy the school_id from step 2 for Mount Olivet Methodist Academy

UPDATE users
SET school_id = 'PASTE_SCHOOL_ID_HERE'
WHERE email = 'your-email@example.com';

-- 4. Verify the update worked
SELECT 
  u.id,
  u.email,
  u.school_id,
  s.name as school_name
FROM users u
LEFT JOIN schools s ON s.id = u.school_id
WHERE u.email = 'your-email@example.com';

-- 5. Create school_settings if it doesn't exist
-- IMPORTANT: Use the same school_id from step 3
INSERT INTO school_settings (
  school_id,
  school_name,
  current_academic_year,
  current_term
) VALUES (
  'PASTE_SCHOOL_ID_HERE',
  'Mount Olivet Methodist Academy',
  '2024/2025',
  'Term 1'
) ON CONFLICT (school_id) DO NOTHING;

-- 6. Verify school_settings exists
SELECT * FROM school_settings WHERE school_id = 'PASTE_SCHOOL_ID_HERE';
