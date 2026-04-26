-- Debug Upload Issue
-- Check if files are being uploaded to storage but not saved to database

-- 1. Check if any files exist in storage bucket
SELECT 
  name as file_path,
  bucket_id,
  created_at,
  updated_at,
  metadata
FROM storage.objects 
WHERE bucket_id = 'school-assets'
ORDER BY created_at DESC;

-- 2. Check your current user and school_id
SELECT 
  id as user_id,
  email,
  school_id,
  role
FROM users 
WHERE id = auth.uid();

-- 3. Check school_settings table structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'school_settings'
  AND column_name IN ('school_logo_url', 'headmaster_signature_url', 'school_id', 'id');

-- 4. Check if school_settings record exists for your school
SELECT 
  id,
  school_id,
  school_name,
  school_logo_url,
  headmaster_signature_url
FROM school_settings
WHERE school_id IN (
  SELECT school_id FROM users WHERE id = auth.uid()
);

-- 5. Check RLS policies on school_settings
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'school_settings';
