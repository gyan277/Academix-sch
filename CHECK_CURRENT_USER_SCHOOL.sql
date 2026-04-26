-- Check which school the current admin user belongs to
SELECT 
  id as user_id,
  email,
  school_id,
  role,
  full_name
FROM users
WHERE role = 'admin'
ORDER BY created_at DESC;

-- Check the school_settings for that school
SELECT 
  school_id,
  school_name,
  school_logo_url,
  headmaster_signature_url,
  LENGTH(school_logo_url) as logo_url_length,
  LENGTH(headmaster_signature_url) as signature_url_length
FROM school_settings
WHERE school_id = 'f3c2cfe9-0a1b-494c-bd25-cc787ab28f77';
