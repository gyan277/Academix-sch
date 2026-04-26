-- Test Storage Bucket Setup
-- Run these queries to verify storage bucket and test logo/signature functionality

-- 1. Check if school-assets bucket exists
SELECT * FROM storage.buckets WHERE id = 'school-assets';

-- 2. Check storage policies for school-assets bucket
SELECT * FROM storage.policies WHERE bucket_id = 'school-assets';

-- 3. Check current school_settings to see if logo/signature URLs are saved
SELECT 
  s.name as school_name,
  ss.school_logo_url,
  ss.headmaster_signature_url,
  ss.current_academic_year,
  ss.current_term
FROM school_settings ss
JOIN schools s ON s.id = ss.school_id;

-- 4. Check if any files exist in storage (this might not work via SQL)
SELECT * FROM storage.objects WHERE bucket_id = 'school-assets';

-- 5. Manually insert test URLs (OPTIONAL - for testing without actual upload)
-- Replace 'your-school-id-here' with your actual school_id
-- Replace the URLs with actual Supabase storage URLs after you upload

/*
UPDATE school_settings
SET 
  school_logo_url = 'https://your-project.supabase.co/storage/v1/object/public/school-assets/your-school-id/logo.png',
  headmaster_signature_url = 'https://your-project.supabase.co/storage/v1/object/public/school-assets/your-school-id/signature.png'
WHERE school_id = 'your-school-id-here';
*/

-- 6. Verify the update worked
SELECT 
  s.name as school_name,
  ss.school_logo_url,
  ss.headmaster_signature_url
FROM school_settings ss
JOIN schools s ON s.id = ss.school_id;
