-- Quick check to see if storage is ready for uploads

-- 1. Verify bucket exists and is public
SELECT 
  id as bucket_name,
  public as is_public,
  file_size_limit,
  allowed_mime_types
FROM storage.buckets 
WHERE id = 'school-assets';

-- Expected result:
-- bucket_name: school-assets
-- is_public: true
-- file_size_limit: 5242880 (or NULL)
-- allowed_mime_types: (array of image types or NULL)

-- 2. Count policies on the bucket
SELECT 
  COUNT(*) as policy_count,
  string_agg(name, ', ') as policy_names
FROM storage.policies 
WHERE bucket_id = 'school-assets';

-- Expected: At least 1 policy (public read access)

-- 3. Get your school_id for testing
SELECT 
  u.id as user_id,
  u.email,
  u.school_id,
  s.name as school_name
FROM users u
JOIN schools s ON s.id = u.school_id
WHERE u.email = auth.email(); -- Your current logged-in email

-- 4. Check if school_settings exists for your school
SELECT 
  school_id,
  school_name,
  school_logo_url,
  headmaster_signature_url
FROM school_settings
WHERE school_id IN (
  SELECT school_id FROM users WHERE id = auth.uid()
);

-- If all queries return results, storage is ready!
-- If school_settings doesn't exist, it will be created on first upload
