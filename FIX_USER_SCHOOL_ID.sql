-- Fix user's school_id to link them to Mount Olivet Methodist Academy

-- 1. First, check all schools
SELECT id, name FROM schools ORDER BY name;

-- 2. Check your current user
SELECT id, email, school_id, role FROM users WHERE id = auth.uid();

-- 3. Update your user to link to Mount Olivet Methodist Academy
-- Replace 'YOUR_EMAIL_HERE' with your actual email
UPDATE users
SET school_id = (SELECT id FROM schools WHERE name = 'Mount Olivet Methodist Academy' LIMIT 1)
WHERE email = 'YOUR_EMAIL_HERE';

-- 4. Verify the update
SELECT 
  u.id as user_id,
  u.email,
  u.school_id,
  s.name as school_name
FROM users u
LEFT JOIN schools s ON s.id = u.school_id
WHERE u.email = 'YOUR_EMAIL_HERE';

-- 5. Now create school_settings record for this school if it doesn't exist
INSERT INTO school_settings (
  school_id,
  school_name,
  current_academic_year,
  current_term
)
SELECT 
  id,
  name,
  '2024/2025',
  'Term 1'
FROM schools 
WHERE name = 'Mount Olivet Methodist Academy'
ON CONFLICT (school_id) DO NOTHING;

-- 6. Verify school_settings was created
SELECT * FROM school_settings 
WHERE school_id = (SELECT id FROM schools WHERE name = 'Mount Olivet Methodist Academy');
