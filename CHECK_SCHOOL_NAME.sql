-- Check if school name is saved in the database
SELECT 
  school_id,
  school_name,
  school_address,
  school_phone,
  school_email,
  CASE 
    WHEN school_name IS NOT NULL AND school_name != '' THEN '✅ School name exists'
    ELSE '❌ School name is NULL or empty'
  END as name_status
FROM school_settings;
