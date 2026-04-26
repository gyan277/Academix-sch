-- Check what files exist in the school-assets storage bucket
-- Note: This query checks the storage.objects table

SELECT 
  name as file_path,
  bucket_id,
  created_at,
  updated_at,
  CASE 
    WHEN name LIKE '%logo%' THEN '🖼️ Logo file'
    WHEN name LIKE '%signature%' THEN '✍️ Signature file'
    ELSE '📄 Other file'
  END as file_type
FROM storage.objects
WHERE bucket_id = 'school-assets'
ORDER BY created_at DESC;
