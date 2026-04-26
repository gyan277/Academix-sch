-- Check the full logo URL that was saved

SELECT 
  school_name,
  school_logo_url,
  headmaster_signature_url,
  LENGTH(school_logo_url) as logo_url_length
FROM school_settings
WHERE school_logo_url IS NOT NULL
ORDER BY id DESC
LIMIT 5;

-- This will show you the complete URL
