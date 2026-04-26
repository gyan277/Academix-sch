-- Check if logo and signature URLs are saved in database
SELECT 
  school_id,
  school_name,
  school_logo_url,
  headmaster_signature_url,
  CASE 
    WHEN school_logo_url IS NOT NULL AND school_logo_url != '' THEN '✅ Logo URL exists'
    ELSE '❌ Logo URL missing'
  END as logo_status,
  CASE 
    WHEN headmaster_signature_url IS NOT NULL AND headmaster_signature_url != '' THEN '✅ Signature URL exists'
    ELSE '❌ Signature URL missing'
  END as signature_status
FROM school_settings;

-- Also check if the URLs are accessible (they should start with the Supabase storage URL)
SELECT 
  school_id,
  school_logo_url,
  headmaster_signature_url,
  CASE 
    WHEN school_logo_url LIKE '%supabase%' THEN '✅ Valid Supabase URL'
    WHEN school_logo_url IS NOT NULL THEN '⚠️ URL exists but not from Supabase'
    ELSE '❌ No URL'
  END as logo_url_check,
  CASE 
    WHEN headmaster_signature_url LIKE '%supabase%' THEN '✅ Valid Supabase URL'
    WHEN headmaster_signature_url IS NOT NULL THEN '⚠️ URL exists but not from Supabase'
    ELSE '❌ No URL'
  END as signature_url_check
FROM school_settings;
